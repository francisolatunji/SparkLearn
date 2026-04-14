import SwiftUI
import UIKit
import AudioToolbox

enum AppPrefs {
    static let soundEffectsEnabledKey = "soundEffectsEnabled"
    static let hapticsEnabledKey = "hapticsEnabled"
}

// MARK: - Design Tokens (Duolingo-inspired)
struct DS {
    // Duo-inspired action palette
    static let duoGreen = Color(hex: "58CC02")
    static let duoGreenDark = Color(hex: "58A700")
    static let duoGreenLight = Color(hex: "89E219")
    static let duoGreenTint = Color(hex: "D7FFB8")
    static let duoBlue = Color(hex: "1CB0F6")
    static let duoBlueDark = Color(hex: "1899D6")
    static let duoBlueTint = Color(hex: "DDF4FF")
    static let duoRed = Color(hex: "FF4B4B")
    static let duoRedDark = Color(hex: "EA2B2B")
    static let duoRedTint = Color(hex: "FFE1E1")
    static let duoOrange = Color(hex: "FF9600")
    static let duoOrangeDark = Color(hex: "E68600")
    static let duoYellow = Color(hex: "FFC800")
    static let duoPurple = Color(hex: "CE82FF")
    static let duoPurpleDark = Color(hex: "B566E3")

    // Duo-inspired neutrals
    static let duoText = Color(hex: "4B4B4B")
    static let duoTextSecondary = Color(hex: "AFAFAF")
    static let duoBorder = Color(hex: "E5E5E5")
    static let duoBorderDark = Color(hex: "CECECE")
    static let duoBg = Color(hex: "F7F7F7")
    static let duoCardBg = Color.white
    static let duoShadow = Color(hex: "4B4B4B").opacity(0.08)

    // Legacy aliases → now point to Duo palette
    static let primary = duoGreen
    static let primaryDark = duoGreenDark
    static let primaryLight = duoGreenTint
    static let accent = duoOrange
    static let accentSoft = Color(hex: "FED7AA")
    static let mint = Color(hex: "14B8A6")
    static let gold = duoYellow
    static let electricBlue = Color(hex: "00D4FF")
    static let deepPurple = duoPurple
    static let warmGlow = Color(hex: "FDE68A")
    static let cardHighlight = Color.white.opacity(0.15)
    static let glassStroke = Color.white.opacity(0.25)

    static let success = duoGreen
    static let error = duoRed
    static let warning = duoOrange

    static let bg = duoBg
    static let cardBg = duoCardBg
    static let textPrimary = duoText
    static let textSecondary = Color(hex: "777777")
    static let textTertiary = duoTextSecondary
    static let border = duoBorder
    static let divider = Color(hex: "F1F5F9")
    static let bgTop = duoBg
    static let bgBottom = duoBg
    static let cardShadow = duoShadow

    // Typography (rounded like Duo)
    static let heroTitleFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 15, weight: .medium, design: .rounded)
    static let smallFont = Font.system(size: 13, weight: .medium, design: .rounded)
    static let buttonFont = Font.system(size: 17, weight: .bold, design: .rounded)

    // Spacing & radii
    static let cornerRadius: CGFloat = 16
    static let cardCorner: CGFloat = 16
    static let buttonCorner: CGFloat = 16
    static let pillRadius: CGFloat = 12
    static let padding: CGFloat = 20

    // MARK: - Accessibility

    /// Color-blind safe palette (deuteranopia-friendly alternatives)
    static let a11ySuccess = Color(hex: "2196F3") // Blue instead of green
    static let a11yError = Color(hex: "FF5722")   // Orange-red
    static let a11yWarning = Color(hex: "FF9800")  // Amber

    /// Check if user prefers reduced motion
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// Safe animation that respects reduced motion
    static func safeAnimation(_ animation: Animation = .easeInOut(duration: 0.3)) -> Animation? {
        prefersReducedMotion ? nil : animation
    }

    // Animations (Duo-style snappy)
    static let duoPress: Animation = .easeOut(duration: 0.1)
    static let duoSlide: Animation = .spring(response: 0.25, dampingFraction: 0.8)
    static let duoFill: Animation = .easeOut(duration: 0.3)
}

extension DS {
    static var heroBackground: some View {
        duoBg.ignoresSafeArea()
    }

    static var lessonBackground: some View {
        Color.white.ignoresSafeArea()
    }

    static let tapAnim: Animation = .easeOut(duration: 0.1)
    static let feedbackAnim: Animation = .spring(response: 0.25, dampingFraction: 0.8)
    static let transitionAnim: Animation = .easeInOut(duration: 0.25)
}

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

