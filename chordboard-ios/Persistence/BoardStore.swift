import Foundation
import Observation

// MARK: - BoardStore

@Observable
final class BoardStore {

    // MARK: - State

    var boards: [Board] = []
    var activeBoardID: UUID?

    // MARK: - File URL

    private let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("chordboard-ios", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("boards.json")
    }()

    // MARK: - UserDefaults Keys

    private enum Defaults {
        static let activeBoardID = "activeBoardID"
    }

    // MARK: - Init

    init() {
        load()
        restoreActiveBoardID()
        if boards.isEmpty {
            let defaultBoard = Board(name: "My Board")
            boards.append(defaultBoard)
            activeBoardID = defaultBoard.id
            save()
        }
    }

    // MARK: - Load / Save

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            boards = try decoder.decode([Board].self, from: data)
        } catch {
            print("BoardStore load error: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(boards)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("BoardStore save error: \(error)")
        }
    }

    // MARK: - Board Operations

    func addBoard(name: String = "New Board") -> Board {
        var board = Board(name: name)
        boards.append(board)
        activeBoardID = board.id
        saveActiveBoardID()
        save()
        return board
    }

    func deleteBoard(id: UUID) {
        boards.removeAll { $0.id == id }
        if activeBoardID == id {
            activeBoardID = boards.first?.id
            saveActiveBoardID()
        }
        save()
    }

    func deleteBoards(at offsets: IndexSet) {
        let idsToDelete = offsets.map { boards[$0].id }
        boards.remove(atOffsets: offsets)
        if let activeID = activeBoardID, idsToDelete.contains(activeID) {
            activeBoardID = boards.first?.id
            saveActiveBoardID()
        }
        save()
    }

    func renameBoard(id: UUID, newName: String) {
        guard let index = boards.firstIndex(where: { $0.id == id }) else { return }
        boards[index].name = newName
        boards[index].updatedAt = .now
        save()
    }

    func duplicateBoard(id: UUID) {
        guard let original = boards.first(where: { $0.id == id }) else { return }
        var copy = original
        copy.id = UUID()
        copy.name = "\(original.name) Copy"
        copy.createdAt = .now
        copy.updatedAt = .now
        copy.pads = original.pads.map { pad in
            var newPad = pad
            newPad.id = UUID()
            return newPad
        }
        if let index = boards.firstIndex(where: { $0.id == id }) {
            boards.insert(copy, at: index + 1)
        } else {
            boards.append(copy)
        }
        save()
    }

    func updateBoard(_ board: Board) {
        guard let index = boards.firstIndex(where: { $0.id == board.id }) else { return }
        var updated = board
        updated.updatedAt = .now
        boards[index] = updated
        save()
    }

    func updatePad(_ pad: Pad, in boardID: UUID) {
        guard let boardIndex = boards.firstIndex(where: { $0.id == boardID }) else { return }
        guard let padIndex = boards[boardIndex].pads.firstIndex(where: { $0.id == pad.id }) else { return }
        boards[boardIndex].pads[padIndex] = pad
        boards[boardIndex].updatedAt = .now
        save()
    }

    // MARK: - Active Board

    var activeBoard: Board? {
        get { boards.first { $0.id == activeBoardID } }
        set {
            if let board = newValue {
                updateBoard(board)
            }
        }
    }

    func setActiveBoard(id: UUID) {
        activeBoardID = id
        saveActiveBoardID()
    }

    // MARK: - UserDefaults

    private func saveActiveBoardID() {
        UserDefaults.standard.set(activeBoardID?.uuidString, forKey: Defaults.activeBoardID)
    }

    private func restoreActiveBoardID() {
        if let uuidString = UserDefaults.standard.string(forKey: Defaults.activeBoardID),
           let uuid = UUID(uuidString: uuidString) {
            activeBoardID = uuid
        }
        // Validate that the saved ID exists
        if let activeID = activeBoardID, !boards.contains(where: { $0.id == activeID }) {
            activeBoardID = boards.first?.id
        }
    }
}
