import Foundation
import CoreMIDI
import Observation

// MARK: - MIDIEngine

@Observable
final class MIDIEngine {

    // MARK: - Published State

    var isEnabled: Bool = false
    var availableOutputs: [MIDIOutput] = []
    var selectedOutput: MIDIOutput?
    var selectedChannel: Int = 1  // 1–16

    // MARK: - Private CoreMIDI State

    private var midiClient: MIDIClientRef = 0
    private var outputPort: MIDIPortRef = 0

    // MARK: - Active Note Tracking

    /// Maps MIDI note number to the time it was sent (for cancellation)
    private var activeNotes: [Int: MIDITimeStamp] = [:]
    private var pendingNoteOffs: [Int: DispatchWorkItem] = [:]

    // MARK: - Constants

    private let noteOffSafetyMs: Double = 20.0
    private let maxStrumMs: Double = 500.0
    private let humanizationTimingMs: Double = 35.0
    private let humanizationVelocityPct: Double = 0.20

    // MARK: - Init / Deinit

    init() {
        restoreSettings()
    }

    deinit {
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
        }
    }

    // MARK: - Enable / Disable

    func enable() {
        guard !isEnabled else { return }
        setupMIDI()
        isEnabled = true
        scanOutputs()
        restoreSelectedOutput()
    }

    func disable() {
        isEnabled = false
        stopAllNotes()
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
            outputPort = 0
        }
        if midiClient != 0 {
            MIDIClientDispose(midiClient)
            midiClient = 0
        }
    }

    // MARK: - Setup

    private func setupMIDI() {
        var status = MIDIClientCreate("ChordboardMIDIClient" as CFString, { _, _ in }, nil, &midiClient)
        if status != noErr {
            print("MIDIClientCreate failed: \(status)")
            return
        }
        status = MIDIOutputPortCreate(midiClient, "ChordboardOutputPort" as CFString, &outputPort)
        if status != noErr {
            print("MIDIOutputPortCreate failed: \(status)")
        }
    }

    // MARK: - Scan Outputs

    func scanOutputs() {
        let count = MIDIGetNumberOfDestinations()
        var outputs: [MIDIOutput] = []
        for i in 0..<count {
            let endpoint = MIDIGetDestination(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name)
            let displayName = (name?.takeRetainedValue() as String?) ?? "Unknown"
            outputs.append(MIDIOutput(id: i, name: displayName, endpointRef: UInt32(endpoint)))
        }
        availableOutputs = outputs
    }

    // MARK: - Play Notes

    /// Plays notes with expression parameters.
    /// - Parameters:
    ///   - notes: MIDI note numbers
    ///   - velocity: Base velocity 0–1
    ///   - strumValue: Strum amount 0–1 (0 = simultaneous, 1 = 500ms spread)
    ///   - tiltValue: Velocity tilt -1 to 1 (negative = bass heavy, positive = treble heavy)
    ///   - humanize: Humanization amount 0–1
    func playNotes(
        _ notes: [Int],
        velocity: Float = 0.75,
        strumValue: Float = 0.0,
        tiltValue: Float = 0.0,
        humanize: Float = 0.0
    ) {
        guard isEnabled, outputPort != 0, let output = selectedOutput else { return }
        let endpoint = MIDIEndpointRef(output.endpointRef)

        // Cancel any pending note-offs for these notes
        for note in notes {
            pendingNoteOffs[note]?.cancel()
            pendingNoteOffs[note] = nil
        }

        let nowNs = AudioConvertHostTimeToNanos(mach_absolute_time())
        let channel = UInt8(selectedChannel - 1) & 0x0F

        for (index, note) in notes.enumerated() {
            guard note >= 0 && note <= 127 else { continue }

            // Strum timing offset
            let strumOffsetMs = Double(strumValue) * maxStrumMs * Double(index) / Double(max(notes.count - 1, 1))
            var timingOffsetMs = strumOffsetMs

            // Humanization timing offset
            let humanTimingMs = Double(humanize) * humanizationTimingMs * Double.random(in: -1...1)
            timingOffsetMs += humanTimingMs

            // Clamp timing to non-negative
            timingOffsetMs = max(0, timingOffsetMs)

            // Velocity calculation
            var vel = Double(velocity)

            // Velocity tilt: higher velocity for bass (negative tilt) or treble (positive tilt)
            if abs(tiltValue) > 0.001 {
                let normIndex = notes.count > 1 ? Double(index) / Double(notes.count - 1) : 0.5
                // normIndex 0 = bass, 1 = treble
                let tilt = Double(tiltValue)
                if tilt > 0 {
                    // treble heavy: higher index = higher velocity
                    vel += tilt * 0.3 * normIndex
                } else {
                    // bass heavy: lower index = higher velocity
                    vel += abs(tilt) * 0.3 * (1.0 - normIndex)
                }
                vel = min(1.0, max(0.01, vel))
            }

            // Humanization velocity
            let humanVelMod = Double(humanize) * humanizationVelocityPct * Double.random(in: -1...1)
            vel = min(1.0, max(0.01, vel + humanVelMod))

            let midiVelocity = UInt8(vel * 127)

            let noteOnTimeNs = nowNs + UInt64(timingOffsetMs * 1_000_000)
            let noteOnTS = AudioConvertNanosToHostTime(noteOnTimeNs)

            // Send NoteOn
            sendMIDI(endpoint: endpoint, channel: channel, status: 0x90, data1: UInt8(note), data2: midiVelocity, timestamp: noteOnTS)

            // Schedule NoteOff safety (will be cancelled if pad releases cleanly)
            let noteOffTimeNs = noteOnTimeNs + UInt64(noteOffSafetyMs * 1_000_000)
            let noteOffTS = AudioConvertNanosToHostTime(noteOffTimeNs)
            activeNotes[note] = noteOffTS

            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.sendMIDI(endpoint: endpoint, channel: channel, status: 0x80, data1: UInt8(note), data2: 0, timestamp: AudioConvertNanosToHostTime(AudioConvertHostTimeToNanos(mach_absolute_time()) + 1_000_000))
                self.activeNotes.removeValue(forKey: note)
                self.pendingNoteOffs.removeValue(forKey: note)
            }
            pendingNoteOffs[note] = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + (timingOffsetMs + noteOffSafetyMs + 20) / 1000.0, execute: workItem)
        }
    }

    /// Stops specific notes (called on pad release).
    func stopNotes(_ notes: [Int]) {
        guard isEnabled, outputPort != 0, let output = selectedOutput else { return }
        let endpoint = MIDIEndpointRef(output.endpointRef)
        let channel = UInt8(selectedChannel - 1) & 0x0F

        let nowNs = AudioConvertHostTimeToNanos(mach_absolute_time())
        let noteOffTimeNs = nowNs + UInt64(noteOffSafetyMs * 1_000_000)
        let noteOffTS = AudioConvertNanosToHostTime(noteOffTimeNs)

        for note in notes {
            // Cancel the pending auto-off
            pendingNoteOffs[note]?.cancel()
            pendingNoteOffs[note] = nil
            activeNotes.removeValue(forKey: note)
            sendMIDI(endpoint: endpoint, channel: channel, status: 0x80, data1: UInt8(note), data2: 0, timestamp: noteOffTS)
        }
    }

    func stopAllNotes() {
        guard isEnabled, outputPort != 0, let output = selectedOutput else { return }
        let endpoint = MIDIEndpointRef(output.endpointRef)
        let channel = UInt8(selectedChannel - 1) & 0x0F

        let nowNs = AudioConvertHostTimeToNanos(mach_absolute_time())
        let noteOffTS = AudioConvertNanosToHostTime(nowNs + UInt64(noteOffSafetyMs * 1_000_000))

        for (note, _) in activeNotes {
            pendingNoteOffs[note]?.cancel()
            sendMIDI(endpoint: endpoint, channel: channel, status: 0x80, data1: UInt8(note), data2: 0, timestamp: noteOffTS)
        }
        activeNotes.removeAll()
        pendingNoteOffs.removeAll()
    }

    func sendAftertouch(_ value: Float) {
        guard isEnabled, outputPort != 0, let output = selectedOutput else { return }
        let endpoint = MIDIEndpointRef(output.endpointRef)
        let channel = UInt8(selectedChannel - 1) & 0x0F
        let pressure = UInt8(min(127, Int(value * 127)))
        let ts = AudioConvertNanosToHostTime(AudioConvertHostTimeToNanos(mach_absolute_time()))
        sendMIDI(endpoint: endpoint, channel: channel, status: 0xD0, data1: pressure, data2: 0, timestamp: ts)
    }

    // MARK: - CoreMIDI Send

    private func sendMIDI(endpoint: MIDIEndpointRef, channel: UInt8, status: UInt8, data1: UInt8, data2: UInt8, timestamp: MIDITimeStamp) {
        var packetList = MIDIPacketList()
        let packet = MIDIPacketListInit(&packetList)
        let messageStatus = (status & 0xF0) | channel
        var data: [UInt8] = [messageStatus, data1, data2]
        // For channel pressure, only 2 bytes
        let length: Int = (status == 0xD0) ? 2 : 3
        _ = MIDIPacketListAdd(&packetList, MemoryLayout<MIDIPacketList>.size, packet, timestamp, length, &data)
        MIDISend(outputPort, endpoint, &packetList)
    }

    // MARK: - Settings Persistence

    private enum Defaults {
        static let selectedOutputRef = "midi.selectedOutputRef"
        static let selectedChannel = "midi.selectedChannel"
        static let isEnabled = "midi.isEnabled"
    }

    func saveSettings() {
        UserDefaults.standard.set(selectedChannel, forKey: Defaults.selectedChannel)
        UserDefaults.standard.set(isEnabled, forKey: Defaults.isEnabled)
        if let output = selectedOutput {
            UserDefaults.standard.set(output.endpointRef, forKey: Defaults.selectedOutputRef)
        } else {
            UserDefaults.standard.removeObject(forKey: Defaults.selectedOutputRef)
        }
    }

    func restoreSettings() {
        selectedChannel = UserDefaults.standard.integer(forKey: Defaults.selectedChannel)
        if selectedChannel < 1 || selectedChannel > 16 { selectedChannel = 1 }
        isEnabled = UserDefaults.standard.bool(forKey: Defaults.isEnabled)
    }

    private func restoreSelectedOutput() {
        let savedRef = UserDefaults.standard.integer(forKey: Defaults.selectedOutputRef)
        if savedRef != 0 {
            selectedOutput = availableOutputs.first { Int($0.endpointRef) == savedRef }
        }
        if selectedOutput == nil {
            selectedOutput = availableOutputs.first
        }
    }
}

// MARK: - AudioConvert helpers (host time <-> nanoseconds)

private func AudioConvertHostTimeToNanos(_ hostTime: UInt64) -> UInt64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return hostTime * UInt64(info.numer) / UInt64(info.denom)
}

private func AudioConvertNanosToHostTime(_ nanos: UInt64) -> UInt64 {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return nanos * UInt64(info.denom) / UInt64(info.numer)
}