// MARK: - Haptics
struct Haptics {
    static func light() {
        guard UserDefaults.standard.object(forKey: AppPrefs.hapticsEnabledKey) as? Bool ?? true else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        guard UserDefaults.standard.object(forKey: AppPrefs.hapticsEnabledKey) as? Bool ?? true else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        guard UserDefaults.standard.object(forKey: AppPrefs.hapticsEnabledKey) as? Bool ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func error() {
        guard UserDefaults.standard.object(forKey: AppPrefs.hapticsEnabledKey) as? Bool ?? true else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

struct SoundCue {
    static func tap() {
        guard UserDefaults.standard.object(forKey: AppPrefs.soundEffectsEnabledKey) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func success() {
        guard UserDefaults.standard.object(forKey: AppPrefs.soundEffectsEnabledKey) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(1113)
    }

    static func error() {
        guard UserDefaults.standard.object(forKey: AppPrefs.soundEffectsEnabledKey) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(1053)
    }

    static func streak() {
        guard UserDefaults.standard.object(forKey: AppPrefs.soundEffectsEnabledKey) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(1025)
    }

    static func celebration() {
        guard UserDefaults.standard.object(forKey: AppPrefs.soundEffectsEnabledKey) as? Bool ?? true else { return }
        AudioServicesPlaySystemSound(1005)
    }
}

// MARK: - Duo 3D Button (signature Duolingo-style)
struct DuoButton: View {
    enum Variant {
        case green, blue, neutral, danger, orange, purple

        var bgColor: Color {
            switch self {
            case .green: DS.duoGreen
            case .blue: DS.duoBlue
            case .neutral: .white
            case .danger: DS.duoRed
            case .orange: DS.duoOrange
            case .purple: DS.duoPurple
            }
        }
        var shadowColor: Color {
            switch self {
            case .green: DS.duoGreenDark
            case .blue: DS.duoBlueDark
            case .neutral: DS.duoBorderDark
            case .danger: DS.duoRedDark
            case .orange: DS.duoOrangeDark
            case .purple: DS.duoPurpleDark
            }
        }
        var fgColor: Color {
            switch self {
            case .neutral: DS.duoText
            default: .white
            }
        }
        var borderColor: Color? {
            switch self {
            case .neutral: DS.duoBorder
            default: nil
            }
        }
    }

    let title: String
    var variant: Variant = .green
    var icon: String? = nil
    var fullWidth: Bool = true
    var small: Bool = false
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: small ? 14 : 16, weight: .bold))
                }
                Text(title)
                    .font(.system(size: small ? 15 : 17, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            .foregroundColor(variant.fgColor)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, small ? 20 : 24)
            .padding(.vertical, small ? 12 : 16)
            .background(
                ZStack {
                    // 3D shadow layer
                    RoundedRectangle(cornerRadius: DS.buttonCorner)
                        .fill(variant.shadowColor)

                    // Main surface — lifts on press
                    RoundedRectangle(cornerRadius: DS.buttonCorner)
                        .fill(variant.bgColor)
                        .overlay {
                            if let borderColor = variant.borderColor {
                                RoundedRectangle(cornerRadius: DS.buttonCorner)
                                    .stroke(borderColor, lineWidth: 2)
                            }
                        }
                        .offset(y: pressed ? 0 : -4)
                }
            )
            .offset(y: pressed ? 4 : 0)
        }
        .buttonStyle(DuoPressStyle(pressed: $pressed))
    }
}

// Legacy wrappers
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        DuoButton(title: title, variant: .green, icon: icon, action: action)
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        DuoButton(title: title, variant: .neutral, icon: icon, action: action)
    }
}

// Duo press-down style
struct DuoPressStyle: ButtonStyle {
    @Binding var pressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(DS.duoPress) {
                    pressed = newValue
                }
            }
    }
}

// Keep old name for compat
typealias PressDownStyle = DuoPressStyle

