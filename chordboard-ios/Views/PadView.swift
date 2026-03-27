import SwiftUI

// MARK: - PadView

struct PadView: View {
    let pad: Pad
    let boardScale: BoardScale
    var isPressed: Bool = false
    var onTap: () -> Void = {}
    var onLongPress: () -> Void = {}

    private var chordInfo: (root: PitchClass, type: ChordType)? {
        switch pad.mode {
        case .unassigned:
            return nil
        case .scale:
            guard boardScale.enabled else { return nil }
            return MusicTheory.resolveScaleDegree(
                scaleRoot: boardScale.root,
                scaleType: boardScale.type,
                degree: pad.scale.degree
            )
        case .free:
            return (pad.free.root, pad.free.type)
        }
    }

    private var chordSymbol: String? {
        guard let info = chordInfo else { return nil }
        let ext: ChordExtension
        let inv: Inversion
        switch pad.mode {
        case .scale:
            ext = pad.scale.chordExtension
            inv = pad.scale.inversion
        case .free:
            ext = pad.free.chordExtension
            inv = pad.free.inversion
        case .unassigned:
            return nil
        }
        return MusicTheory.chordSymbol(root: info.root, type: info.type, extension: ext, inversion: inv)
    }

    private var romanNumeral: String? {
        guard pad.mode == .scale, boardScale.enabled else { return nil }
        let info = chordInfo
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]
        let idx = pad.scale.degree - 1
        guard idx >= 0 && idx < numerals.count else { return nil }
        var numeral = numerals[idx]
        if info?.type == .minor || info?.type == .diminished {
            numeral = numeral.lowercased()
        }
        if info?.type == .diminished {
            numeral += "°"
        }
        return numeral
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)

                // Content
                VStack(spacing: 4) {
                    if pad.mode == .unassigned {
                        Text("UNASSIGNED")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        if let roman = romanNumeral {
                            Text(roman)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isPressed ? .white.opacity(0.8) : .secondary)
                        }
                        if let symbol = chordSymbol {
                            Text(symbol)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(isPressed ? .white : .primary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.1), value: isPressed)
        }
        .aspectRatio(1.0, contentMode: .fit)
    }

    private var backgroundColor: Color {
        if pad.mode == .unassigned {
            return Color(.systemGray6)
        }
        if isPressed {
            return Color.accentColor
        }
        return Color(.systemGray5)
    }

    private var borderColor: Color {
        if isPressed {
            return Color.accentColor
        }
        if pad.mode == .unassigned {
            return Color(.systemGray4).opacity(0.5)
        }
        return Color(.systemGray3)
    }
}

#Preview {
    let pad: Pad = {
        var p = Pad()
        p.mode = .free
        p.free.root = .c
        p.free.type = .major
        return p
    }()
    return PadView(pad: pad, boardScale: BoardScale(), isPressed: false)
        .frame(width: 100, height: 100)
        .padding()
}
