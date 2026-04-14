import SwiftUI

struct SafetyScenarioView: View {
    let isSafe: Bool
    let scenarioDescription: String
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var shake = false
    @State private var selectedChoice: Bool?
    @State private var warningPulse = false

    var body: some View {
        VStack(spacing: 20) {
            // Scenario card
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(DS.warning)
                    .scaleEffect(warningPulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: warningPulse)
                    .onAppear { warningPulse = true }

                Text(scenarioDescription)
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(24)
            .padding(.leading, 6) // extra space for caution stripe
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadius)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .stroke(DS.warning.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            )
            // Yellow/black caution stripe on left edge
            .overlay(alignment: .leading) {
                Canvas { context, size in
                    let stripeWidth: CGFloat = 8
                    let stripeSpacing: CGFloat = 6
                    for y in stride(from: -size.height, through: size.height * 2, by: stripeSpacing * 2) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: stripeWidth, y: y + stripeSpacing))
                        path.addLine(to: CGPoint(x: stripeWidth, y: y + stripeSpacing * 2))
                        path.addLine(to: CGPoint(x: 0, y: y + stripeSpacing))
                        path.closeSubpath()
                        context.fill(path, with: .color(.black))
                    }
                    for y in stride(from: -size.height + stripeSpacing, through: size.height * 2, by: stripeSpacing * 2) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: stripeWidth, y: y + stripeSpacing))
                        path.addLine(to: CGPoint(x: stripeWidth, y: y + stripeSpacing * 2))
                        path.addLine(to: CGPoint(x: 0, y: y + stripeSpacing))
                        path.closeSubpath()
                        context.fill(path, with: .color(DS.warning))
                    }
                }
                .frame(width: 6)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: DS.cornerRadius,
                        bottomLeadingRadius: DS.cornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )
                .allowsHitTesting(false)
            }

            // Safe / Unsafe buttons
            HStack(spacing: 14) {
                Button(action: { answer(true) }) {
                    VStack(spacing: 8) {
                        Image(systemName: answered && isSafe ? "checkmark.shield.fill" : "checkmark.shield")
                            .font(.system(size: 28, weight: .medium))
                        Text("Safe")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(safeButtonFg(true))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .fill(safeButtonBg(true))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .stroke(safeButtonBorder(true), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                    .scaleEffect(selectedChoice == true && !answered ? 0.97 : 1)
                }
                .disabled(answered)

                Button(action: { answer(false) }) {
                    VStack(spacing: 8) {
                        Image(systemName: answered && !isSafe ? "xmark.shield.fill" : "xmark.shield")
                            .font(.system(size: 28, weight: .medium))
                        Text("Unsafe")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(safeButtonFg(false))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .fill(safeButtonBg(false))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .stroke(safeButtonBorder(false), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                    )
                    .scaleEffect(selectedChoice == false && !answered ? 0.97 : 1)
                }
                .disabled(answered)
            }
        }
        .offset(x: shake ? -8 : 0)
        .animation(DS.tapAnim, value: selectedChoice)
        .animation(DS.feedbackAnim, value: answered)
        .animation(shake ? .default.repeatCount(3, autoreverses: true).speed(6) : .default, value: shake)
    }

    private func answer(_ userSaidSafe: Bool) {
        Haptics.light()
        selectedChoice = userSaidSafe
        let correct = userSaidSafe == isSafe
        wasCorrect = correct
        answered = true
        if !correct {
            shake = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
        }
        onAnswer(correct)
    }

    private func safeButtonFg(_ forSafe: Bool) -> Color {
        guard answered else { return forSafe ? DS.success : DS.error }
        if forSafe == isSafe { return .white }
        return DS.textTertiary
    }

    private func safeButtonBg(_ forSafe: Bool) -> Color {
        guard answered else { return DS.cardBg }
        if forSafe == isSafe { return forSafe ? DS.success : DS.error }
        return DS.cardBg
    }

    private func safeButtonBorder(_ forSafe: Bool) -> Color {
        guard answered else { return forSafe ? DS.success.opacity(0.3) : DS.error.opacity(0.3) }
        if forSafe == isSafe { return .clear }
        return DS.border
    }
}
