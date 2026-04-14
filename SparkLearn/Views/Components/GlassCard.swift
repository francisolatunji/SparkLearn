import SwiftUI

// MARK: - Enhanced Glass Card with Gradient Accent
struct GlassCardAccent<Content: View>: View {
    let accentColor: Color
    let content: () -> Content

    init(accent: Color = DS.primary, @ViewBuilder content: @escaping () -> Content) {
        self.accentColor = accent
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .fill(.ultraThinMaterial)

                    // Top accent gradient
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.2), accentColor.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )

                    // Glass stroke
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )

                    // Inner highlight
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
                .shadow(color: accentColor.opacity(0.15), radius: 20, y: 10)
            )
    }
}

// MARK: - Dark Glass Card (for overlays on 3D content)
struct DarkGlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.padding)
            .background(
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(.black.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
    }
}

// MARK: - Stat Chip
struct StatChip: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = DS.primary

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
            }
            Text(label)
                .font(DS.smallFont)
                .foregroundColor(DS.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Icon Badge
struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}
