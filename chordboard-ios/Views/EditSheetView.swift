import SwiftUI

// MARK: - EditSheetView

struct EditSheetView: View {
    let initialPad: Pad
    let board: Board
    var midiEngine: MIDIEngine
    var onSave: (Pad) -> Void

    @State private var pad: Pad
    @State private var isPlaying = false
    @State private var holdTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    init(pad: Pad, board: Board, midiEngine: MIDIEngine, onSave: @escaping (Pad) -> Void) {
        self.initialPad = pad
        self.board = board
        self.midiEngine = midiEngine
        self.onSave = onSave
        self._pad = State(initialValue: pad)
    }

    private var isDirty: Bool { pad != initialPad }

    // Resolved chord info for current settings
    private var resolvedChord: (root: PitchClass, type: ChordType) {
        switch pad.mode {
        case .scale:
            return MusicTheory.resolveScaleDegree(
                scaleRoot: board.scale.root,
                scaleType: board.scale.type,
                degree: pad.scale.degree
            )
        case .free, .unassigned:
            return (pad.free.root, pad.free.type)
        }
    }

    private var currentExtension: ChordExtension {
        get { pad.mode == .scale ? pad.scale.chordExtension : pad.free.chordExtension }
    }
    private var currentInversion: Inversion {
        get { pad.mode == .scale ? pad.scale.inversion : pad.free.inversion }
    }
    private var currentVoicing: Voicing {
        get { pad.mode == .scale ? pad.scale.voicing : pad.free.voicing }
    }
    private var currentOctave: Int {
        get { pad.mode == .scale ? pad.scale.octave : pad.free.octave }
    }

    private var currentNotes: [Int] {
        let chord = resolvedChord
        return MusicTheory.buildChord(
            root: chord.root,
            octave: currentOctave,
            type: chord.type,
            extension: currentExtension,
            inversion: currentInversion,
            voicing: currentVoicing
        )
    }

    private var currentActivePitchClasses: Set<PitchClass> {
        Set(currentNotes.map { PitchClass.from(midiNote: $0) })
    }

    private var allowedExtensions: [ChordExtension] {
        MusicTheory.allowedExtensions(for: resolvedChord.type)
    }

    private var maxInversion: Inversion {
        MusicTheory.maxInversion(type: resolvedChord.type, extension: currentExtension)
    }

    private var canTransposeUp: Bool {
        let octave = pad.mode == .scale ? pad.scale.octave : pad.free.octave
        var testPad = pad
        if pad.mode == .scale { testPad.scale.octave = octave + 1 } else { testPad.free.octave = octave + 1 }
        return MusicTheory.isValidChord(root: resolvedChord.root, octave: octave + 1, type: resolvedChord.type, extension: currentExtension, inversion: currentInversion, voicing: currentVoicing)
    }

