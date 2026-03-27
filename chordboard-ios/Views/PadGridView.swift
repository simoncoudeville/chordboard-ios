import SwiftUI

// MARK: - PadGridView

struct PadGridView: View {
    @Bindable var store: BoardStore
    var midiEngine: MIDIEngine

    @State private var pressedPadIDs: Set<UUID> = []
    @State private var padNotes: [UUID: [Int]] = [:]
    @State private var showingEditSheet = false
    @State private var selectedPad: Pad?
    @State private var activePitchClasses: Set<PitchClass> = []
    @State private var activeChordName: String = ""
    @State private var showingScaleSheet = false
    @State private var showingMIDISheet = false

    // Adaptive columns: 3 on iPhone, 4 on iPad
    private var columns: [GridItem] {
        let count = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    private var board: Board? {
        store.activeBoard
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Keyboard display
                KeyboardView(
                    activePitchClasses: activePitchClasses,
                    chordName: activeChordName
                )
                .padding(.top, 8)
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 8)

                // Pad grid
                if let board = board {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(board.pads.enumerated()), id: \.element.id) { index, pad in
                                PadCellView(
                                    pad: pad,
                                    boardScale: board.scale,
                                    isPressed: pressedPadIDs.contains(pad.id)
                                ) {
                                    // Tap handler (short tap on unassigned or long press opens edit)
                                    if pad.mode == .unassigned {
                                        selectedPad = pad
                                        showingEditSheet = true
                                    }
                                } onLongPress: {
                                    selectedPad = pad
                                    showingEditSheet = true
                                } onPadDown: { location, size in
                                    handlePadDown(pad: pad, board: board, location: location, size: size)
                                } onPadUp: {
                                    handlePadUp(pad: pad)
                                }
                            }
                        }
                        .padding(12)
                    }
                } else {
                    Spacer()
                    Text("No board selected")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .navigationTitle(board?.name ?? "Chordboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingScaleSheet = true
                    } label: {
                        Image(systemName: "music.note.list")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMIDISheet = true
                    } label: {
                        Image(systemName: "cable.connector")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let pad = selectedPad, let board = board {
                    EditSheetView(
                        pad: pad,
                        board: board,
                        midiEngine: midiEngine
                    ) { updatedPad in
                        store.updatePad(updatedPad, in: board.id)
                    }
                }
            }
            .sheet(isPresented: $showingScaleSheet) {
                if let board = board {
                    GlobalScaleView(board: board) { updatedBoard in
                        store.updateBoard(updatedBoard)
                    }
                }
            }
            .sheet(isPresented: $showingMIDISheet) {
                MIDISettingsView(midiEngine: midiEngine)
            }
        }
    }

    // MARK: - Gesture Handlers

    private func handlePadDown(pad: Pad, board: Board, location: CGPoint, size: CGSize) {
        guard pad.mode != .unassigned else { return }

        pressedPadIDs.insert(pad.id)

        // Normalize location to 0–1
        let normX = Float(max(0, min(1, location.x / size.width)))
        let normY = Float(max(0, min(1, location.y / size.height)))

        let (notes, velocity, strumValue, tiltValue, humanize) = expressionValues(
            pad: pad, board: board, normX: normX, normY: normY
        )

        padNotes[pad.id] = notes
        updateKeyboard(notes: Array(padNotes.values.flatMap { $0 }))

        // Play via MIDI engine
        if midiEngine.isEnabled {
            midiEngine.playNotes(notes, velocity: velocity, strumValue: strumValue, tiltValue: tiltValue, humanize: humanize)
        }
    }

    private func handlePadUp(pad: Pad) {
        pressedPadIDs.remove(pad.id)
        if let notes = padNotes.removeValue(forKey: pad.id) {
            if midiEngine.isEnabled {
                midiEngine.stopNotes(notes)
            }
        }
        updateKeyboard(notes: Array(padNotes.values.flatMap { $0 }))
    }

    private func expressionValues(
        pad: Pad, board: Board, normX: Float, normY: Float
    ) -> (notes: [Int], velocity: Float, strumValue: Float, tiltValue: Float, humanize: Float) {
        // Get chord info
        let (root, type, octave, ext, inv, voicing): (PitchClass, ChordType, Int, ChordExtension, Inversion, Voicing)

        switch pad.mode {
        case .scale:
            let info = MusicTheory.resolveScaleDegree(scaleRoot: board.scale.root, scaleType: board.scale.type, degree: pad.scale.degree)
            root = info.root
            type = info.type
            octave = pad.scale.octave
            ext = pad.scale.chordExtension
            inv = pad.scale.inversion
            voicing = pad.scale.voicing
        case .free:
            root = pad.free.root
            type = pad.free.type
            octave = pad.free.octave
            ext = pad.free.chordExtension
            inv = pad.free.inversion
            voicing = pad.free.voicing
        case .unassigned:
            return ([], 0.75, 0, 0, 0)
        }

        let notes = MusicTheory.buildChord(root: root, octave: octave, type: type, extension: ext, inversion: inv, voicing: voicing)

        // Map axes to expression
        var velocity: Float = 0.75
        var strumValue: Float = 0.0
        var tiltValue: Float = 0.0
        var humanize: Float = 0.0

        func applyAxis(_ axis: ExpressionAxis, axisValue: Float) {
            switch axis {
            case .none: break
            case .velocity:
                velocity = axisValue
            case .velocityTilt:
                tiltValue = (axisValue - 0.5) * 2 // map 0–1 to -1…1
            case .strum:
                strumValue = axisValue
            case .aftertouch:
                break // handled separately on move
            case .humanization:
                humanize = axisValue
            }
        }

        applyAxis(pad.axisSettings.x, axisValue: normX)
        applyAxis(pad.axisSettings.y, axisValue: normY)

        return (notes, velocity, strumValue, tiltValue, humanize)
    }

    private func updateKeyboard(notes: [Int]) {
        var pitchClasses = Set<PitchClass>()
        for note in notes {
            pitchClasses.insert(PitchClass.from(midiNote: note))
        }
        activePitchClasses = pitchClasses

        // Update chord name from first pressed pad
        if let firstPadID = pressedPadIDs.first,
           let board = board,
           let pad = board.pads.first(where: { $0.id == firstPadID }) {
            activeChordName = chordNameForPad(pad, board: board)
        } else {
            activeChordName = ""
        }
    }

    private func chordNameForPad(_ pad: Pad, board: Board) -> String {
        switch pad.mode {
        case .unassigned: return ""
        case .scale:
            let info = MusicTheory.resolveScaleDegree(scaleRoot: board.scale.root, scaleType: board.scale.type, degree: pad.scale.degree)
            return MusicTheory.chordSymbol(root: info.root, type: info.type, extension: pad.scale.chordExtension, inversion: pad.scale.inversion)
        case .free:
            return MusicTheory.chordSymbol(root: pad.free.root, type: pad.free.type, extension: pad.free.chordExtension, inversion: pad.free.inversion)
        }
    }
}

// MARK: - PadCellView (handles gestures)

struct PadCellView: View {
    let pad: Pad
    let boardScale: BoardScale
    var isPressed: Bool
    var onTap: () -> Void
    var onLongPress: () -> Void
    var onPadDown: (CGPoint, CGSize) -> Void
    var onPadUp: () -> Void

    @State private var cellSize: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            PadView(pad: pad, boardScale: boardScale, isPressed: isPressed)
                .onAppear { cellSize = geo.size }
                .onChange(of: geo.size) { _, newSize in cellSize = newSize }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isPressed {
                                onPadDown(value.location, cellSize)
                            }
                        }
                        .onEnded { _ in
                            onPadUp()
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            onLongPress()
                        }
                )
                .onTapGesture {
                    onTap()
                }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }
}

#Preview {
    let store = BoardStore()
    let engine = MIDIEngine()
    return PadGridView(store: store, midiEngine: engine)
}
