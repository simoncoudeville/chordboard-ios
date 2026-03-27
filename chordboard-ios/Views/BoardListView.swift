import SwiftUI

// MARK: - BoardListView

struct BoardListView: View {
    @Bindable var store: BoardStore
    var onSelectBoard: (Board) -> Void

    @State private var showingDeleteAlert = false
    @State private var boardToDelete: Board?
    @State private var showingRenameAlert = false
    @State private var boardToRename: Board?
    @State private var renameText = ""
    @State private var showingNewBoardAlert = false
    @State private var newBoardName = ""

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.boards) { board in
                    Button {
                        store.setActiveBoard(id: board.id)
                        onSelectBoard(board)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(dateFormatter.string(from: board.updatedAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.activeBoardID == board.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            boardToDelete = board
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            boardToRename = board
                            renameText = board.name
                            showingRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.duplicateBoard(id: board.id)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                    .contextMenu {
                        Button {
                            boardToRename = board
                            renameText = board.name
                            showingRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }

                        Button {
                            store.duplicateBoard(id: board.id)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        Divider()

                        Button(role: .destructive) {
                            boardToDelete = board
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    store.deleteBoards(at: offsets)
                }
            }
            .navigationTitle("Boards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        newBoardName = ""
                        showingNewBoardAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Delete Board?", isPresented: $showingDeleteAlert, presenting: boardToDelete) { board in
                Button("Delete \"\(board.name)\"", role: .destructive) {
                    store.deleteBoard(id: board.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { board in
                Text("This will permanently delete \"\(board.name)\" and all its pads.")
            }
            .alert("Rename Board", isPresented: $showingRenameAlert) {
                TextField("Board name", text: $renameText)
                Button("Rename") {
                    if let board = boardToRename, !renameText.isEmpty {
                        store.renameBoard(id: board.id, newName: renameText)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("New Board", isPresented: $showingNewBoardAlert) {
                TextField("Board name", text: $newBoardName)
                Button("Create") {
                    let name = newBoardName.isEmpty ? "New Board" : newBoardName
                    let board = store.addBoard(name: name)
                    onSelectBoard(board)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    BoardListView(store: BoardStore(), onSelectBoard: { _ in })
}
