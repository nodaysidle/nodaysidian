import SwiftUI

enum LatticeTheme {
    // MARK: - Core Palette
    // Canonical NODAYSIDLE base — #0A0A0F
    static let void        = Color(hex: 0x0A0A0F)
    static let deepSpace   = Color(hex: 0x0E0E14)
    static let nebula      = Color(hex: 0x101018)
    static let surface     = Color(hex: 0x14141F)
    static let surfaceHover = Color(hex: 0x181825)
    static let surfaceRaised = Color(hex: 0x1C1C2A)
    static let border      = Color(hex: 0x2A2A3C)
    static let borderStrong = Color(hex: 0x3A3A50)

    // MARK: - Accent Colors — monotonic Volt (#C8FF00) opacity family
    static let volt        = Color(hex: 0xC8FF00)
    static let mint        = volt                      // primary accent
    static let lavender    = volt.opacity(0.60)        // secondary, calm
    static let amber       = volt.opacity(0.75)        // mid-state
    static let coral       = volt.opacity(0.92)        // hot / ripe

    // Legacy aliases — kept so call sites don't break during transition
    static let cyan        = mint
    static let violet      = lavender
    static let rose        = coral

    // MARK: - Text hierarchy
    static let textPrimary   = Color(hex: 0xF0F0F5)   // canonical primary
    static let textSecondary = Color(hex: 0x6B6B80)   // canonical secondary
    static let textMuted     = Color(hex: 0x4A4A55)   // dimmer than secondary
    static let textAccent    = volt                    // interactive / highlighted

    // MARK: - Ripeness — flat color steps, no glow
    static func ripenessColor(_ score: Double) -> Color {
        let clamped = max(0, min(1, score))
        switch clamped {
        case 0 ..< 0.30: return textMuted
        case 0.30 ..< 0.60: return mint
        case 0.60 ..< 0.85: return amber
        default: return coral
        }
    }

    // Kept for API compatibility — returns a low-opacity solid version, not a glow
    static func ripenessGlow(_ score: Double) -> Color {
        ripenessColor(score).opacity(0.45)
    }

    // MARK: - Node Sizing
    static func nodeRadius(connectionCount: Int) -> CGFloat {
        let base: CGFloat = 5
        let scale = min(CGFloat(connectionCount), 20)
        return base + scale * 1.1
    }

    // MARK: - Typography
    // Logotype — wide tracked, semibold rounded
    static let logotypeFont = Font.system(size: 11, weight: .semibold, design: .rounded)

    // Display — used for large headings, ultra-light for contrast
    static let displayFont = Font.system(size: 28, weight: .ultraLight, design: .rounded)

    // Title — sidebar section labels, card headings
    static let titleFont = Font.system(size: 13, weight: .semibold, design: .default)

    // Body — note content, descriptions
    static let bodyFont = Font.system(size: 13, weight: .regular, design: .default)

    // Caption — timestamps, sub-labels
    static let captionFont = Font.system(size: 11, weight: .medium, design: .default)

    // Mono — counts, numeric data, technical values
    static let monoFont = Font.system(size: 11, weight: .regular, design: .monospaced)

    // MARK: - Deprecated shadow names (kept for API compat — use border instead)
    static let glowShadow   = Color.clear
    static let subtleShadow = Color.black.opacity(0.5)
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8)  & 0xFF) / 255.0,
            blue:  Double(hex         & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - GlassCard — flat solid replacement, no material blur, no gradient
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LatticeTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(LatticeTheme.border, lineWidth: 1)
                    }
            }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
