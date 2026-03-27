import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var store = BoardStore()
    @State private var midiEngine = MIDIEngine()
    @State private var selectedBoard: Board?
    @State private var showingBoardList = false

    private var isIPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    var body: some View {
        if isIPad {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    // MARK: - iPhone Layout

    @ViewBuilder
    private var iPhoneLayout: some View {
        if store.boards.isEmpty {
            // Should not happen since BoardStore creates a default board
            VStack {
                Text("No boards yet")
                Button("Create Board") {
                    _ = store.addBoard()
                }
            }
        } else {
            TabView {
                // Pad grid for active board
                PadGridView(store: store, midiEngine: midiEngine)
                    .tabItem {
                        Label("Board", systemImage: "square.grid.3x3.fill")
                    }

                // Board list
                BoardListView(store: store) { board in
                    store.setActiveBoard(id: board.id)
                }
                .tabItem {
                    Label("Boards", systemImage: "list.bullet")
                }
            }
        }
    }

    // MARK: - iPad Layout

    @ViewBuilder
    private var iPadLayout: some View {
        NavigationSplitView {
            BoardListView(store: store) { board in
                store.setActiveBoard(id: board.id)
            }
        } detail: {
            PadGridView(store: store, midiEngine: midiEngine)
        }
    }
}

#Preview {
    ContentView()
}