// MARK: - Progress Bar (Duo-style capsule)
struct ProgressBar: View {
    let progress: Double
    var color: Color = DS.duoGreen
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let fillWidth = max(0, geo.size.width * min(1, progress))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.duoBorder)

                Capsule()
                    .fill(color)
                    .frame(width: max(fillWidth, progress > 0 ? height : 0))
                    .animation(DS.duoFill, value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Card (with optional accent color top-edge gradient)
struct CardView<Content: View>: View {
    let accentColor: Color?
    let content: () -> Content

    init(accent: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.accentColor = accent
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.padding)
            .background(
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(DS.cardBg)
                    .overlay(alignment: .top) {
                        if let accent = accentColor {
                            RoundedRectangle(cornerRadius: DS.cardCorner)
                                .fill(
                                    LinearGradient(
                                        colors: [accent.opacity(0.12), .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
                    .shadow(color: DS.cardShadow, radius: 16, y: 10)
            )
    }
}

struct DSGlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(DS.padding)
            .background(
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .stroke(DS.glassStroke, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .allowsHitTesting(false)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
                    .shadow(color: DS.cardShadow, radius: 20, y: 12)
            )
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (i, sub) in subviews.enumerated() {
            sub.place(at: CGPoint(x: bounds.minX + result.positions[i].x,
                                  y: bounds.minY + result.positions[i].y),
                       anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for sub in subviews {
            let s = sub.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, s.height)
            x += s.width + spacing
            maxX = max(maxX, x)
        }
        return (positions, CGSize(width: maxX, height: y + rowH))
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    let duration: Double
    let delay: Double

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.4)
                .offset(x: phase * geo.size.width * 1.4 - geo.size.width * 0.2)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: duration)
                        .delay(delay)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
            }
            .mask(content)
        )
    }
}

extension View {
    func shimmer(duration: Double = 2.0, delay: Double = 1.0) -> some View {
        modifier(ShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - Glow Border Modifier
extension View {
    func glowBorder(color: Color, radius: CGFloat = 8, lineWidth: CGFloat = 2, cornerRadius: CGFloat = DS.cardCorner) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: lineWidth)
                .blur(radius: radius / 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color.opacity(0.5), lineWidth: lineWidth / 2)
        )
    }
}

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var floating = false
    let amplitude: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .offset(y: floating ? -amplitude : amplitude)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    floating = true
                }
            }
    }
}

extension View {
    func floating(amplitude: CGFloat = 4, duration: Double = 2.0) -> some View {
        modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
}

// MARK: - Pulse Glow Modifier
struct PulseGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var glowing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.6 : 0.1), radius: glowing ? radius : radius / 3)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

extension View {
    func pulseGlow(color: Color = DS.primary, radius: CGFloat = 12) -> some View {
        modifier(PulseGlowModifier(color: color, radius: radius))
    }
}

// MARK: - Real-Time Canvas Lightning Arc System
struct ElectricArcView: View {
    var color: Color = .yellow
    var branchColor: Color = Color(hex: "00D4FF")
    var arcCount: Int = 3
    var intensity: Double = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let seed = Int(time * 12) // change shape ~12x per second