    private var canTransposeDown: Bool {
        let octave = pad.mode == .scale ? pad.scale.octave : pad.free.octave
        return MusicTheory.isValidChord(root: resolvedChord.root, octave: octave - 1, type: resolvedChord.type, extension: currentExtension, inversion: currentInversion, voicing: currentVoicing)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Mode
                Section("Mode") {
                    Picker("Mode", selection: $pad.mode) {
                        Text("Unassigned").tag(PadMode.unassigned)
                        if board.scale.enabled {
                            Text("In Scale").tag(PadMode.scale)
                        }
                        Text("Free").tag(PadMode.free)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                if pad.mode == .scale && board.scale.enabled {
                    scaleModeSection
                }

                if pad.mode == .free {
                    freeModeSection
                }

                if pad.mode != .unassigned {
                    chordOptionsSection
                    transposeSection
                    axisSection
                }

                // Preview keyboard
                if pad.mode != .unassigned {
                    Section("Chord Preview") {
                        KeyboardView(
                            activePitchClasses: currentActivePitchClasses,
                            chordName: MusicTheory.chordSymbol(
                                root: resolvedChord.root,
                                type: resolvedChord.type,
                                extension: currentExtension,
                                inversion: currentInversion
                            )
                        )
                        .frame(height: 72)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }
            }
            .navigationTitle(pad.mode == .unassigned ? "Unassigned Pad" : "Edit Pad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        stopPlaying()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        stopPlaying()
                        onSave(pad)
                        dismiss()
                    }
                    .disabled(!isDirty)
                    .fontWeight(.semibold)
                }
                if pad.mode != .unassigned {
                    ToolbarItem(placement: .bottomBar) {
                        playButton
                    }
                }
            }
        }
    }

    // MARK: - Scale Mode Section

    @ViewBuilder
    private var scaleModeSection: some View {
        Section("Scale Degree") {
            Picker("Degree", selection: $pad.scale.degree) {
                ForEach(1...7, id: \.self) { degree in
                    let info = MusicTheory.resolveScaleDegree(
                        scaleRoot: board.scale.root,
                        scaleType: board.scale.type,
                        degree: degree
                    )
                    Text(romanNumeral(degree, type: info.type))
                        .tag(degree)
                }
            }
            .pickerStyle(.wheel)
        }
    }

    // MARK: - Free Mode Section

    @ViewBuilder
    private var freeModeSection: some View {
        Section("Root Note") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(PitchClass.allCases, id: \.self) { pitch in
                    Button {
                        pad.free.root = pitch
                        // Reset extension/inversion if not valid for new type
                        if !MusicTheory.allowedExtensions(for: pad.free.type).contains(pad.free.chordExtension) {
                            pad.free.chordExtension = .none
                        }
                    } label: {
                        Text(pitch.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(pad.free.root == pitch ? Color.accentColor : Color(.systemGray5))
                            .foregroundStyle(pad.free.root == pitch ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
        }

        Section("Chord Type") {
            Picker("Type", selection: $pad.free.type) {
                ForEach(ChordType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .onChange(of: pad.free.type) { _, newType in
                if !MusicTheory.allowedExtensions(for: newType).contains(pad.free.chordExtension) {
                    pad.free.chordExtension = .none
                }
            }
        }
    }

    // MARK: - Chord Options Section

    @ViewBuilder
    private var chordOptionsSection: some View {
        Section("Chord Options") {
            Picker("Extension", selection: extensionBinding) {
                ForEach(allowedExtensions, id: \.self) { ext in
                    Text(ext.displayName).tag(ext)
                }
            }

            Picker("Inversion", selection: inversionBinding) {
                ForEach(Inversion.allCases.prefix(maxInversion.steps + 1), id: \.self) { inv in
                    Text(inv.displayName).tag(inv)
                }
            }

            Picker("Voicing", selection: voicingBinding) {
                ForEach(Voicing.allCases, id: \.self) { voicing in
                    Text(voicing.displayName).tag(voicing)
                }
            }
        }
    }

    // MARK: - Transpose Section

    @ViewBuilder
    private var transposeSection: some View {
        Section("Octave") {
            HStack {
                Text("Octave \(currentOctave)")
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    holdButton(label: "minus", action: transposeDown, enabled: canTransposeDown)
                    Text("\(currentOctave)")
                        .font(.headline)
                        .frame(minWidth: 30, alignment: .center)
                    holdButton(label: "plus", action: transposeUp, enabled: canTransposeUp)
                }
            }
        }
    }

    // MARK: - Axis Section

    @ViewBuilder
    private var axisSection: some View {
        Section("Expression Axes") {
            Picker("X Axis", selection: $pad.axisSettings.x) {
                ForEach(ExpressionAxis.allCases, id: \.self) { axis in
                    Text(axis.displayName).tag(axis)
                }
            }
            Picker("Y Axis", selection: $pad.axisSettings.y) {
                ForEach(ExpressionAxis.allCases, id: \.self) { axis in
                    Text(axis.displayName).tag(axis)
                }
            }
        }
    }

    // MARK: - Play Button

    private var playButton: some View {
        Button {
            if isPlaying {
                stopPlaying()
            } else {
                startPlaying()
            }
        } label: {
            Label(isPlaying ? "Stop" : "Play", systemImage: isPlaying ? "stop.fill" : "play.fill")
                .frame(minWidth: 100)
        }
        .buttonStyle(.borderedProminent)
        .tint(isPlaying ? .red : .accentColor)
    }

    // MARK: - Hold-to-Repeat Button

    private func holdButton(label: String, action: @escaping () -> Void, enabled: Bool) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: label)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
        .disabled(!enabled)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.35)
                .onEnded { _ in
                    holdTask?.cancel()
                    holdTask = Task {
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        while !Task.isCancelled && enabled {
                            action()
                            try? await Task.sleep(nanoseconds: 110_000_000)
                        }
                    }
                }
        )
        .onLongPressGesture(minimumDuration: 99) {} // placeholder
        .gesture(DragGesture(minimumDistance: 0).onEnded { _ in holdTask?.cancel() })
    }

    // MARK: - Transpose Actions

    private func transposeUp() {
        if pad.mode == .scale {
            pad.scale.octave += 1
        } else {
            pad.free.octave += 1
        }
    }

    private func transposeDown() {
        if pad.mode == .scale {
            pad.scale.octave -= 1
        } else {
            pad.free.octave -= 1
        }
    }

    // MARK: - Play / Stop

    private func startPlaying() {
        isPlaying = true
        if midiEngine.isEnabled {
            midiEngine.playNotes(currentNotes, velocity: 0.75)
        }
    }

    private func stopPlaying() {
        isPlaying = false
        if midiEngine.isEnabled {
            midiEngine.stopNotes(currentNotes)
        }
    }

    // MARK: - Bindings

    private var extensionBinding: Binding<ChordExtension> {
        Binding {
            pad.mode == .scale ? pad.scale.chordExtension : pad.free.chordExtension
        } set: { newValue in
            if pad.mode == .scale { pad.scale.chordExtension = newValue }
            else { pad.free.chordExtension = newValue }
        }
    }

    private var inversionBinding: Binding<Inversion> {
        Binding {
            pad.mode == .scale ? pad.scale.inversion : pad.free.inversion
        } set: { newValue in
            if pad.mode == .scale { pad.scale.inversion = newValue }
            else { pad.free.inversion = newValue }
        }
    }

    private var voicingBinding: Binding<Voicing> {
        Binding {
            pad.mode == .scale ? pad.scale.voicing : pad.free.voicing
        } set: { newValue in
            if pad.mode == .scale { pad.scale.voicing = newValue }
            else { pad.free.voicing = newValue }
        }
    }

    // MARK: - Helpers

    private func romanNumeral(_ degree: Int, type: ChordType) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        guard degree >= 1 && degree <= 7 else { return "?" }
        var numeral = numerals[degree - 1]
        if type == .minor || type == .diminished { numeral = numeral.lowercased() }
        if type == .diminished { numeral += "°" }
        return numeral
    }
}

#Preview {
    EditSheetView(
        pad: Pad(),
        board: Board(name: "Preview"),
        midiEngine: MIDIEngine()
    ) { _ in }
}
