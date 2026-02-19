import SwiftUI

struct NoteListItem: View {
    let note: NoteEntity
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Ripeness indicator — flat solid dot, no shadow
            Circle()
                .fill(LatticeTheme.ripenessColor(note.ripenessScore))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.displayTitle)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .default))
                    .foregroundStyle(
                        isSelected ? LatticeTheme.textPrimary : LatticeTheme.textSecondary
                    )
                    .lineLimit(1)

                if !note.snippet.isEmpty {
                    Text(note.snippet)
                        .font(.system(size: 11.5, weight: .regular, design: .default))
                        .foregroundStyle(LatticeTheme.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let mod = note.modifiedAt {
                Text(mod.relativeFormatted)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(LatticeTheme.textMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(rowBackgroundColor)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(LatticeTheme.mint.opacity(0.55), lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private var rowBackgroundColor: Color {
        if isSelected  { return LatticeTheme.mint.opacity(0.15) }
        if isHovered   { return LatticeTheme.surfaceHover }
        return .clear
    }
}

extension Date {
    var relativeFormatted: String {
        let interval = -self.timeIntervalSinceNow
        if interval < 60     { return "now" }
        if interval < 3600   { return "\(Int(interval / 60))m" }
        if interval < 86400  { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}
