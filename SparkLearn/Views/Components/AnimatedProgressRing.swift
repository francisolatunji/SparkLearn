import SwiftUI

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8
    var color: Color = DS.primary
    var showPercentage: Bool = true
    var icon: String?

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.12), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.6), color, color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Glow dot at progress head
            if animatedProgress > 0.02 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth + 2, height: lineWidth + 2)
                    .shadow(color: color, radius: 4)
                    .offset(y: -size / 2)
                    .rotationEffect(.degrees(360 * animatedProgress - 90))
            }

            // Center content
            VStack(spacing: 2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundColor(color)
                }

                if showPercentage {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = min(1.0, progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animatedProgress = min(1.0, newValue)
            }
        }
    }
}

// MARK: - XP Progress Ring (specialized for daily XP goal)
struct XPProgressRing: View {
    let currentXP: Int
    let goalXP: Int
    var size: CGFloat = 70

    var progress: Double {
        guard goalXP > 0 else { return 0 }
        return min(1.0, Double(currentXP) / Double(goalXP))
    }

    var color: Color {
        if progress >= 1.0 { return DS.success }
        if progress >= 0.5 { return DS.primary }
        return DS.accent
    }

    var body: some View {
        AnimatedProgressRing(
            progress: progress,
            size: size,
            lineWidth: 6,
            color: color,
            showPercentage: false,
            icon: progress >= 1.0 ? "checkmark" : nil
        )
        .overlay(
            VStack(spacing: 0) {
                if progress < 1.0 {
                    Text("\(currentXP)")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                    Text("/\(goalXP)")
                        .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                        .foregroundColor(DS.textTertiary)
                }
            }
        )
    }
}

// MARK: - Streak Flame View
struct StreakFlameView: View {
    let streak: Int
    var size: CGFloat = 36
    @State private var flickering = false

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                // Outer glow
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.8, weight: .bold))
                    .foregroundColor(DS.accent.opacity(0.3))
                    .blur(radius: 4)
                    .scaleEffect(flickering ? 1.1 : 0.9)

                // Main flame
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.7, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: streak > 0 ? [Color(hex: "FF6B35"), Color(hex: "F7931E"), Color(hex: "FFD700")] : [DS.textTertiary, DS.textTertiary],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }

            Text("\(streak)")
                .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                .foregroundColor(streak > 0 ? DS.accent : DS.textTertiary)
        }
        .onAppear {
            guard streak > 0 else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flickering = true
            }
        }
    }
}

// MARK: - Heart Counter View
struct HeartCounterView: View {
    let hearts: Int
    let maxHearts: Int
    var nextHeartDate: Date?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<maxHearts, id: \.self) { i in
                Image(systemName: i < hearts ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(i < hearts ? DS.error : DS.textTertiary.opacity(0.4))
            }

            if hearts < maxHearts, let nextDate = nextHeartDate {
                Text(nextDate, style: .timer)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(DS.textTertiary)
                    .frame(width: 40)
            }
        }
    }
}

// MARK: - Level Badge
struct LevelBadge: View {
    let level: Int
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [DS.primary, DS.primaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: DS.primary.opacity(0.3), radius: 4, y: 2)

            Text("\(level)")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AnimatedProgressRing(progress: 0.73, color: DS.primary)
        XPProgressRing(currentXP: 85, goalXP: 120)
        StreakFlameView(streak: 7)
        HeartCounterView(hearts: 3, maxHearts: 5)
        LevelBadge(level: 12)
    }
    .padding()
    .background(DS.bg)
}
