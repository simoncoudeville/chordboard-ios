import XCTest
@testable import chordboard_ios

// MARK: - MusicTheoryTests

final class MusicTheoryTests: XCTestCase {

    // MARK: - buildChord Tests

    func testBuildChord_CMajorClose() {
        // C4 major, root position, close voicing
        // Root MIDI: C4 = 60, intervals [0,4,7] -> [60, 64, 67]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 64, 67])
    }

    func testBuildChord_CMinorClose() {
        // C4 minor, root position: [60, 63, 67]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .minor, extension: .none, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 63, 67])
    }

    func testBuildChord_GMajorClose() {
        // G4 major: G4=67, [67, 71, 74]
        let notes = MusicTheory.buildChord(root: .g, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [67, 71, 74])
    }

    func testBuildChord_CMaj7() {
        // C4 maj7: [60, 64, 67, 71]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .maj7, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 64, 67, 71])
    }

    func testBuildChord_CMinor7() {
        // C4 minor 7: [60, 63, 67, 70]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .minor, extension: .seven, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 63, 67, 70])
    }

    func testBuildChord_CdiminishedDim7() {
        // C4 dim7: intervals [0,3,6,9] -> [60, 63, 66, 69]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .diminished, extension: .seven, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 63, 66, 69])
    }

    func testBuildChord_CMajorFirstInversion() {
        // C4 major first inversion: raise lowest (60) by octave -> [64, 67, 72]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .first, voicing: .close)
        XCTAssertEqual(notes, [64, 67, 72])
    }

    func testBuildChord_CMajorSecondInversion() {
        // C4 major second inversion: [60,64,67] -> first inv [64,67,72] -> second inv [67,72,76]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .second, voicing: .close)
        XCTAssertEqual(notes, [67, 72, 76])
    }

    func testBuildChord_CMajorOpenVoicing() {
        // C4 major open: [60,64,67] -> raise odd-indexed (64) by octave -> [60,76,67] -> sorted [60,67,76]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .open)
        XCTAssertEqual(notes, [60, 67, 76])
    }

    func testBuildChord_CMajorDrop2() {
        // C4 major drop2: [60,64,67] -> 2nd from highest (64) drop octave -> [52, 60, 67]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .drop2)
        XCTAssertEqual(notes, [52, 60, 67])
    }

    func testBuildChord_CMajorSpread() {
        // C4 major spread: [60,64,67] -> upper half (index >= 1) raised by octave -> [60, 76, 79]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .spread)
        XCTAssertEqual(notes, [60, 76, 79])
    }

    func testBuildChord_Power() {
        // C4 power: [60, 67]
        let notes = MusicTheory.buildChord(root: .c, octave: 4, type: .power, extension: .none, inversion: .root, voicing: .close)
        XCTAssertEqual(notes, [60, 67])
    }

    // MARK: - resolveScaleDegree Tests — C Major

