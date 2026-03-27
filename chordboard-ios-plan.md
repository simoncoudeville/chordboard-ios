# Chordboard iOS — SwiftUI Implementation Plan

## Project Setup

- **Xcode project**: SwiftUI + Swift, iOS 17 minimum
- **Frameworks**: CoreMIDI, CoreAudioKit, SwiftUI, Combine
- **No third-party dependencies** — music theory logic ported from the web app
- **Architecture**: `@Observable` models (iOS 17), no external state management
- **Persistence**: `Codable` + JSON file in Application Support

---

## Data Models

Define these first — everything else depends on them.

### Enums

```swift
enum PadMode: String, Codable { case unassigned, scale, free }

enum ChordType: String, Codable, CaseIterable {
    case major, minor, diminished, halfDiminished, augmented, sus2, sus4, power
}

enum ChordExtension: String, Codable {
    case none, six, sixNine, maj7, maj9, add9, seven, nine, eleven, thirteen
    // Valid options differ per ChordType — see allowedExtensions(for:)
}

enum Voicing: String, Codable, CaseIterable {
    case close, open, drop2, drop3, spread
}

enum Inversion: String, Codable, CaseIterable {
    case root, first, second, third, fourth, fifth, sixth
}

enum ExpressionAxis: String, Codable, CaseIterable {
    case none, velocity, velocityTilt, strum, aftertouch, humanization
}

enum PitchClass: Int, Codable, CaseIterable {
    case c=0, db, d, eb, e, f, gb, g, ab, a, bb, b
}

enum ScaleType: String, Codable, CaseIterable {
    case major, minor, dorian, mixolydian, lydian, phrygian, harmonicMinor
    // Each returns 7 semitone intervals from the root
}
```

### Structs

```swift
struct ScalePadSettings: Codable {
    var degree: Int = 1        // 1–7
    var octave: Int = 4
    var extension: ChordExtension = .none
    var inversion: Inversion = .root
    var voicing: Voicing = .close
}

struct FreePadSettings: Codable {
    var root: PitchClass = .c
    var type: ChordType = .major
    var octave: Int = 4
    var extension: ChordExtension = .none
    var inversion: Inversion = .root
    var voicing: Voicing = .close
}

struct PadAxisSettings: Codable {
    var x: ExpressionAxis = .none
    var y: ExpressionAxis = .none
}

struct Pad: Codable, Identifiable {
    var id = UUID()
    var mode: PadMode = .unassigned
    var assigned: Bool = false
    var scale: ScalePadSettings = .init()
    var free: FreePadSettings = .init()
    var settings: PadAxisSettings = .init()
}

struct BoardScale: Codable {
    var root: PitchClass = .c
    var type: ScaleType = .major
    var enabled: Bool = true
}

struct Board: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var pads: [Pad] = Array(repeating: Pad(), count: 12)
    var scale: BoardScale = .init()
    var createdAt: Date = .now
    var updatedAt: Date = .now
}
```

---

## Phase 1: Music Theory Engine

The hardest part. Port from `chordSystem.js` and `music.js`. Write unit tests before building any UI on top of this.

### 1a. Scale intervals

Each `ScaleType` returns its 7 semitone intervals from the root, e.g.:
- major: [0, 2, 4, 5, 7, 9, 11]
- minor: [0, 2, 3, 5, 7, 8, 10]
- dorian: [0, 2, 3, 5, 7, 9, 10]
- mixolydian: [0, 2, 4, 5, 7, 9, 10]
- lydian: [0, 2, 4, 6, 7, 9, 11]
- phrygian: [0, 1, 3, 5, 7, 8, 10]
- harmonicMinor: [0, 2, 3, 5, 7, 8, 11]

### 1b. Chord intervals by type

```
major:         [0, 4, 7]
minor:         [0, 3, 7]
diminished:    [0, 3, 6]
halfDiminished:[0, 3, 6, 10]   (always includes m7)
augmented:     [0, 4, 8]
sus2:          [0, 2, 7]
sus4:          [0, 5, 7]
power:         [0, 7]
```

