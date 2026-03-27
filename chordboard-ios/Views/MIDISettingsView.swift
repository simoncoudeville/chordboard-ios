import SwiftUI
import CoreAudioKit

// MARK: - MIDISettingsView

struct MIDISettingsView: View {
    @Bindable var midiEngine: MIDIEngine
    @State private var showingBTMIDI = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable MIDI Output", isOn: Binding(
                        get: { midiEngine.isEnabled },
                        set: { enabled in
                            if enabled { midiEngine.enable() }
                            else { midiEngine.disable() }
                            midiEngine.saveSettings()
                        }
                    ))
                }

                if midiEngine.isEnabled {
                    Section("Output Device") {
                        if midiEngine.availableOutputs.isEmpty {
                            Text("No MIDI outputs found")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(midiEngine.availableOutputs) { output in
                                Button {
                                    midiEngine.selectedOutput = output
                                    midiEngine.saveSettings()
                                } label: {
                                    HStack {
                                        Text(output.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if midiEngine.selectedOutput == output {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            midiEngine.scanOutputs()
                        } label: {
                            Label("Rescan Outputs", systemImage: "arrow.clockwise")
                        }
                    }

                    Section("Channel") {
                        Picker("MIDI Channel", selection: $midiEngine.selectedChannel) {
                            ForEach(1...16, id: \.self) { channel in
                                Text("Channel \(channel)").tag(channel)
                            }
                        }
                        .onChange(of: midiEngine.selectedChannel) { _, _ in
                            midiEngine.saveSettings()
                        }
                    }

                    Section("Bluetooth MIDI") {
                        Button {
                            showingBTMIDI = true
                        } label: {
                            Label("Connect Bluetooth Device", systemImage: "bluetooth")
                        }
                    }
                }
            }
            .navigationTitle("MIDI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingBTMIDI) {
                BluetoothMIDIView()
            }
        }
    }
}

// MARK: - BluetoothMIDIView

struct BluetoothMIDIView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let btVC = CABTMIDICentralViewController()
        let nav = UINavigationController(rootViewController: btVC)
        btVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: context.coordinator,
            action: #selector(Coordinator.done)
        )
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        @objc func done() { dismiss() }
    }
}

#Preview {
    MIDISettingsView(midiEngine: MIDIEngine())
}
