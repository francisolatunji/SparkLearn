import SwiftUI

// MARK: - Sparky the Mascot
// A lightning bolt character with limbs and a gray beard, drawn in SwiftUI.

struct MascotView: View {
    var size: CGFloat = 120
    var mood: MascotMood = .happy
    var animate: Bool = true

    @State private var bouncing = false
    @State private var blinking = false
    @State private var breathing = false
    @State private var showSparkles = false
    @State private var showTear = false
    @State private var tearOffset: CGFloat = 0
    @State private var cracklePhase = false

    var body: some View {
        ZStack {
            // Glow behind - mood-reactive
            Circle()
                .fill(glowColor.opacity(0.1))
                .frame(width: size * 1.3, height: size * 1.3)
                .scaleEffect(bouncing ? 1.08 : 1.0)

            // Celebration sparkles
            if mood == .celebrating && showSparkles {
                ForEach(0..<6, id: \.self) { i in
                    MascotSparkle(index: i, size: size)
                }
            }

            // Body: lightning bolt shape
            ZStack {
                // Lightning bolt body with sheen
                ZStack {
                    LightningBoltShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.55, height: size * 0.85)
                        .shadow(color: Color(hex: "F59E0B").opacity(0.3), radius: 8, y: 4)

                    // Diagonal highlight sheen
                    LightningBoltShape()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(bouncing ? 0.25 : 0.1), .clear],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .frame(width: size * 0.55, height: size * 0.85)
                }

                // Electric crackle lines (celebrating mood)
                if mood == .celebrating && cracklePhase {
                    ForEach(0..<3, id: \.self) { i in
                        CrackleLine(size: size, index: i)
                    }
                }

                // Face
                VStack(spacing: size * 0.02) {
                    HStack(spacing: size * 0.1) {
                        MascotEye(size: size * 0.11, mood: mood, blinking: blinking)
                        MascotEye(size: size * 0.11, mood: mood, blinking: blinking)
                    }

                    MascotMouth(size: size * 0.15, mood: mood)
                }
                .offset(y: -size * 0.05)

                // Sad tear
                if mood == .sad && showTear {
                    Circle()
                        .fill(Color(hex: "60A5FA"))
                        .frame(width: size * 0.04, height: size * 0.06)
                        .offset(x: size * 0.04, y: -size * 0.02 + tearOffset)
                        .opacity(tearOffset > size * 0.15 ? 0 : 1)
                }

                MascotBeard(size: size * 0.22)
                    .offset(y: size * 0.09)

                MascotLimb(size: size, side: .left, bouncing: bouncing)
                    .offset(x: -size * 0.33, y: size * 0.03)

                MascotLimb(size: size, side: .right, bouncing: bouncing)
                    .offset(x: size * 0.33, y: size * 0.03)

                HStack(spacing: size * 0.18) {
                    MascotLeg(size: size, bouncing: bouncing)
                    MascotLeg(size: size, bouncing: bouncing)
                }
                .offset(y: size * 0.42)
            }
            .offset(y: bouncing ? -4 : 4)
            .scaleEffect(breathing ? 1.02 : 0.98)
        }
        .frame(width: size * 1.3, height: size * 1.3)
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                bouncing = true
            }
            // Subtle breathing
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                breathing = true
            }
            // Blink every few seconds with occasional double-blink
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                performBlink()
                // 30% chance of double-blink
                if Int.random(in: 0...9) < 3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        performBlink()
                    }
                }
            }
            // Mood-specific effects
            if mood == .celebrating {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    showSparkles = true
                    cracklePhase = true
                }
            }
            if mood == .sad {
                startTearAnimation()
            }
        }
    }

    private var glowColor: Color {
        switch mood {
        case .celebrating: return DS.gold
        case .sad: return DS.error
        case .encouraging: return DS.success
        default: return DS.primary
        }
    }

    private func performBlink() {
        withAnimation(.easeInOut(duration: 0.12)) { blinking = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.12)) { blinking = false }
        }
    }

    private func startTearAnimation() {
        showTear = true
        tearOffset = 0
        withAnimation(.easeIn(duration: 1.2)) {
            tearOffset = size * 0.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            startTearAnimation()
        }
    }
}

// MARK: - Sparkle Effect for Celebrating Mood
private struct MascotSparkle: View {
    let index: Int
    let size: CGFloat
    @State private var visible = false

