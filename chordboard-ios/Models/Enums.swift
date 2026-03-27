import Foundation

// MARK: - PadMode

enum PadMode: String, Codable, CaseIterable, Hashable {
    case unassigned
    case scale
    case free
}

// MARK: - ChordType

enum ChordType: String, Codable, CaseIterable, Hashable {
    case major
    case minor
    case diminished
    case halfDiminished
    case augmented
    case sus2
    case sus4
    case power

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        case .diminished: return "Diminished"
        case .halfDiminished: return "Half Dim"
        case .augmented: return "Augmented"
        case .sus2: return "Sus2"
        case .sus4: return "Sus4"
        case .power: return "Power"
        }
    }

    var symbol: String {
        switch self {
        case .major: return ""
        case .minor: return "m"
        case .diminished: return "dim"
        case .halfDiminished: return "m7b5"
        case .augmented: return "aug"
        case .sus2: return "sus2"
        case .sus4: return "sus4"
        case .power: return "5"
        }
    }
}

// MARK: - ChordExtension

enum ChordExtension: String, Codable, CaseIterable, Hashable {
    case none
    case six
    case sixNine
    case maj7
    case maj9
    case add9
    case seven
    case nine
    case eleven
    case thirteen

    var displayName: String {
        switch self {
        case .none: return "None"
        case .six: return "6"
        case .sixNine: return "6/9"
        case .maj7: return "maj7"
        case .maj9: return "maj9"
        case .add9: return "add9"
        case .seven: return "7"
        case .nine: return "9"
        case .eleven: return "11"
        case .thirteen: return "13"
        }
    }

    var symbol: String {
        switch self {
        case .none: return ""
        case .six: return "6"
        case .sixNine: return "6/9"
        case .maj7: return "maj7"
        case .maj9: return "maj9"
        case .add9: return "add9"
        case .seven: return "7"
        case .nine: return "9"
        case .eleven: return "11"
        case .thirteen: return "13"
        }
    }
}

// MARK: - Voicing

enum Voicing: String, Codable, CaseIterable, Hashable {
    case close
    case open
    case drop2
    case drop3
    case spread

    var displayName: String {
        switch self {
        case .close: return "Close"
        case .open: return "Open"
        case .drop2: return "Drop 2"
        case .drop3: return "Drop 3"
        case .spread: return "Spread"
        }
    }
}

// MARK: - Inversion

enum Inversion: String, Codable, CaseIterable, Hashable {
    case root
    case first
    case second
    case third
    case fourth
    case fifth
    case sixth

    var displayName: String {
        switch self {
        case .root: return "Root"
        case .first: return "1st"
        case .second: return "2nd"
        case .third: return "3rd"
        case .fourth: return "4th"
        case .fifth: return "5th"
        case .sixth: return "6th"
        }
    }

    var steps: Int {
        switch self {
        case .root: return 0
        case .first: return 1
        case .second: return 2
        case .third: return 3
        case .fourth: return 4
        case .fifth: return 5
        case .sixth: return 6
        }
    }
}

// MARK: - ExpressionAxis

enum ExpressionAxis: String, Codable, CaseIterable, Hashable {
    case none
    case velocity
    case velocityTilt
    case strum
    case aftertouch
    case humanization

    var displayName: String {
        switch self {
        case .none: return "None"
        case .velocity: return "Velocity"
        case .velocityTilt: return "Velocity Tilt"
        case .strum: return "Strum"
        case .aftertouch: return "Aftertouch"
        case .humanization: return "Humanization"
        }
    }
}

// MARK: - PitchClass

enum PitchClass: Int, Codable, CaseIterable, Hashable, Comparable {
    case c = 0
    case db
    case d
    case eb
    case e
    case f
    case gb
    case g
    case ab
    case a
    case bb
    case b

    var displayName: String {
        switch self {
        case .c: return "C"
        case .db: return "D\u{266D}"
        case .d: return "D"
        case .eb: return "E\u{266D}"
        case .e: return "E"
        case .f: return "F"
        case .gb: return "G\u{266D}"
        case .g: return "G"
        case .ab: return "A\u{266D}"
        case .a: return "A"
        case .bb: return "B\u{266D}"
        case .b: return "B"
        }
    }

    var sharpName: String {
        switch self {
        case .c: return "C"
        case .db: return "C\u{266F}"
        case .d: return "D"
        case .eb: return "D\u{266F}"
        case .e: return "E"
        case .f: return "F"
        case .gb: return "F\u{266F}"
        case .g: return "G"
        case .ab: return "G\u{266F}"
        case .a: return "A"
        case .bb: return "A\u{266F}"
        case .b: return "B"
        }
    }

    var isBlackKey: Bool {
        switch self {
        case .db, .eb, .gb, .ab, .bb: return true
        default: return false
        }
    }

    static func < (lhs: PitchClass, rhs: PitchClass) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(midiNote: Int) -> PitchClass {
        let pc = midiNote % 12
        return PitchClass(rawValue: pc) ?? .c
    }
}

// MARK: - ScaleType

enum ScaleType: String, Codable, CaseIterable, Hashable {
    case major
    case minor
    case dorian
    case mixolydian
    case lydian
    case phrygian
    case harmonicMinor

    var displayName: String {
        switch self {
        case .major: return "Major"
        case .minor: return "Minor"
        case .dorian: return "Dorian"
        case .mixolydian: return "Mixolydian"
        case .lydian: return "Lydian"
        case .phrygian: return "Phrygian"
        case .harmonicMinor: return "Harmonic Minor"
        }
    }

    var intervals: [Int] {
        switch self {
        case .major: return [0, 2, 4, 5, 7, 9, 11]
        case .minor: return [0, 2, 3, 5, 7, 8, 10]
        case .dorian: return [0, 2, 3, 5, 7, 9, 10]
        case .mixolydian: return [0, 2, 4, 5, 7, 9, 10]
        case .lydian: return [0, 2, 4, 6, 7, 9, 11]
        case .phrygian: return [0, 1, 3, 5, 7, 8, 10]
        case .harmonicMinor: return [0, 2, 3, 5, 7, 8, 11]
        }
    }

    /// Pitch classes that use flat accidentals in this scale
    var preferFlats: Bool {
        switch self {
        case .major:
            return false // depends on root, handled in preferredDisplayName
        case .minor, .dorian, .phrygian, .harmonicMinor:
            return true
        case .mixolydian, .lydian:
            return false
        }
    }
}
