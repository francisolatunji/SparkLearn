import SwiftUI

struct NumericInputView: View {
    let correctValue: Double
    let unit: String
    let tolerance: Double
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var inputText = ""
    @State private var shake = false
    @State private var checking = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Input
            HStack(spacing: 12) {
                TextField("?", text: $inputText)
                    .font(.system(size: 32, weight: .bold, design: .monospaced).monospacedDigit())
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .foregroundColor(DS.textPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .fill(Color(hex: "F0F1F3"))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .stroke(
                                        answered
                                        ? (wasCorrect ? DS.success : DS.error)
                                        : (focused ? DS.primary : DS.border),
                                        lineWidth: 2
                                    )
                            )
                            // Inner shadow for calculator look
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                    .blur(radius: 2)
                                    .offset(y: 1)
                                    .mask(RoundedRectangle(cornerRadius: DS.cornerRadius).fill())
                            )
                            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    )

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(DS.primary)
                        )
                }
            }

            if answered && !wasCorrect {
                HStack(spacing: 6) {
                    Text("Answer:")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                    Text(formatValue(correctValue) + " " + unit)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(DS.success)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if !answered {
                PrimaryButton("Check", icon: "checkmark") {
                    checkAnswer()
                }
                .overlay {
                    if checking {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .opacity(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || checking)
            }
        }
        .offset(x: shake ? -8 : 0)
        .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
        .onAppear { focused = true }
    }

    private func checkAnswer() {
        checking = true
        guard let val = Double(inputText.trimmingCharacters(in: .whitespaces)) else {
            shake = true
            checking = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
            return
        }
        let correct = abs(val - correctValue) <= tolerance + 0.001
        wasCorrect = correct
        answered = true
        focused = false
        checking = false
        if !correct {
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
        }
        onAnswer(correct)
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}