                for i in 0..<arcCount {
                    let mainPath = generateLightningPath(
                        from: CGPoint(x: size.width * CGFloat(i + 1) / CGFloat(arcCount + 1), y: 0),
                        to: CGPoint(x: size.width / 2 + CGFloat.random(in: -30...30), y: size.height),
                        segments: 12,
                        jitter: 35 * intensity,
                        seed: seed + i * 1000
                    )

                    // Outer glow
                    context.stroke(
                        mainPath,
                        with: .color(color.opacity(0.15)),
                        style: StrokeStyle(lineWidth: 8 * intensity, lineCap: .round, lineJoin: .round)
                    )
                    // Mid glow
                    context.stroke(
                        mainPath,
                        with: .color(color.opacity(0.4)),
                        style: StrokeStyle(lineWidth: 3 * intensity, lineCap: .round, lineJoin: .round)
                    )
                    // Core
                    context.stroke(
                        mainPath,
                        with: .color(.white),
                        style: StrokeStyle(lineWidth: 1.5 * intensity, lineCap: .round, lineJoin: .round)
                    )

                    // Branch forks
                    let points = extractPoints(from: mainPath, count: 12)
                    for j in stride(from: 2, to: points.count - 2, by: 3) {
                        let branchEnd = CGPoint(
                            x: points[j].x + CGFloat.random(in: -50...50),
                            y: points[j].y + CGFloat.random(in: 20...60)
                        )
                        let branchPath = generateLightningPath(
                            from: points[j], to: branchEnd,
                            segments: 4, jitter: 15, seed: seed + j * 100 + i
                        )
                        context.stroke(
                            branchPath,
                            with: .color(branchColor.opacity(0.3)),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        context.stroke(
                            branchPath,
                            with: .color(.white.opacity(0.6)),
                            style: StrokeStyle(lineWidth: 0.8, lineCap: .round)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .blendMode(.plusLighter)
    }

    private func seededRandom(seed: Int, index: Int) -> CGFloat {
        let x = sin(Double(seed * 127 + index * 311)) * 43758.5453
        return CGFloat(x - x.rounded(.down)) * 2 - 1 // -1...1
    }

    private func generateLightningPath(from start: CGPoint, to end: CGPoint, segments: Int, jitter: CGFloat, seed: Int) -> Path {
        var path = Path()
        path.move(to: start)
        for i in 1..<segments {
            let t = CGFloat(i) / CGFloat(segments)
            let baseX = start.x + (end.x - start.x) * t
            let baseY = start.y + (end.y - start.y) * t
            let offsetX = seededRandom(seed: seed, index: i) * jitter
            let offsetY = seededRandom(seed: seed + 500, index: i) * jitter * 0.3
            path.addLine(to: CGPoint(x: baseX + offsetX, y: baseY + offsetY))
        }
        path.addLine(to: end)
        return path
    }

    private func extractPoints(from path: Path, count: Int) -> [CGPoint] {
        // Approximate evenly-spaced points along the path
        let rect = path.boundingRect
        guard !rect.isEmpty else { return [] }
        var points: [CGPoint] = []
        for i in 0...count {
            let t = CGFloat(i) / CGFloat(count)
            let y = rect.minY + rect.height * t
            let x = rect.midX + CGFloat.random(in: -10...10)
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
}

// MARK: - Real-Time Ember/Fire Particle System
struct EmberParticleView: View {
    var particleCount: Int = 60
    var baseColor: Color = .orange
    var secondaryColor: Color = .yellow
    var speed: Double = 2.5

    private let startOffsets: [CGFloat]
    private let startPhases: [CGFloat]
    private let sizes: [CGFloat]

    init(particleCount: Int = 60, baseColor: Color = .orange, secondaryColor: Color = .yellow, speed: Double = 2.5) {
        self.particleCount = particleCount
        self.baseColor = baseColor
        self.secondaryColor = secondaryColor
        self.speed = speed
        self.startOffsets = (0..<particleCount).map { _ in CGFloat.random(in: 0...1) }
        self.startPhases = (0..<particleCount).map { _ in CGFloat.random(in: 0...CGFloat.pi * 2) }
        self.sizes = (0..<particleCount).map { _ in CGFloat.random(in: 4...14) }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for i in 0..<particleCount {
                    let offset = startOffsets[i]
                    let phase = startPhases[i]
                    let particleSize = sizes[i]

                    let t = ((CGFloat(time / speed) + offset).truncatingRemainder(dividingBy: 1.0))
                    let invertedT = 1 - t

                    // Rise from bottom, drift sideways with sine wave
                    let x = size.width * (0.2 + offset * 0.6) + cos(CGFloat(time) * 2 + phase) * 20
                    let y = size.height * invertedT

                    let alpha = invertedT * invertedT // fade as it rises
                    let resolvedColor = i.isMultiple(of: 3) ? secondaryColor : baseColor

                    context.opacity = alpha
                    context.fill(
                        Circle().path(in: CGRect(x: x - particleSize / 2, y: y - particleSize / 2, width: particleSize, height: particleSize)),
                        with: .color(resolvedColor)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .blendMode(.plusLighter)
    }
}

// MARK: - Core Haptics Electric Shock Engine
import CoreHaptics

class SparkHaptics {
    static let shared = SparkHaptics()
    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    /// Electric shock: rapid staccato buzzes that feel like electricity
    func playElectricShock() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []

        // 8 rapid transient "zaps" with escalating intensity
        for i in 0..<8 {
            let intensity = CHHapticEventParameter(
                parameterID: .hapticIntensity,
                value: Float(0.4 + Double(i) * 0.08)
            )
            let sharpness = CHHapticEventParameter(
                parameterID: .hapticSharpness,
                value: Float(0.8 + Double(i) * 0.025)
            )
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.04
            ))
        }

        // Sustained buzz at the end
        let sustainIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let sustainSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [sustainIntensity, sustainSharpness],
            relativeTime: 0.35,
            duration: 0.15
        ))

        playPattern(events)
    }

    /// Celebration burst: rising intensity pops
    func playCelebration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []

        for i in 0..<5 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + Double(i) * 0.1))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.3 + Double(i) * 0.15))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.12
            ))
        }

        // Final big pop
        let bigIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let bigSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [bigIntensity, bigSharpness],
            relativeTime: 0.7
        ))

        playPattern(events)
    }

    /// Streak buzz: rhythmic double-tap pattern
    func playStreakBuzz() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events: [CHHapticEvent] = []

        for i in 0..<3 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            // Double tap
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: Double(i) * 0.2))
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: Double(i) * 0.2 + 0.06))
        }

        playPattern(events)
    }

    private func playPattern(_ events: [CHHapticEvent]) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Haptic play error: \(error)")
        }
    }
}

// MARK: - Animated MeshGradient Background (iOS 18+)
struct AnimatedMeshBackground: View {
    var darkMode: Bool = true

