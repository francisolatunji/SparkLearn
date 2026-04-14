import SwiftUI

struct TapToFillView: View {
    let template: String
    let tokens: [String]
    let correctOrder: [String]
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var filledTokens: [String] = []
    @State private var usedIndices: Set<Int> = []
    @State private var shake = false
    @State private var pressedTokenIndex: Int?

    private var blankCount: Int {
        template.components(separatedBy: "___").count - 1
    }

    var body: some View {
        VStack(spacing: 24) {
            // Template with blanks
            templateDisplay
                .padding(DS.padding)
                .background(
                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                        .fill(DS.cardBg)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                )

            // Token bank
            if !answered {
                FlowLayout(spacing: 10) {
                    ForEach(Array(tokens.enumerated()), id: \.offset) { idx, token in
                        Button(action: { tapToken(idx) }) {
                            Text(token)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(usedIndices.contains(idx) ? DS.textTertiary : DS.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(DS.cardBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    usedIndices.contains(idx) ? DS.border : DS.primary.opacity(0.3),
                                                    lineWidth: 1.5
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
                                )
                                // 3D chip inner shadow overlay
                                .overlay(
                                    VStack {
                                        Spacer()
                                        LinearGradient(
                                            colors: [.clear, .black.opacity(0.06)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 12)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .allowsHitTesting(false)
                                )
                                .scaleEffect(pressedTokenIndex == idx ? 0.96 : 1)
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    guard !answered else { return }
                                    pressedTokenIndex = idx
                                }
                                .onEnded { _ in
                                    pressedTokenIndex = nil
                                }
                        )
                        .disabled(usedIndices.contains(idx) || answered)
                    }
                }
            }
        }
        .offset(x: shake ? -8 : 0)
        .animation(DS.tapAnim, value: pressedTokenIndex)
        .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
        .animation(DS.feedbackAnim, value: answered)
    }

    private var templateDisplay: some View {
        let parts = template.components(separatedBy: "___")
        return FlowLayout(spacing: 6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { idx, part in
                if !part.isEmpty {
                    Text(part)
                        .font(.system(size: 17, weight: .medium, design: .monospaced))
                        .foregroundColor(DS.textPrimary)
                }
                if idx < blankCount {
                    if idx < filledTokens.count {
                        Text(filledTokens[idx])
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(answered
                                          ? (filledTokens[idx] == correctOrder[idx] ? DS.success : DS.error)
                                          : DS.primary)
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: filledTokens.count)
                            .onTapGesture {
                                guard !answered else { return }
                                Haptics.light()
                                removeFilled(at: idx)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(DS.primary.opacity(0.4))
                            .frame(width: 64, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(DS.primary.opacity(0.05))
                                    .opacity(idx == filledTokens.count && !answered ? 1 : 0)
                            )
                    }
                }
            }
        }
    }

    private func tapToken(_ tokenIndex: Int) {
        guard filledTokens.count < blankCount else { return }
        Haptics.light()
        filledTokens.append(tokens[tokenIndex])
        usedIndices.insert(tokenIndex)
        if filledTokens.count == blankCount { checkAnswer() }
    }

    private func removeFilled(at index: Int) {
        let removed = filledTokens.remove(at: index)
        if let i = tokens.firstIndex(of: removed) { usedIndices.remove(i) }
    }

    private func checkAnswer() {
        let correct = filledTokens == correctOrder
        wasCorrect = correct
        answered = true
        if !correct {
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
        }
        onAnswer(correct)
    }
}
