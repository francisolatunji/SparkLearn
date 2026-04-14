import SwiftUI

// MARK: - Confetti Burst Effect
struct ConfettiBurst: View {
    @Binding var isActive: Bool
    var particleCount: Int = 40
    var colors: [Color] = [DS.primary, DS.accent, DS.success, DS.gold, DS.electricBlue, DS.deepPurple]

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                ConfettiPiece(particle: particle, isActive: isActive)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateParticles()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isActive = false
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { i in
            ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? DS.primary,
                startX: CGFloat.random(in: -20...20),
                startY: 0,
                endX: CGFloat.random(in: -200...200),
                endY: CGFloat.random(in: -400 ... -100),
                rotation: Double.random(in: 0...720),
                scale: CGFloat.random(in: 0.4...1.0),
                duration: Double.random(in: 1.0...2.0),
                delay: Double(i) * 0.02,
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let duration: Double
    let delay: Double
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle, rectangle, star, triangle
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let isActive: Bool
    @State private var animated = false

    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle().fill(particle.color)
                    .frame(width: 8, height: 8)
            case .rectangle:
                Rectangle().fill(particle.color)
                    .frame(width: 10, height: 6)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(particle.color)
            case .triangle:
                Triangle().fill(particle.color)
                    .frame(width: 8, height: 8)
            }
        }
        .scaleEffect(animated ? particle.scale * 0.3 : particle.scale)
        .offset(
            x: animated ? particle.endX : particle.startX,
            y: animated ? particle.endY + 300 : particle.startY
        )
        .rotationEffect(.degrees(animated ? particle.rotation : 0))
        .opacity(animated ? 0 : 1)
        .onAppear {
            if isActive {
                withAnimation(.easeOut(duration: particle.duration).delay(particle.delay)) {
                    animated = true
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animated = false
                withAnimation(.easeOut(duration: particle.duration).delay(particle.delay)) {
                    animated = true
                }
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Lightning Rain Effect
struct LightningRainEffect: View {
    @Binding var isActive: Bool
    var boltCount: Int = 8

    @State private var bolts: [LightningBolt] = []

    var body: some View {
        ZStack {
            ForEach(bolts) { bolt in
                LightningBoltRain(bolt: bolt, isActive: isActive)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateBolts()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isActive = false
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func generateBolts() {
        bolts = (0..<boltCount).map { i in
            LightningBolt(
                id: i,
                x: CGFloat.random(in: -180...180),
                delay: Double(i) * 0.1,
                size: CGFloat.random(in: 20...40)
            )
        }
    }
}

struct LightningBolt: Identifiable {
    let id: Int
    let x: CGFloat
    let delay: Double
    let size: CGFloat
}

struct LightningBoltRain: View {
    let bolt: LightningBolt
    let isActive: Bool
    @State private var falling = false
    @State private var flash = false

    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: bolt.size, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "FDE68A"), Color(hex: "F97316")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .yellow.opacity(flash ? 0.8 : 0.2), radius: flash ? 12 : 4)
            .offset(x: bolt.x, y: falling ? 400 : -200)
            .opacity(falling ? 0 : 1)
            .onAppear {
                if isActive { animate() }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    falling = false
                    flash = false
                    animate()
                }
            }
    }

    private func animate() {
        withAnimation(.easeIn(duration: 0.4).delay(bolt.delay)) {
            falling = true
        }
        withAnimation(.easeInOut(duration: 0.1).delay(bolt.delay)) {
            flash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + bolt.delay + 0.15) {
            withAnimation(.easeOut(duration: 0.1)) { flash = false }
        }
    }
}

// MARK: - Sparkle Ring Effect (for achievements)
struct SparkleRingEffect: View {
    @Binding var isActive: Bool
    var color: Color = DS.gold
    var sparkleCount: Int = 12

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<sparkleCount, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...14), weight: .bold))
                    .foregroundColor(i.isMultiple(of: 2) ? color : .white)
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(i) * (360.0 / Double(sparkleCount))))
            }
        }
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(opacity)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.5)) {
                    scale = 1.2
                    opacity = 1
                }
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        opacity = 0
                        scale = 1.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isActive = false
                        rotation = 0
                        scale = 0.5
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Gem Burst Effect
struct GemBurstEffect: View {
    @Binding var isActive: Bool
    var gemCount: Int = 8

    @State private var gems: [(id: Int, x: CGFloat, y: CGFloat, rotation: Double)] = []
    @State private var animated = false

    var body: some View {
        ZStack {
            ForEach(gems, id: \.id) { gem in
                Image(systemName: "diamond.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "60A5FA"), Color(hex: "818CF8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "60A5FA").opacity(0.5), radius: 6)
                    .offset(x: animated ? gem.x : 0, y: animated ? gem.y : 0)
                    .rotationEffect(.degrees(animated ? gem.rotation : 0))
                    .opacity(animated ? 0 : 1)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animated = false
                gems = (0..<gemCount).map { i in
                    (id: i,
                     x: CGFloat.random(in: -120...120),
                     y: CGFloat.random(in: -200 ... -50),
                     rotation: Double.random(in: -360...360))
                }
                withAnimation(.easeOut(duration: 1.0)) {
                    animated = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isActive = false
                }
            }
        }
        .allowsHitTesting(false)
    }
}