    private let darkColors: [Color] = [
        Color(hex: "0A0E27"), Color(hex: "0D1B3E"), Color(hex: "0A0E27"),
        Color(hex: "1A0A3E"), Color(hex: "162454"), Color(hex: "0D2847"),
        Color(hex: "0A0E27"), Color(hex: "0D1B3E"), Color(hex: "0A0E27")
    ]

    private let lightColors: [Color] = [
        Color(hex: "ECF4FF"), Color(hex: "DBEAFE"), Color(hex: "ECF4FF"),
        Color(hex: "FFF1E6"), Color(hex: "F0E6FF"), Color(hex: "E6F7FF"),
        Color(hex: "FFF9F4"), Color(hex: "F5F0FF"), Color(hex: "FFF9F4")
    ]

    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let colors = darkMode ? darkColors : lightColors

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animatedPoints(time: t),
                    colors: animatedColors(base: colors, time: t)
                )
            }
            .ignoresSafeArea()
        } else {
            // Fallback for iOS 17
            if darkMode {
                Color.black.ignoresSafeArea()
            } else {
                DS.heroBackground.ignoresSafeArea()
            }
        }
    }

    private func animatedPoints(time: Double) -> [SIMD2<Float>] {
        let drift: Float = 0.04
        return [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(0.5 + drift * Float(sin(time * 0.7)), 0),
            SIMD2<Float>(1, 0),

            SIMD2<Float>(0, 0.5 + drift * Float(cos(time * 0.5))),
            SIMD2<Float>(0.5 + drift * Float(sin(time * 0.9)), 0.5 + drift * Float(cos(time * 0.6))),
            SIMD2<Float>(1, 0.5 + drift * Float(sin(time * 0.8))),

            SIMD2<Float>(0, 1),
            SIMD2<Float>(0.5 + drift * Float(cos(time * 0.6)), 1),
            SIMD2<Float>(1, 1)
        ]
    }

    private func animatedColors(base: [Color], time: Double) -> [Color] {
        base.enumerated().map { i, color in
            let shift = sin(time * 0.4 + Double(i) * 0.7) * 0.08
            return shiftBrightness(of: color, by: shift)
        }
    }

    private func shiftBrightness(of color: Color, by amount: Double) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        b = max(0, min(1, b + CGFloat(amount)))
        return Color(hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: Double(a))
    }
}

// MARK: - XP Pop PhaseAnimator
enum XPPopPhase: CaseIterable {
    case idle, grow, bounce, settle

    var scale: Double {
        switch self {
        case .idle: 1.0
        case .grow: 1.6
        case .bounce: 0.85
        case .settle: 1.0
        }
    }

    var yOffset: Double {
        switch self {
        case .idle: 0
        case .grow: -20
        case .bounce: 5
        case .settle: 0
        }
    }

    var glow: Double {
        switch self {
        case .idle: 0
        case .grow: 1.0
        case .bounce: 0.5
        case .settle: 0
        }
    }
}

struct XPPopView: View {
    let xp: Int
    let trigger: Int

    var body: some View {
        Text("+\(xp) XP")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(DS.gold)
            .phaseAnimator(XPPopPhase.allCases, trigger: trigger) { content, phase in
                content
                    .scaleEffect(phase.scale)
                    .offset(y: phase.yOffset)
                    .shadow(color: DS.gold.opacity(phase.glow), radius: phase.glow * 15)
            } animation: { phase in
                switch phase {
                case .idle: .snappy(duration: 0.1)
                case .grow: .spring(response: 0.2, dampingFraction: 0.5)
                case .bounce: .spring(response: 0.15, dampingFraction: 0.6)
                case .settle: .smooth(duration: 0.2)
                }
            }
    }
}

// MARK: - Ripple Tap Effect
struct RippleTapModifier: ViewModifier {
    let color: Color
    @State private var rippleActive = false
    @State private var tapLocation: CGPoint = .zero

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: rippleActive ? max(geo.size.width, geo.size.height) * 2.5 : 0,
                               height: rippleActive ? max(geo.size.width, geo.size.height) * 2.5 : 0)
                        .position(tapLocation)
                        .opacity(rippleActive ? 0 : 0.6)
                        .animation(.easeOut(duration: 0.5), value: rippleActive)
                }
                .clipped()
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        tapLocation = value.location
                        rippleActive = false
                        DispatchQueue.main.async {
                            rippleActive = true
                        }
                    }
            )
    }
}

extension View {
    func rippleTap(color: Color = DS.primary) -> some View {
        modifier(RippleTapModifier(color: color))
    }
}
