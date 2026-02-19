import SwiftUI

// RipenessIndicator — premium flat design
// Outer ring: solid color stroke (no angular gradient)
// Inner fill: flat solid at lower opacity
// Score text: monospaced, precise weight

struct RipenessIndicator: View {
    let score: Double
    var size: CGFloat = 32

    var body: some View {
        let color = LatticeTheme.ripenessColor(score)

        ZStack {
            // Outer track ring — dark base
            Circle()
                .strokeBorder(LatticeTheme.surfaceRaised, lineWidth: 2)
                .frame(width: size, height: size)

            // Filled arc representing the score
            // Using a trim on a circle stroke gives a clean segmented feel
            Circle()
                .trim(from: 0, to: max(0, min(1, score)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            // Inner fill — flat, low opacity
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: size * 0.65, height: size * 0.65)

            // Score percentage — monospaced
            Text("\(Int(score * 100))")
                .font(.system(size: size * 0.27, weight: .semibold, design: .monospaced))
                .foregroundStyle(LatticeTheme.textPrimary)
        }
    }
}
