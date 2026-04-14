import SwiftUI

struct DiagramLabelView: View {
    let labels: [DiagramLabel]
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var currentLabelIndex = 0
    @State private var correctTaps = 0
    @State private var tappedIndices: Set<Int> = []
    @State private var flashIndex: Int?
    @State private var flashCorrect = false
    @State private var targetPulse = false
    @State private var radarPhase: CGFloat = 0
    @State private var burstIndex: Int?
    @State private var burstProgress: CGFloat = 0

    var allDone: Bool { currentLabelIndex >= labels.count }

    var body: some View {
        VStack(spacing: 16) {
            if !allDone && !answered {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DS.primary)
                    Text("Tap the **\(labels[currentLabelIndex].componentName)**")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(DS.primaryLight)
                )
                .scaleEffect(targetPulse ? 1.02 : 1)
            }

            // Diagram
            ZStack {
                RoundedRectangle(cornerRadius: DS.cornerRadius)
                    .fill(Color(hex: "1E293B"))
                    .frame(height: 240)

                // Grid
                GridPatternView()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: DS.cornerRadius))

                GeometryReader { geo in
                    ForEach(Array(labels.enumerated()), id: \.element.id) { idx, label in
                        Button(action: { tapHotspot(idx) }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    // Radar pulse ring on current target
                                    if idx == currentLabelIndex && !answered && !tappedIndices.contains(idx) {
                                        Circle()
                                            .stroke(DS.primary.opacity(1 - radarPhase), lineWidth: 2)
                                            .frame(width: 46 + 30 * radarPhase, height: 46 + 30 * radarPhase)
                                    }

                                    // Particle burst on correct tap
                                    if burstIndex == idx {
                                        ForEach(0..<4, id: \.self) { i in
                                            Circle()
                                                .fill(DS.success)
                                                .frame(width: 6, height: 6)
                                                .offset(
                                                    x: cos(Double(i) * .pi / 2) * 30 * burstProgress,
                                                    y: sin(Double(i) * .pi / 2) * 30 * burstProgress
                                                )
                                                .opacity(1 - burstProgress)
                                        }
                                    }

                                    Circle()
                                        .fill(hotspotColor(idx))
                                        .frame(width: 46, height: 46)
                                        .shadow(color: hotspotColor(idx).opacity(flashIndex == idx ? 0.6 : 0), radius: 8)
                                        .scaleEffect(idx == currentLabelIndex && !answered ? 1.07 : 1)

                                    Image(systemName: label.symbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }

                                if tappedIndices.contains(idx) {
                                    Text(label.componentName)
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(DS.success.opacity(0.85)))
                                }
                            }
                            .position(
                                x: label.position.x * geo.size.width,
                                y: label.position.y * geo.size.height
                            )
                        }
                        .disabled(tappedIndices.contains(idx) || answered)
                    }
                }
                .frame(height: 240)
            }

            // Progress
            HStack(spacing: 6) {
                ForEach(0..<labels.count, id: \.self) { i in
                    Circle()
                        .fill(i < currentLabelIndex ? DS.success : DS.border)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                targetPulse = true
            }
            withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                radarPhase = 1
            }
        }
        .animation(DS.feedbackAnim, value: currentLabelIndex)
        .animation(DS.feedbackAnim, value: answered)
    }

    private func tapHotspot(_ index: Int) {
        guard !answered, !allDone else { return }
        let isCorrect = index == currentLabelIndex
        flashIndex = index
        flashCorrect = isCorrect

        if isCorrect {
            Haptics.light()
            correctTaps += 1
            tappedIndices.insert(index)

            // Trigger particle burst
            burstIndex = index
            burstProgress = 0
            withAnimation(.easeOut(duration: 0.5)) {
                burstProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { burstIndex = nil }

            currentLabelIndex += 1
            if allDone {
                wasCorrect = correctTaps == labels.count
                answered = true
                onAnswer(wasCorrect)
            }
        } else {
            Haptics.error()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { flashIndex = nil }
    }

    private func hotspotColor(_ idx: Int) -> Color {
        if tappedIndices.contains(idx) { return DS.success }
        if flashIndex == idx { return flashCorrect ? DS.success : DS.error }
        return DS.primary.opacity(0.7)
    }
}

struct GridPatternView: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 20
            for x in stride(from: 0, through: size.width, by: step) {
                var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(p, with: .color(.white.opacity(0.04)), lineWidth: 1)
            }
            for y in stride(from: 0, through: size.height, by: step) {
                var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(p, with: .color(.white.opacity(0.04)), lineWidth: 1)
            }
        }
    }
}
