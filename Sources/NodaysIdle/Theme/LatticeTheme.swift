import SwiftUI

enum LatticeTheme {
    // MARK: - Core Palette
    // Near-black base — ink-dark, not space-dark
    static let void        = Color(hex: 0x0C0C0E)
    static let deepSpace   = Color(hex: 0x111113)
    static let nebula      = Color(hex: 0x161618)
    static let surface     = Color(hex: 0x1C1C1F)
    static let surfaceHover = Color(hex: 0x232326)
    static let surfaceRaised = Color(hex: 0x27272A)
    static let border      = Color(hex: 0x353539)
    static let borderStrong = Color(hex: 0x48484F)

    // MARK: - Accent Colors (flat, no glow variants)
    // Primary: mint/teal — clear, modern
    static let mint        = Color(hex: 0x2DD4BF)
    // Secondary: soft lavender — calm, distinctive
    static let lavender    = Color(hex: 0xA78BFA)
    // Warm: coral/peach — for ripe/hot items
    static let coral       = Color(hex: 0xFB7C6D)
    // Neutral amber — mid-state
    static let amber       = Color(hex: 0xF59E0B)

    // Legacy aliases — kept so call sites don't break during transition
    static let cyan        = mint
    static let violet      = lavender
    static let rose        = coral

    // MARK: - Text hierarchy
    static let textPrimary   = Color(hex: 0xEEEEF0)   // near-white, slightly warm
    static let textSecondary = Color(hex: 0xA0A0AA)   // mid gray — boosted
    static let textMuted     = Color(hex: 0x6B6B78)   // subtle — boosted
    static let textAccent    = mint                    // interactive / highlighted

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