    func testResolveScaleDegree_CMajor_Degree1() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 1)
        XCTAssertEqual(result.root, .c)
        XCTAssertEqual(result.type, .major)
    }

    func testResolveScaleDegree_CMajor_Degree2() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 2)
        XCTAssertEqual(result.root, .d)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_CMajor_Degree3() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 3)
        XCTAssertEqual(result.root, .e)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_CMajor_Degree4() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 4)
        XCTAssertEqual(result.root, .f)
        XCTAssertEqual(result.type, .major)
    }

    func testResolveScaleDegree_CMajor_Degree5() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 5)
        XCTAssertEqual(result.root, .g)
        XCTAssertEqual(result.type, .major)
    }

    func testResolveScaleDegree_CMajor_Degree6() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 6)
        XCTAssertEqual(result.root, .a)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_CMajor_Degree7() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .c, scaleType: .major, degree: 7)
        XCTAssertEqual(result.root, .b)
        XCTAssertEqual(result.type, .diminished)
    }

    // MARK: - resolveScaleDegree Tests — A Minor

    func testResolveScaleDegree_AMinor_Degree1() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 1)
        XCTAssertEqual(result.root, .a)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_AMinor_Degree2() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 2)
        XCTAssertEqual(result.root, .b)
        XCTAssertEqual(result.type, .diminished)
    }

    func testResolveScaleDegree_AMinor_Degree3() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 3)
        XCTAssertEqual(result.root, .c)
        XCTAssertEqual(result.type, .major)
    }

    func testResolveScaleDegree_AMinor_Degree4() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 4)
        XCTAssertEqual(result.root, .d)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_AMinor_Degree5() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 5)
        XCTAssertEqual(result.root, .e)
        XCTAssertEqual(result.type, .minor)
    }

    func testResolveScaleDegree_AMinor_Degree6() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 6)
        XCTAssertEqual(result.root, .f)
        XCTAssertEqual(result.type, .major)
    }

    func testResolveScaleDegree_AMinor_Degree7() {
        let result = MusicTheory.resolveScaleDegree(scaleRoot: .a, scaleType: .minor, degree: 7)
        XCTAssertEqual(result.root, .g)
        XCTAssertEqual(result.type, .major)
    }

    // MARK: - chordSymbol Tests

    func testChordSymbol_CMajor() {
        let sym = MusicTheory.chordSymbol(root: .c, type: .major, extension: .none, inversion: .root)
        XCTAssertEqual(sym, "C")
    }

    func testChordSymbol_CMinor() {
        let sym = MusicTheory.chordSymbol(root: .c, type: .minor, extension: .none, inversion: .root)
        XCTAssertEqual(sym, "Cm")
    }

    func testChordSymbol_CMinor7() {
        let sym = MusicTheory.chordSymbol(root: .c, type: .minor, extension: .seven, inversion: .root)
        XCTAssertEqual(sym, "Cm7")
    }

    func testChordSymbol_GMaj9() {
        let sym = MusicTheory.chordSymbol(root: .g, type: .major, extension: .maj9, inversion: .root)
        XCTAssertEqual(sym, "Gmaj9")
    }

    func testChordSymbol_BDiminished() {
        let sym = MusicTheory.chordSymbol(root: .b, type: .diminished, extension: .none, inversion: .root)
        XCTAssertEqual(sym, "Bdim")
    }

    func testChordSymbol_FSus4() {
        let sym = MusicTheory.chordSymbol(root: .f, type: .sus4, extension: .none, inversion: .root)
        XCTAssertEqual(sym, "Fsus4")
    }

    func testChordSymbol_DBbMaj7() {
        let sym = MusicTheory.chordSymbol(root: .db, type: .major, extension: .maj7, inversion: .root)
        XCTAssertEqual(sym, "D\u{266D}maj7")
    }

    // MARK: - allowedExtensions Tests

    func testAllowedExtensions_Major() {
        let exts = MusicTheory.allowedExtensions(for: .major)
        XCTAssertTrue(exts.contains(.none))
        XCTAssertTrue(exts.contains(.six))
        XCTAssertTrue(exts.contains(.maj7))
        XCTAssertTrue(exts.contains(.maj9))
        XCTAssertTrue(exts.contains(.seven))
        XCTAssertFalse(exts.contains(.eleven))
    }

    func testAllowedExtensions_Minor() {
        let exts = MusicTheory.allowedExtensions(for: .minor)
        XCTAssertTrue(exts.contains(.none))
        XCTAssertTrue(exts.contains(.seven))
        XCTAssertTrue(exts.contains(.eleven))
        XCTAssertFalse(exts.contains(.maj7))
        XCTAssertFalse(exts.contains(.sixNine))
    }

    func testAllowedExtensions_Diminished() {
        let exts = MusicTheory.allowedExtensions(for: .diminished)
        XCTAssertEqual(exts, [.none, .seven])
    }

    func testAllowedExtensions_HalfDiminished() {
        let exts = MusicTheory.allowedExtensions(for: .halfDiminished)
        XCTAssertEqual(exts, [.none])
    }

    func testAllowedExtensions_Power() {
        let exts = MusicTheory.allowedExtensions(for: .power)
        XCTAssertEqual(exts, [.none])
    }

    func testAllowedExtensions_Augmented() {
        let exts = MusicTheory.allowedExtensions(for: .augmented)
        XCTAssertTrue(exts.contains(.none))
        XCTAssertTrue(exts.contains(.maj7))
        XCTAssertTrue(exts.contains(.nine))
        XCTAssertFalse(exts.contains(.seven))
    }

    // MARK: - isValidChord Tests

    func testIsValidChord_InRange() {
        // C4 major close — all notes in range
        XCTAssertTrue(MusicTheory.isValidChord(root: .c, octave: 4, type: .major, extension: .none, inversion: .root, voicing: .close))
    }

    func testIsValidChord_TooLow() {
        // C0 major — root would be 12, below 24
        XCTAssertFalse(MusicTheory.isValidChord(root: .c, octave: 0, type: .major, extension: .none, inversion: .root, voicing: .close))
    }

    func testIsValidChord_TooHigh() {
        // C8 major — notes would exceed 107
        XCTAssertFalse(MusicTheory.isValidChord(root: .c, octave: 8, type: .major, extension: .none, inversion: .root, voicing: .close))
    }

    func testIsValidChord_BoundaryLow() {
        // C1 = MIDI 24, valid
        XCTAssertTrue(MusicTheory.isValidChord(root: .c, octave: 1, type: .major, extension: .none, inversion: .root, voicing: .close))
    }

    func testIsValidChord_BoundaryHigh() {
        // G6 major: [91,95,98] all <= 107, should be valid
        XCTAssertTrue(MusicTheory.isValidChord(root: .g, octave: 6, type: .major, extension: .none, inversion: .root, voicing: .close))
    }

    func testIsValidChord_ExtremeVoicingSpread() {
        // Spread voicing can push notes up an extra octave
        // C6 major spread: [84,88,91] -> upper half + 12 -> [84, 100, 103] — still valid
        XCTAssertTrue(MusicTheory.isValidChord(root: .c, octave: 6, type: .major, extension: .none, inversion: .root, voicing: .spread))
    }

    // MARK: - Scale Intervals Tests

    func testScaleIntervals_Major() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .major), [0, 2, 4, 5, 7, 9, 11])
    }

    func testScaleIntervals_Minor() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .minor), [0, 2, 3, 5, 7, 8, 10])
    }

    func testScaleIntervals_Dorian() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .dorian), [0, 2, 3, 5, 7, 9, 10])
    }

    func testScaleIntervals_Mixolydian() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .mixolydian), [0, 2, 4, 5, 7, 9, 10])
    }

    func testScaleIntervals_Lydian() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .lydian), [0, 2, 4, 6, 7, 9, 11])
    }

    func testScaleIntervals_Phrygian() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .phrygian), [0, 1, 3, 5, 7, 8, 10])
    }

    func testScaleIntervals_HarmonicMinor() {
        XCTAssertEqual(MusicTheory.scaleIntervals(for: .harmonicMinor), [0, 2, 3, 5, 7, 8, 11])
    }

    // MARK: - Chord Intervals Tests

    func testChordIntervals_Major_None() {
        XCTAssertEqual(MusicTheory.chordIntervals(type: .major, extension: .none), [0, 4, 7])
    }

    func testChordIntervals_Minor_None() {
        XCTAssertEqual(MusicTheory.chordIntervals(type: .minor, extension: .none), [0, 3, 7])
    }

    func testChordIntervals_HalfDiminished() {
        XCTAssertEqual(MusicTheory.chordIntervals(type: .halfDiminished, extension: .none), [0, 3, 6, 10])
    }

    func testChordIntervals_Major_Maj7() {
        let intervals = MusicTheory.chordIntervals(type: .major, extension: .maj7)
        XCTAssertTrue(intervals.contains(0))
        XCTAssertTrue(intervals.contains(4))
        XCTAssertTrue(intervals.contains(7))
        XCTAssertTrue(intervals.contains(11))
    }

    func testChordIntervals_Major_Nine() {
        let intervals = MusicTheory.chordIntervals(type: .major, extension: .nine)
        XCTAssertTrue(intervals.contains(10))
        XCTAssertTrue(intervals.contains(14))
    }

    // MARK: - Pitch Class Display Tests

    func testPitchClassDisplayNames() {
        XCTAssertEqual(PitchClass.c.displayName, "C")
        XCTAssertEqual(PitchClass.db.displayName, "D\u{266D}")
        XCTAssertEqual(PitchClass.eb.displayName, "E\u{266D}")
        XCTAssertEqual(PitchClass.gb.displayName, "G\u{266D}")
        XCTAssertEqual(PitchClass.ab.displayName, "A\u{266D}")
        XCTAssertEqual(PitchClass.bb.displayName, "B\u{266D}")
    }

    func testPitchClassFromMIDI() {
        XCTAssertEqual(PitchClass.from(midiNote: 60), .c)  // C4
        XCTAssertEqual(PitchClass.from(midiNote: 61), .db) // Db4
        XCTAssertEqual(PitchClass.from(midiNote: 67), .g)  // G4
        XCTAssertEqual(PitchClass.from(midiNote: 69), .a)  // A4
    }
}
