import SwiftUI

struct CanvasListItem: View {
    let canvas: CanvasEntity
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.on.square")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LatticeTheme.lavender)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(canvas.displayTitle)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .default))
                    .foregroundStyle(isSelected ? LatticeTheme.textPrimary : LatticeTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("\(canvas.elementCount) elements")
                        .font(LatticeTheme.monoFont)
                        .foregroundStyle(LatticeTheme.textMuted)

                    if let mod = canvas.modifiedAt {
                        Text(mod, style: .relative)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(LatticeTheme.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    isSelected
                        ? LatticeTheme.lavender.opacity(0.12)
                        : isHovered
                            ? LatticeTheme.surfaceHover
                            : Color.clear
                )
        }
    }
}