    private var angle: Double { Double(index) * 60.0 }
    private var radius: CGFloat { size * 0.55 }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.08, weight: .bold))
            .foregroundStyle(index.isMultiple(of: 2) ? DS.gold : .white)
            .offset(
                x: cos(angle * .pi / 180) * radius,
                y: sin(angle * .pi / 180) * radius
            )
            .scaleEffect(visible ? 1.0 : 0.3)
            .opacity(visible ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.8)
                    .delay(Double(index) * 0.1)
                    .repeatForever(autoreverses: false)
                ) {
                    visible = true
                }
            }
    }
}

// MARK: - Electric Crackle Lines
private struct CrackleLine: View {
    let size: CGFloat
    let index: Int
    @State private var flash = false

    var body: some View {
        Path { p in
            let startX = size * CGFloat([-0.22, 0.18, -0.05][index])
            let startY = size * CGFloat([-0.3, -0.25, 0.1][index])
            p.move(to: CGPoint(x: startX, y: startY))
            p.addLine(to: CGPoint(x: startX + size * 0.06, y: startY + size * 0.08))
            p.addLine(to: CGPoint(x: startX + size * 0.02, y: startY + size * 0.12))
            p.addLine(to: CGPoint(x: startX + size * 0.08, y: startY + size * 0.18))
        }
        .stroke(Color.yellow, lineWidth: 1.5)
        .opacity(flash ? 0.8 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).delay(Double(index) * 0.15).repeatForever(autoreverses: true)) {
                flash = true
            }
        }
    }
}

// MARK: - Mascot Moods
enum MascotMood {
    case happy, thinking, celebrating, sad, encouraging
    // New moods for Sparky 2.0
    case curious, proud, worried, sleepy, excited

    var dialogueOptions: [String] {
        switch self {
        case .happy: return ["Let's learn something new!", "You're doing great!", "Ready for more?"]
        case .thinking: return ["Hmm, let me think...", "That's a tricky one!", "Consider this..."]
        case .celebrating: return ["Amazing work!", "You nailed it!", "Perfect score!"]
        case .sad: return ["Don't give up!", "Try again!", "You'll get it next time!"]
        case .encouraging: return ["You can do this!", "Almost there!", "Keep going!"]
        case .curious: return ["What's this?", "Interesting...", "Tell me more!"]
        case .proud: return ["Look at you go!", "So proud!", "You're a natural!"]
        case .worried: return ["Be careful!", "Double-check that!", "Safety first!"]
        case .sleepy: return ["Time for a break?", "*yawn*", "Let's rest and review tomorrow!"]
        case .excited: return ["Ooh! New content!", "This is going to be fun!", "Let's gooo!"]
        }
    }
}

// MARK: - Sparky Costumes
enum SparkyCostume: String, CaseIterable, Codable {
    case defaultCostume = "default"
    case labCoat = "lab_coat"
    case hardHat = "hard_hat"
    case astronaut = "astronaut"
    case wizard = "wizard"
    case golden = "golden"

    var displayName: String {
        switch self {
        case .defaultCostume: return "Classic Sparky"
        case .labCoat: return "Lab Sparky"
        case .hardHat: return "Safety Sparky"
        case .astronaut: return "Space Sparky"
        case .wizard: return "Wizard Sparky"
        case .golden: return "Golden Sparky"
        }
    }

    var gemCost: Int {
        switch self {
        case .defaultCostume: return 0
        case .labCoat: return 200
        case .hardHat: return 200
        case .astronaut: return 350
        case .wizard: return 350
        case .golden: return 500
        }
    }

    var accessoryColor: Color {
        switch self {
        case .defaultCostume: return .clear
        case .labCoat: return .white
        case .hardHat: return Color(hex: "F59E0B")
        case .astronaut: return Color(hex: "E2E8F0")
        case .wizard: return Color(hex: "7C3AED")
        case .golden: return Color(hex: "FFD700")
        }
    }
}

// MARK: - Lightning Bolt Shape
struct LightningBoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // Simplified, friendly lightning bolt
        p.move(to: CGPoint(x: w * 0.55, y: 0))
        p.addLine(to: CGPoint(x: w * 0.85, y: 0))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.72, y: h * 0.42))
        p.addLine(to: CGPoint(x: w * 0.25, y: h))
        p.addLine(to: CGPoint(x: w * 0.45, y: h * 0.52))
        p.addLine(to: CGPoint(x: w * 0.2, y: h * 0.52))
        p.closeSubpath()

        // Round the corners slightly
        return p
    }
}

// MARK: - Eye Component
struct MascotEye: View {
    let size: CGFloat
    let mood: MascotMood
    let blinking: Bool

