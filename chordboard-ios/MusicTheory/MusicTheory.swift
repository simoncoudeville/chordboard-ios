import Foundation

// MARK: - MusicTheory namespace

enum MusicTheory {

    // MARK: - Scale Intervals

    static func scaleIntervals(for type: ScaleType) -> [Int] {
        type.intervals
    }

    // MARK: - Chord Intervals

    /// Returns all semitone intervals (from root) for a given chord type + extension.
    static func chordIntervals(type: ChordType, extension ext: ChordExtension) -> [Int] {
        var base: [Int]
        switch type {
        case .major:         base = [0, 4, 7]
        case .minor:         base = [0, 3, 7]
        case .diminished:    base = [0, 3, 6]
        case .halfDiminished: base = [0, 3, 6, 10]
        case .augmented:     base = [0, 4, 8]
        case .sus2:          base = [0, 2, 7]
        case .sus4:          base = [0, 5, 7]
        case .power:         base = [0, 7]
        }

        // Only add extension intervals if it's a valid extension for this type
        let allowed = allowedExtensions(for: type)
        guard allowed.contains(ext) else { return base }

        // halfDiminished always includes m7 in base; skip adding 7 again
        switch ext {
        case .none:
            break
        case .six:
            base.append(9)
        case .sixNine:
            base.append(contentsOf: [9, 14])
        case .maj7:
            base.append(11)
        case .maj9:
            base.append(contentsOf: [11, 14])
        case .add9:
            base.append(14)
        case .seven:
            // For diminished chord, dim7 = 9 semitones; for others = 10
            if type == .diminished {
                base.append(9)
            } else {
                base.append(10)
            }
        case .nine:
            if type == .diminished {
                base.append(contentsOf: [9, 14])
            } else {
                base.append(contentsOf: [10, 14])
            }
        case .eleven:
            base.append(contentsOf: [10, 14, 17])
        case .thirteen:
            base.append(contentsOf: [10, 14, 17, 21])
        }

        return base.sorted()
    }

    // MARK: - Chord Builder

    /// Builds a chord and returns MIDI note numbers.
    static func buildChord(
        root: PitchClass,
        octave: Int,
        type: ChordType,
        extension ext: ChordExtension,
        inversion: Inversion,
        voicing: Voicing
    ) -> [Int] {
        let intervals = chordIntervals(type: type, extension: ext)
        let rootMIDI = root.rawValue + (octave + 1) * 12

        // Step 1: Build note array from root + intervals
        var notes: [Int] = intervals.map { rootMIDI + $0 }

        // Step 2: Apply inversion — for each step, raise the lowest note by one octave
        let invSteps = min(inversion.steps, notes.count - 1)
        for _ in 0..<invSteps {
            notes.sort()
            notes[0] += 12
        }
        notes.sort()

        // Step 3: Apply voicing
        switch voicing {
        case .close:
            break // no change

        case .open:
            // Raise odd-indexed notes by one octave
            for i in stride(from: 1, to: notes.count, by: 2) {
                notes[i] += 12
            }

        case .drop2:
            // Lower 2nd-from-highest by one octave
            notes.sort()
            if notes.count >= 2 {
                notes[notes.count - 2] -= 12
            }

        case .drop3:
            // Lower 3rd-from-highest by one octave
            notes.sort()
            if notes.count >= 3 {
                notes[notes.count - 3] -= 12
            }

        case .spread:
            // Raise upper-half notes by one octave
            notes.sort()
            let half = notes.count / 2
            for i in half..<notes.count {
                notes[i] += 12
            }
        }

        notes.sort()
        return notes
    }

    // MARK: - Scale Degree Resolver

    /// Resolves the chord root and type for a given scale degree (1-based).
    static func resolveScaleDegree(
        scaleRoot: PitchClass,
        scaleType: ScaleType,
        degree: Int
    ) -> (root: PitchClass, type: ChordType) {
        let intervals = scaleIntervals(for: scaleType)
        let degreeIndex = (degree - 1 + 7) % 7

        let rootInterval = intervals[degreeIndex]
        let thirdInterval = intervals[(degreeIndex + 2) % 7]
        let fifthInterval = intervals[(degreeIndex + 4) % 7]

        // Calculate third and fifth relative to degree root
        let thirdSemitones = (thirdInterval - rootInterval + 12) % 12
        let fifthSemitones = (fifthInterval - rootInterval + 12) % 12

        let chordType: ChordType
        if thirdSemitones == 4 && fifthSemitones == 7 {
            chordType = .major
        } else if thirdSemitones == 3 && fifthSemitones == 7 {
            chordType = .minor
        } else if thirdSemitones == 3 && fifthSemitones == 6 {
            chordType = .diminished
        } else if thirdSemitones == 4 && fifthSemitones == 8 {
            chordType = .augmented
        } else {
            chordType = .major // fallback
        }

        let rootPC = PitchClass(rawValue: (scaleRoot.rawValue + rootInterval) % 12) ?? .c
        return (root: rootPC, type: chordType)
    }

