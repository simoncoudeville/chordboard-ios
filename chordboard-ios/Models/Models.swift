import Foundation

// MARK: - ScalePadSettings

struct ScalePadSettings: Codable, Hashable {
    var degree: Int = 1
    var octave: Int = 4
    var chordExtension: ChordExtension = .none
    var inversion: Inversion = .root
    var voicing: Voicing = .close
}

// MARK: - FreePadSettings

struct FreePadSettings: Codable, Hashable {
    var root: PitchClass = .c
    var type: ChordType = .major
    var octave: Int = 4
    var chordExtension: ChordExtension = .none
    var inversion: Inversion = .root
    var voicing: Voicing = .close
}

// MARK: - PadAxisSettings

struct PadAxisSettings: Codable, Hashable {
    var x: ExpressionAxis = .none
    var y: ExpressionAxis = .none
}

// MARK: - Pad

struct Pad: Codable, Identifiable, Hashable {
    var id: UUID
    var mode: PadMode = .unassigned
    var scale: ScalePadSettings = .init()
    var free: FreePadSettings = .init()
    var axisSettings: PadAxisSettings = .init()

    init() {
        self.id = UUID()
    }

    init(id: UUID = UUID(), mode: PadMode = .unassigned, scale: ScalePadSettings = .init(), free: FreePadSettings = .init(), axisSettings: PadAxisSettings = .init()) {
        self.id = id
        self.mode = mode
        self.scale = scale
        self.free = free
        self.axisSettings = axisSettings
    }
}

// MARK: - BoardScale

struct BoardScale: Codable, Hashable {
    var root: PitchClass = .c
    var type: ScaleType = .major
    var enabled: Bool = true
}

// MARK: - Board

struct Board: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var pads: [Pad]
    var scale: BoardScale
    var createdAt: Date
    var updatedAt: Date

    init(name: String = "New Board") {
        self.id = UUID()
        self.name = name
        // Generate 12 separate Pad instances (not Array(repeating:) to avoid duplicate UUIDs)
        self.pads = (0..<12).map { _ in Pad() }
        self.scale = BoardScale()
        self.createdAt = .now
        self.updatedAt = .now
    }
}

// MARK: - MIDIOutput (lightweight wrapper)

struct MIDIOutput: Identifiable, Hashable {
    let id: Int  // endpoint index
    let name: String
    let endpointRef: UInt32  // MIDIEndpointRef stored as UInt32

    func hash(into hasher: inout Hasher) {
        hasher.combine(endpointRef)
    }

    static func == (lhs: MIDIOutput, rhs: MIDIOutput) -> Bool {
        lhs.endpointRef == rhs.endpointRef
    }
}
