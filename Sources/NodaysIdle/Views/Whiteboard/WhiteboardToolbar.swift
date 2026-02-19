import SwiftUI

struct WhiteboardToolbar: View {
    @Bindable var whiteboard: WhiteboardViewModel

    var body: some View {
        HStack(spacing: 6) {
            // Tool buttons
            toolSection

            divider

            // Color controls
            colorSection

            divider

            // Stroke width
            strokeWidthSection

            divider

            // Undo / Redo
            undoRedoSection
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(LatticeTheme.surface)
                .overlay {
                    Capsule()
                        .strokeBorder(LatticeTheme.border, lineWidth: 1)
                }
        }
    }

    // MARK: - Tool Buttons

    private var toolSection: some View {
        HStack(spacing: 3) {
            ForEach(WhiteboardTool.allCases, id: \.self) { tool in
                Button {
                    whiteboard.activeTool = tool
                } label: {
                    Image(systemName: tool.icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(
                            whiteboard.activeTool == tool
                                ? LatticeTheme.mint
                                : LatticeTheme.textSecondary
                        )
                        .frame(width: 30, height: 26)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(
                                    whiteboard.activeTool == tool
                                        ? LatticeTheme.mint.opacity(0.15)
                                        : Color.clear
                                )
                        )
                }
                .buttonStyle(.plain)
                .help(tool.label)
            }
        }
    }

    // MARK: - Color Controls

    private var colorSection: some View {
        HStack(spacing: 6) {
            // Stroke color picker
            ColorPicker("", selection: Bindable(whiteboard).strokeColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 24, height: 24)

            // Fill toggle
            Button {
                whiteboard.hasFill.toggle()
                if whiteboard.hasFill && whiteboard.fillColor == nil {
                    whiteboard.fillColor = whiteboard.strokeColor.opacity(0.3)
                }
            } label: {
                if whiteboard.hasFill {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(whiteboard.fillColor ?? whiteboard.strokeColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(LatticeTheme.textSecondary, lineWidth: 1)
                        )
                        .frame(width: 18, height: 18)
                } else {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(LatticeTheme.textMuted, lineWidth: 1)
                        .frame(width: 18, height: 18)
                        .overlay(
                            // Diagonal line to indicate "no fill"
                            Path { path in
                                path.move(to: CGPoint(x: 2, y: 16))
                                path.addLine(to: CGPoint(x: 16, y: 2))
                            }
                            .stroke(LatticeTheme.textMuted, lineWidth: 0.5)
                        )
                }
            }
            .buttonStyle(.plain)
            .help(whiteboard.hasFill ? "Remove fill" : "Add fill")

            // Fill color picker (shown only when fill is active)
            if whiteboard.hasFill {
                ColorPicker("", selection: fillColorBinding, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 24, height: 24)
            }
        }
    }

    // Non-optional binding for fill color picker
    private var fillColorBinding: Binding<Color> {
        Binding<Color>(
            get: { whiteboard.fillColor ?? whiteboard.strokeColor },
            set: { whiteboard.fillColor = $0 }
        )
    }

    // MARK: - Stroke Width

    private var strokeWidthSection: some View {
        HStack(spacing: 4) {
            Image(systemName: "lineweight")
                .font(.system(size: 11))
                .foregroundStyle(LatticeTheme.textMuted)

            Slider(
                value: Bindable(whiteboard).strokeWidth,
                in: 1...6,
                step: 0.5
            )
            .frame(width: 60)
            .tint(LatticeTheme.mint)

            Text(String(format: "%.1f", whiteboard.strokeWidth))
                .font(LatticeTheme.monoFont)
                .foregroundStyle(LatticeTheme.textSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }

    // MARK: - Undo / Redo

    private var undoRedoSection: some View {
        HStack(spacing: 3) {
            Button {
                whiteboard.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        whiteboard.canUndo
                            ? LatticeTheme.textSecondary
                            : LatticeTheme.textMuted.opacity(0.4)
                    )
                    .frame(width: 28, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!whiteboard.canUndo)
            .help("Undo")

            Button {
                whiteboard.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(
                        whiteboard.canRedo
                            ? LatticeTheme.textSecondary
                            : LatticeTheme.textMuted.opacity(0.4)
                    )
                    .frame(width: 28, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!whiteboard.canRedo)
            .help("Redo")
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(LatticeTheme.border)
            .frame(width: 1, height: 20)
    }
}
