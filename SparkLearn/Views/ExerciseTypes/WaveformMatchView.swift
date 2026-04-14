import SwiftUI

// MARK: - Waveform Match Exercise
/// Match oscilloscope waveforms to circuit behaviors
struct WaveformMatchView: View {
    let question: String
    let waveforms: [WaveformOption]
    let correctIndex: Int
    let onComplete: (Bool) -> Void

    @State private var selectedIndex: Int?
    @State private var answered = false

    var body: some View {
        VStack(spacing: 20) {
            // Question
            VStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 28))
                    .foregroundColor(DS.electricBlue)

                Text(question)
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.padding)
            }

            // Waveform options
            VStack(spacing: 12) {
                ForEach(waveforms.indices, id: \.self) { index in
                    WaveformCard(
                        waveform: waveforms[index],
                        isSelected: selectedIndex == index,
                        isCorrect: answered && index == correctIndex,
                        isWrong: answered && selectedIndex == index && index != correctIndex
                    ) {
                        guard !answered else { return }
                        selectedIndex = index
                        answered = true

                        let correct = index == correctIndex
                        if correct {
                            Haptics.success()
                            SoundCue.success()
                        } else {
                            Haptics.error()
                            SoundCue.error()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onComplete(correct)
                        }
                    }
                }
            }
            .padding(.horizontal, DS.padding)

            Spacer()
        }
    }
}

// MARK: - Waveform Option
struct WaveformOption: Identifiable {
    let id = UUID()
    let label: String
    let type: WaveformType
    let frequency: Double
    let amplitude: Double

    enum WaveformType {
        case sine, square, triangle, sawtooth, dc, noise
    }
}

// MARK: - Waveform Card
struct WaveformCard: View {
    let waveform: WaveformOption
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Waveform display
                WaveformShape(type: waveform.type, amplitude: waveform.amplitude)
                    .stroke(waveformColor, lineWidth: 2.5)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.05))
                    )
                    .overlay(
                        // Grid lines
                        VStack(spacing: 12) {
                            Divider().opacity(0.2)
                            Divider().opacity(0.3)
                            Divider().opacity(0.2)
                        }
                    )

                Text(waveform.label)
                    .font(DS.captionFont)
                    .foregroundColor(DS.textPrimary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                    .shadow(color: DS.cardShadow, radius: isSelected ? 8 : 4, y: isSelected ? 6 : 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(DS.tapAnim, value: isSelected)
    }

    private var waveformColor: Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.error }
        return DS.electricBlue
    }

    private var backgroundColor: Color {
        if isCorrect { return DS.success.opacity(0.08) }
        if isWrong { return DS.error.opacity(0.08) }
        return DS.cardBg
    }

    private var borderColor: Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.error }
        if isSelected { return DS.primary }
        return DS.border
    }
}

// MARK: - Waveform Shape
struct WaveformShape: Shape {
    let type: WaveformOption.WaveformType
    let amplitude: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amp = rect.height * 0.4 * amplitude

        switch type {
        case .sine:
            path.move(to: CGPoint(x: 0, y: midY))
            for x in stride(from: 0, to: rect.width, by: 1) {
                let progress = x / rect.width
                let y = midY - amp * sin(progress * .pi * 4)
                path.addLine(to: CGPoint(x: x, y: y))
            }

        case .square:
            let period = rect.width / 3
            path.move(to: CGPoint(x: 0, y: midY))
            for i in 0..<3 {
                let startX = CGFloat(i) * period
                path.addLine(to: CGPoint(x: startX, y: midY - amp))
                path.addLine(to: CGPoint(x: startX + period / 2, y: midY - amp))
                path.addLine(to: CGPoint(x: startX + period / 2, y: midY + amp))
                path.addLine(to: CGPoint(x: startX + period, y: midY + amp))
            }

        case .triangle:
            let period = rect.width / 3
            path.move(to: CGPoint(x: 0, y: midY))
            for i in 0..<3 {
                let startX = CGFloat(i) * period
                path.addLine(to: CGPoint(x: startX + period / 4, y: midY - amp))
                path.addLine(to: CGPoint(x: startX + period * 3 / 4, y: midY + amp))
                path.addLine(to: CGPoint(x: startX + period, y: midY))
            }

        case .sawtooth:
            let period = rect.width / 3
            path.move(to: CGPoint(x: 0, y: midY + amp))
            for i in 0..<3 {
                let startX = CGFloat(i) * period
                path.addLine(to: CGPoint(x: startX + period, y: midY - amp))
                path.addLine(to: CGPoint(x: startX + period, y: midY + amp))
            }

        case .dc:
            path.move(to: CGPoint(x: 0, y: midY - amp * 0.5))
            path.addLine(to: CGPoint(x: rect.width, y: midY - amp * 0.5))

        case .noise:
            path.move(to: CGPoint(x: 0, y: midY))
            for x in stride(from: 0, to: rect.width, by: 3) {
                let y = midY + CGFloat.random(in: -amp...amp)
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}
