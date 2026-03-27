import SwiftUI

// MARK: - KeyboardView

/// Displays a single-octave mini keyboard (C–B) with highlighted pitch classes.
struct KeyboardView: View {
    var activePitchClasses: Set<PitchClass> = []
    var chordName: String = ""

    // White key order
    private let whiteKeys: [PitchClass] = [.c, .d, .e, .f, .g, .a, .b]
    // Black key positions (as fractions between white keys)
    private let blackKeys: [(pitch: PitchClass, position: Double)] = [
        (.db, 1.0), (.eb, 2.0), (.gb, 4.0), (.ab, 5.0), (.bb, 6.0)
    ]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let whiteKeyWidth = geo.size.width / CGFloat(whiteKeys.count)
                let blackKeyWidth = whiteKeyWidth * 0.65
                let blackKeyHeight = geo.size.height * 0.60

                ZStack(alignment: .topLeading) {
                    // White keys
                    HStack(spacing: 1) {
                        ForEach(whiteKeys, id: \.self) { pitch in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(activePitchClasses.contains(pitch) ? Color.accentColor.opacity(0.8) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                                )
                        }
                    }

                    // Black keys
                    ForEach(blackKeys, id: \.pitch) { keyInfo in
                        let xPos = (keyInfo.position / CGFloat(whiteKeys.count)) * geo.size.width - blackKeyWidth / 2 + whiteKeyWidth / 2
                        RoundedRectangle(cornerRadius: 2)
                            .fill(activePitchClasses.contains(keyInfo.pitch) ? Color.accentColor : Color.black)
                            .frame(width: blackKeyWidth, height: blackKeyHeight)
                            .offset(x: xPos, y: 0)
                    }
                }
            }
            .frame(height: 56)

            if !chordName.isEmpty {
                Text(chordName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    KeyboardView(
        activePitchClasses: [.c, .e, .g],
        chordName: "C major"
    )
    .frame(height: 80)
    .padding()
    .background(Color(.systemBackground))
}
