import SwiftUI

// MARK: - GlobalScaleView

struct GlobalScaleView: View {
    var board: Board
    var onSave: (Board) -> Void

    @State private var editedBoard: Board
    @Environment(\.dismiss) private var dismiss

    init(board: Board, onSave: @escaping (Board) -> Void) {
        self.board = board
        self.onSave = onSave
        self._editedBoard = State(initialValue: board)
    }

    private var isDirty: Bool { editedBoard != board }

    // Count pads affected by scale change
    private var affectedPadCount: Int {
        board.pads.filter { $0.mode == .scale }.count
    }

    // Count pads that would be converted when disabling scale
    private var scalePadCount: Int {
        board.pads.filter { $0.mode == .scale }.count
    }

    // Would root/type change reset scale pads?
    private var scaleChanged: Bool {
        editedBoard.scale.root != board.scale.root || editedBoard.scale.type != board.scale.type
    }

    // Would enabling/disabling change anything?
    private var enabledChanged: Bool {
        editedBoard.scale.enabled != board.scale.enabled
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Scale Mode", isOn: $editedBoard.scale.enabled)
                }

                if editedBoard.scale.enabled {
                    Section("Root Note") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                            ForEach(PitchClass.allCases, id: \.self) { pitch in
                                Button {
                                    editedBoard.scale.root = pitch
                                } label: {
                                    Text(pitch.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(editedBoard.scale.root == pitch ? Color.accentColor : Color(.systemGray5))
                                        .foregroundStyle(editedBoard.scale.root == pitch ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }

                    Section("Scale Type") {
                        Picker("Type", selection: $editedBoard.scale.type) {
                            ForEach(ScaleType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                }

                // Warnings
                if enabledChanged && !editedBoard.scale.enabled && scalePadCount > 0 {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scale Mode Disabled")
                                    .font(.headline)
                                Text("Disabling scale mode will convert \(scalePadCount) pad\(scalePadCount == 1 ? "" : "s") to Free mode, preserving their current chord settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if editedBoard.scale.enabled && scaleChanged && affectedPadCount > 0 {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scale Changed")
                                    .font(.headline)
                                Text("Changing the scale will reset \(affectedPadCount) pad\(affectedPadCount == 1 ? "" : "s") that are assigned to scale degrees.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Global Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedBoard = editedBoard

                        // Migration: disabling scale -> convert scale pads to free
                        if !editedBoard.scale.enabled && board.scale.enabled {
                            updatedBoard.pads = updatedBoard.pads.map { pad in
                                guard pad.mode == .scale else { return pad }
                                var newPad = pad
                                // Resolve current chord and copy to free settings
                                let info = MusicTheory.resolveScaleDegree(
                                    scaleRoot: board.scale.root,
                                    scaleType: board.scale.type,
                                    degree: pad.scale.degree
                                )
                                newPad.free.root = info.root
                                newPad.free.type = info.type
                                newPad.free.octave = pad.scale.octave
                                newPad.free.chordExtension = pad.scale.chordExtension
                                newPad.free.inversion = pad.scale.inversion
                                newPad.free.voicing = pad.scale.voicing
                                newPad.mode = .free
                                return newPad
                            }
                        }

                        onSave(updatedBoard)
                        dismiss()
                    }
                    .disabled(!isDirty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    GlobalScaleView(board: Board(name: "Preview")) { _ in }
}