    // MARK: - Chord Symbol Formatter

    static func chordSymbol(
        root: PitchClass,
        type: ChordType,
        extension ext: ChordExtension,
        inversion: Inversion
    ) -> String {
        var symbol = root.displayName

        switch type {
        case .major:
            break
        case .minor:
            symbol += "m"
        case .diminished:
            symbol += "dim"
        case .halfDiminished:
            symbol += "m7b5"
        case .augmented:
            symbol += "aug"
        case .sus2:
            symbol += "sus2"
        case .sus4:
            symbol += "sus4"
        case .power:
            symbol += "5"
        }

        switch ext {
        case .none:
            break
        case .six:
            symbol += "6"
        case .sixNine:
            symbol += "6/9"
        case .maj7:
            // Don't double up "maj7b5"
            if type == .halfDiminished {
                break
            }
            symbol += "maj7"
        case .maj9:
            symbol += "maj9"
        case .add9:
            symbol += "add9"
        case .seven:
            if type == .diminished {
                symbol += "dim7"
                // replace the "dim" we already appended
                return root.displayName + "dim7"
            }
            symbol += "7"
        case .nine:
            symbol += "9"
        case .eleven:
            symbol += "11"
        case .thirteen:
            symbol += "13"
        }

        // Inversion slash notation
        if inversion != .root {
            let notes = buildChord(root: root, octave: 4, type: type, extension: ext, inversion: inversion, voicing: .close)
            if let bassNote = notes.first {
                let bassPC = PitchClass(rawValue: bassNote % 12) ?? root
                if bassPC != root {
                    symbol += "/\(bassPC.displayName)"
                }
            }
        }

        return symbol
    }

    // MARK: - Allowed Extensions

    static func allowedExtensions(for type: ChordType) -> [ChordExtension] {
        switch type {
        case .major:
            return [.none, .six, .sixNine, .maj7, .maj9, .add9, .seven, .nine, .thirteen]
        case .minor:
            return [.none, .six, .seven, .nine, .eleven, .thirteen, .add9]
        case .diminished:
            return [.none, .seven]
        case .halfDiminished:
            return [.none]
        case .augmented:
            return [.none, .maj7, .nine]
        case .sus2:
            return [.none, .add9, .seven, .nine, .eleven, .thirteen]
        case .sus4:
            return [.none, .seven, .nine, .eleven, .thirteen]
        case .power:
            return [.none]
        }
    }

    // MARK: - Validity Checker

    static let midiMin = 24
    static let midiMax = 107

    static func isValidChord(
        root: PitchClass,
        octave: Int,
        type: ChordType,
        extension ext: ChordExtension,
        inversion: Inversion,
        voicing: Voicing
    ) -> Bool {
        let notes = buildChord(root: root, octave: octave, type: type, extension: ext, inversion: inversion, voicing: voicing)
        return notes.allSatisfy { $0 >= midiMin && $0 <= midiMax }
    }

    // MARK: - Enharmonic Display

    /// Returns the preferred display name for a pitch class in the context of a given scale.
    static func preferredDisplayName(for pitch: PitchClass, in scale: BoardScale) -> String {
        // Scales that prefer flats
        let flatRoots: Set<PitchClass> = [.f, .bb, .eb, .ab, .db, .gb]
        let useFlats: Bool

        if flatRoots.contains(scale.root) {
            useFlats = true
        } else {
            // Minor/dorian/phrygian scales generally prefer flats for accidentals
            switch scale.type {
            case .minor, .dorian, .phrygian, .harmonicMinor:
                useFlats = true
            default:
                useFlats = false
            }
        }

        if useFlats {
            return pitch.displayName
        } else {
            return pitch.sharpName
        }
    }

    // MARK: - Allowed Inversions

    /// Returns the maximum number of inversions available for a chord (based on note count).
    static func maxInversion(type: ChordType, extension ext: ChordExtension) -> Inversion {
        let intervals = chordIntervals(type: type, extension: ext)
        let noteCount = intervals.count
        // Can invert up to noteCount - 1 times
        switch noteCount - 1 {
        case 0: return .root
        case 1: return .first
        case 2: return .second
        case 3: return .third
        case 4: return .fourth
        case 5: return .fifth
        case 6: return .sixth
        default: return .root
        }
    }
}