    private var pupilOffset: CGPoint {
        switch mood {
        case .thinking: return CGPoint(x: size * 0.08, y: -size * 0.03)
        case .sad: return CGPoint(x: 0, y: size * 0.05)
        default: return CGPoint(x: 0, y: -size * 0.05)
        }
    }

    var body: some View {
        ZStack {
            // White of eye
            Ellipse()
                .fill(.white)
                .frame(width: size, height: blinking ? size * 0.15 : size)

            if !blinking {
                // Pupil
                Circle()
                    .fill(Color(hex: "1E293B"))
                    .frame(width: size * 0.55, height: size * 0.55)
                    .offset(x: pupilOffset.x, y: pupilOffset.y)

                // Shine / star highlight
                if mood == .celebrating {
                    Image(systemName: "sparkle")
                        .font(.system(size: size * 0.22, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: -size * 0.08, y: -size * 0.08)
                } else {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.2, height: size * 0.2)
                        .offset(x: -size * 0.1, y: -size * 0.1)
                }
            }
        }
    }
}

// MARK: - Mouth Component
struct MascotMouth: View {
    let size: CGFloat
    let mood: MascotMood

    var body: some View {
        switch mood {
        case .happy, .celebrating:
            // Happy smile
            HappySmile()
                .stroke(Color(hex: "92400E"), lineWidth: size * 0.12)
                .frame(width: size, height: size * 0.5)
        case .thinking:
            // Straight line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "92400E"))
                .frame(width: size * 0.5, height: size * 0.1)
        case .sad:
            // Frown
            HappySmile()
                .stroke(Color(hex: "92400E"), lineWidth: size * 0.12)
                .frame(width: size * 0.7, height: size * 0.35)
                .rotationEffect(.degrees(180))
        case .encouraging:
            // Open smile
            Ellipse()
                .fill(Color(hex: "92400E"))
                .frame(width: size * 0.6, height: size * 0.4)
        }
    }
}

struct HappySmile: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY * 0.5))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY * 0.5),
            control: CGPoint(x: rect.midX, y: rect.height * 1.2)
        )
        return p
    }
}

private enum MascotSide {
    case left
    case right
}

private struct MascotLimb: View {
    let size: CGFloat
    let side: MascotSide
    let bouncing: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.03)
            .fill(Color(hex: "D97706"))
            .frame(width: size * 0.24, height: size * 0.06)
            .rotationEffect(.degrees(side == .left ? (bouncing ? -8 : -24) : (bouncing ? 8 : 24)))
    }
}

private struct MascotLeg: View {
    let size: CGFloat
    let bouncing: Bool

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(Color(hex: "92400E"))
                .frame(width: size * 0.06, height: size * 0.18)
            Capsule()
                .fill(Color(hex: "475569"))
                .frame(width: size * 0.14, height: size * 0.05)
                .offset(y: -size * 0.01)
        }
        .rotationEffect(.degrees(bouncing ? 4 : -4))
    }
}

private struct MascotBeard: View {
    let size: CGFloat

    var body: some View {
        VStack(spacing: -size * 0.08) {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color(hex: "CBD5E1"))
                .frame(width: size * 0.9, height: size * 0.26)

            HStack(spacing: size * 0.02) {
                Circle()
                    .fill(Color(hex: "E2E8F0"))
                    .frame(width: size * 0.46, height: size * 0.46)
                Circle()
                    .fill(Color(hex: "E2E8F0"))
                    .frame(width: size * 0.46, height: size * 0.46)
            }
        }
    }
}

// MARK: - Mascot with Speech Bubble
struct MascotWithMessage: View {
    let message: String
    var mood: MascotMood = .happy
    var mascotSize: CGFloat = 100

    var body: some View {
        VStack(spacing: 12) {
            MascotView(size: mascotSize, mood: mood)

            Text(message)
                .font(DS.bodyFont)
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

// MARK: - Empty State with Mascot
struct EmptyStateView: View {
    let message: String
    let submessage: String
    var mood: MascotMood = .encouraging

    var body: some View {
        VStack(spacing: 16) {
            MascotView(size: 100, mood: mood)

            Text(message)
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            Text(submessage)
                .font(DS.bodyFont)
                .foregroundColor(DS.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

#Preview {
    VStack(spacing: 40) {
        MascotView(size: 120, mood: .happy)
        MascotView(size: 80, mood: .celebrating)
        MascotWithMessage(message: "Great job! You're getting it!", mood: .celebrating, mascotSize: 80)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.bg)
}
