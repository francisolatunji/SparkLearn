import SwiftUI

struct MultipleChoiceView: View {
    let options: [AnswerOption]
    let correctIndex: Int
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var selectedIndex: Int?
    @State private var shake = false
    @State private var pressedIndex: Int?
    @State private var showCorrectGlow = false

    private let letterLabels = ["A", "B", "C", "D", "E", "F", "G", "H"]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.element.id) { idx, option in
                Button(action: { selectAnswer(idx) }) {
                    HStack(spacing: 14) {
                        // Circle indicator with letter label
                        ZStack {
                            Circle()
                                .stroke(borderColor(idx), lineWidth: 2)
                                .frame(width: 28, height: 28)

                            if answered && idx == correctIndex {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(DS.success)
                            } else if answered && idx == selectedIndex && idx != correctIndex {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(DS.error)
                            } else {
                                Text(idx < letterLabels.count ? letterLabels[idx] : "\(idx + 1)")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(borderColor(idx))
                            }
                        }

                        Text(option.text)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(DS.textPrimary)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: DS.cornerRadius)
                                .fill(bgColor(idx))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                                        .stroke(borderColor(idx), lineWidth: selectedIndex == idx ? 2 : 1)
                                )

                            // Green shimmer pulse on correct answer
                            if answered && idx == correctIndex && showCorrectGlow {
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .fill(DS.success.opacity(0.12))
                                    .transition(.opacity)
                            }
                        }
                    )
                    .shadow(color: pressedIndex == idx ? DS.primary.opacity(0.2) : .clear, radius: pressedIndex == idx ? 12 : 0)
                    .scaleEffect(pressedIndex == idx ? 0.98 : 1)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !answered else { return }
                            pressedIndex = idx
                        }
                        .onEnded { _ in
                            pressedIndex = nil
                        }
                )
                .disabled(answered)
            }
        }
        .offset(x: shake ? -8 : 0)
        .animation(DS.tapAnim, value: pressedIndex)
        .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
        .animation(DS.feedbackAnim, value: answered)
    }

    private func selectAnswer(_ index: Int) {
        guard !answered else { return }
        Haptics.light()
        selectedIndex = index
        let correct = index == correctIndex
        wasCorrect = correct
        answered = true

        if correct {
            withAnimation(.easeIn(duration: 0.3)) { showCorrectGlow = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeOut(duration: 0.4)) { showCorrectGlow = false }
            }
        } else {
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
        }

        onAnswer(correct)
    }

    private func borderColor(_ idx: Int) -> Color {
        guard answered else {
            return selectedIndex == idx ? DS.primary : DS.border
        }
        if idx == correctIndex { return DS.success }
        if idx == selectedIndex { return DS.error }
        return DS.border.opacity(0.5)
    }

    private func bgColor(_ idx: Int) -> Color {
        guard answered else { return DS.cardBg }
        if idx == correctIndex { return DS.success.opacity(0.06) }
        if idx == selectedIndex { return DS.error.opacity(0.06) }
        return DS.cardBg
    }
}