Extensions add on top (semitones from root):
```
6: +9, 6/9: +9+14, maj7: +11, maj9: +11+14,
add9: +14, 7: +10, 9: +10+14, 11: +10+14+17, 13: +10+14+17+21
```
*(exact intervals vary by chord type — some extensions aren't valid for all types)*

### 1c. Chord builder

```swift
func buildChord(
    root: PitchClass,
    octave: Int,
    type: ChordType,
    extension: ChordExtension,
    inversion: Inversion,
    voicing: Voicing
) -> [Int]  // MIDI note numbers
```

Steps:
1. Get semitone intervals for type + extension
2. Starting from `root + octave * 12`, assign each interval, bumping octave when wrapping past 12
3. Apply inversion: for each inversion step, raise the lowest note by one octave
4. Apply voicing:
   - **close**: no change
   - **open**: raise odd-indexed notes by one octave
   - **drop2**: lower 2nd-from-highest by one octave
   - **drop3**: lower 3rd-from-highest by one octave
   - **spread**: raise upper-half notes by one octave
5. Sort ascending, return

### 1d. Scale degree resolver

```swift
func resolveScaleDegree(
    scaleRoot: PitchClass,
    scaleType: ScaleType,
    degree: Int   // 1–7
) -> (root: PitchClass, type: ChordType)
```

Build the triad on the given degree using the scale's intervals. Measure the third and fifth intervals to determine quality:
- 4+3 semitones → major
- 3+4 → minor
- 3+3 → diminished
- 4+4 → augmented

### 1e. Chord symbol formatter

```swift
func chordSymbol(root: PitchClass, type: ChordType, extension: ChordExtension, inversion: Inversion) -> String
// e.g. "Cm7", "Gmaj9", "Bdim", "Fsus4"
```

### 1f. Allowed extensions per chord type

```swift
func allowedExtensions(for type: ChordType) -> [ChordExtension]
// major:         [.none, .six, .sixNine, .maj7, .maj9, .add9, .seven, .nine, .thirteen]
// minor:         [.none, .six, .seven, .nine, .eleven, .thirteen, .add9]
// diminished:    [.none, .seven]
// halfDiminished:[.none]
// augmented:     [.none, .maj7, .nine]
// sus2:          [.none, .add9, .seven, .nine, .eleven, .thirteen]
// sus4:          [.none, .seven, .nine, .eleven, .thirteen]
// power:         [.none]
```

### 1g. Inversion/voicing bounds validator

Check whether an inversion or voicing step would push any note outside MIDI 24–107 (C1–B7). Used to disable UI controls.

### 1h. Enharmonic display

Given a `PitchClass` and a scale context, return the preferred display name (e.g. prefer Db over C# when the key is Db major).

---

## Phase 2: Core MIDI Engine

```swift
@Observable class MIDIEngine {
    var isEnabled: Bool = false
    var availableOutputs: [MIDIOutput] = []
    var selectedOutput: MIDIOutput?
    var selectedChannel: Int = 1  // 1–16

    func enable()
    func disable()
    func scanOutputs()

    func playNotes(_ notes: [Int], velocity: Float, at time: MIDITimeStamp)
    func stopNote(_ note: Int, at time: MIDITimeStamp)
    func sendAftertouch(_ value: Float)

    func saveSettings()
    func restoreSettings()
}
```

### Key behaviours

- **Scheduling**: Use `MIDITimeStamp` (host clock). CoreMIDI's `MIDISendEventList` accepts future timestamps natively — cleaner than the web version's `setTimeout` approach.
- **Note-off safety**: Schedule NoteOff at `noteOnTime + 20ms` minimum.
- **Cancel in-flight notes**: Track pending note-ons. On pad release, send immediate NoteOffs (with 20ms safety offset) for any notes already sent.
- **Strum**: Space notes evenly over 0–500ms based on X or Y axis value.
- **Humanization**: Per-note random velocity ±20% and timing ±35ms.
- **Velocity tilt**: Asymmetric velocity per note — higher velocity on bass or treble notes based on axis position.
- **Bluetooth MIDI**: Free with CoreMIDI — BLE MIDI devices appear in your output list automatically. Use `CABTMIDICentralViewController` (CoreAudioKit) for the Bluetooth scan UI.

### Expression axis mapping (on pad press)

| Axis value | `velocity` | `velocityTilt` | `strum` | `humanization` |
|---|---|---|---|---|
| 0–1 | Base velocity | Tilt bias ±1 | Duration 0–500ms | Amount 0–1 |

`aftertouch` is the only axis function that sends continuously while the pad is held and the finger moves.

---

## Phase 3: Persistence

```swift
class BoardStore {
    private let fileURL: URL  // ~/Library/Application Support/boards.json

    func load() -> [Board]
    func save(_ boards: [Board])
}
```

Also persist separately (UserDefaults is fine):
- Active board ID
- MIDI settings (output ID, channel, wasConnected)
- Changelog seen version

---

## Phase 4: SwiftUI Views

Build in this order:

### 4a. Board List View *(simplest, build first)*

- `List` of boards: name + formatted date
- Swipe actions: delete (with confirmation alert showing board name), rename
- Context menu: rename, duplicate, delete
- "New Board" button at bottom
- Tap to enter pad grid

### 4b. Pad Grid View

- `LazyVGrid` — 3 columns on iPhone, 4 on iPad
- Each pad cell:
  - Unassigned: muted, "UNASSIGNED", tap to open Edit sheet
  - Assigned: chord symbol centred, highlighted while pressed
- **Gesture**: `DragGesture(minimumDistance: 0)` to detect press + XY position
- Track location within cell bounds to get normalized 0–1 coordinates
- Support simultaneous multi-pad gestures

### 4c. Keyboard Display

- Single-octave mini keyboard (C–B) at the top of the pad grid view
- Custom `Canvas` or `Shape` draw: white keys as rectangles, black keys overlaid
- Highlights pitch classes currently sounding
- "Now playing" chord name below

### 4d. Edit Sheet *(most complex)*

- `NavigationStack` inside a `.sheet`
- **Mode toggle**: "In Scale" / "Free" (segmented control)
- **Scale mode**: degree picker showing roman numerals (I–VII) with chord quality
- **Free mode**: 12-key root grid + chord type picker
- **Both modes**: Extension, Voicing, Inversion pickers (filtered to valid options)
- **Transpose**: Up/Down buttons with hold-to-repeat
  - Use `Timer` or `Task { while held { await sleep(110ms); transpose() } }` with 350ms initial delay
  - Disable up/down if transpose would exceed MIDI 24–107
- **XY axis mapping**: Two pickers for X and Y axes
- **Chord preview**: Mini keyboard showing current chord notes
- **Play button**: Plays and holds the chord via MIDIEngine while pressed
- **Save / Cancel**: Save disabled when state matches initial snapshot (dirty tracking)

### 4e. Global Scale Sheet

- Toggle: enable/disable scale mode
- Root picker (12 pitch classes with enharmonic display)
- Scale type picker
- Inline warning: "Changing scale will reset N pads" / "Disabling will convert N pads to Free mode"
- On save: migrate affected pads (scale → free mode conversion preserves root, type, octave, extension, inversion, voicing)

### 4f. MIDI Settings Sheet

- Toggle to enable/disable MIDI output
- Output device list (from `MIDIEngine.availableOutputs`)
- Channel picker (1–16)
- Rescan button
- Bluetooth MIDI: button to present `CABTMIDICentralViewController`

---

## Phase 5: iPad Layout

- `NavigationSplitView`: board list in sidebar, pad grid as detail
- Larger pad grid: 4 columns
- Landscape: keyboard + controls beside the pad grid
- All sheets work as popovers on iPad

---

## Implementation Order

| Step | Task | Notes |
|------|------|-------|
| 1 | Data models — Pad, Board, enums | No logic yet, just types |
| 2 | Music theory engine | Write unit tests first, compare output against web app |
| 3 | Board list UI | Gets navigation working |
| 4 | Pad grid + tap to play | Works without MIDI — play system sounds as placeholder |
| 5 | CoreMIDI engine | Connect, play notes, scheduling |
| 6 | Wire MIDI to pad grid | Full note triggering with strum/humanization |
| 7 | Edit sheet | Largest single piece of work |
| 8 | Global scale sheet | Depends on chord builder |
| 9 | MIDI settings sheet | Depends on MIDIEngine |
| 10 | Persistence | Wire up save/load throughout |
| 11 | iPad layout | Split view, larger grid |
| 12 | Polish | Animations, haptics, App Store assets |

---

## Things That Are Easier Than the Web Version

- **MIDI scheduling** — CoreMIDI timestamps are native, no `setTimeout` hacks
- **Bluetooth MIDI** — free with CoreMIDI, devices appear automatically
- **Multi-touch** — `simultaneousGesture` is cleaner than pointer event juggling
- **Hold-to-repeat** — `Task` + `AsyncStream` or `Timer` is cleaner than JS intervals
- **No permission flow** — CoreMIDI doesn't require browser-style permission gating

## Things to Watch Out For

- **Chord builder correctness** — unit test specific chords and compare against the web app before building UI on top
- **Inversion + voicing interaction** — some combinations exceed MIDI range; bounds checking must be exact
- **Enharmonic display** — which accidental to show depends on scale key context, easy to get silently wrong
- **Strum cancellation** — CoreMIDI doesn't cancel scheduled events; track sent notes and send NoteOffs on release
