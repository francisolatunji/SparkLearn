import SwiftUI

// MARK: - Troubleshoot Exercise
/// "This circuit isn't working — find the bug" (error-based learning)
struct TroubleshootView: View {
    let scenario: TroubleshootScenario
    let onComplete: (Bool) -> Void

    @State private var selectedBugIndex: Int?
    @State private var answered = false
    @State private var showExplanation = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "ladybug.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DS.error)

                Text("Find the Bug")
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)

                Text(scenario.description)
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.padding)
            }

            // Symptom card
            CardView(accent: DS.warning) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DS.warning)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Symptom")
                            .font(DS.captionFont)
                            .foregroundColor(DS.textTertiary)
                        Text(scenario.symptom)
                            .font(DS.bodyFont)
                            .foregroundColor(DS.textPrimary)
                    }
                }
            }
            .padding(.horizontal, DS.padding)

            // Possible bugs
            VStack(spacing: 10) {
                Text("What's causing the problem?")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)

                ForEach(scenario.options.indices, id: \.self) { index in
                    TroubleshootOptionRow(
                        option: scenario.options[index],
                        isSelected: selectedBugIndex == index,
                        isCorrect: answered && index == scenario.correctIndex,
                        isWrong: answered && selectedBugIndex == index && index != scenario.correctIndex
                    ) {
                        guard !answered else { return }
                        selectedBugIndex = index
                        answered = true

                        let correct = index == scenario.correctIndex
                        if correct {
                            Haptics.success()
                            SoundCue.success()
                        } else {
                            Haptics.error()
                            SoundCue.error()
                        }

                        withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                            showExplanation = true
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            onComplete(correct)
                        }
                    }
                }
            }
            .padding(.horizontal, DS.padding)

            // Explanation
            if showExplanation {
                CardView(accent: selectedBugIndex == scenario.correctIndex ? DS.success : DS.error) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: selectedBugIndex == scenario.correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(selectedBugIndex == scenario.correctIndex ? DS.success : DS.error)
                            Text(selectedBugIndex == scenario.correctIndex ? "Correct!" : "Not quite")
                                .font(DS.headlineFont)
                                .foregroundColor(DS.textPrimary)
                        }

                        Text(scenario.explanation)
                            .font(DS.bodyFont)
                            .foregroundColor(DS.textSecondary)
                    }
                }
                .padding(.horizontal, DS.padding)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
        }
    }
}

// MARK: - Troubleshoot Scenario Model
struct TroubleshootScenario {
    let description: String
    let symptom: String
    let options: [TroubleshootOption]
    let correctIndex: Int
    let explanation: String
}

struct TroubleshootOption {
    let text: String
    let icon: String
}

// MARK: - Troubleshoot Option Row
struct TroubleshootOptionRow: View {
    let option: TroubleshootOption
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 32)

                Text(option.text)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DS.success)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.error)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected && !isCorrect && !isWrong ? 0.98 : 1.0)
        .animation(DS.tapAnim, value: isSelected)
    }

    private var iconColor: Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.error }
        return DS.primary
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

// MARK: - Sample Scenarios
extension TroubleshootScenario {
    static let samples: [TroubleshootScenario] = [
        TroubleshootScenario(
            description: "You built an LED circuit with a 5V battery, but the LED isn't lighting up.",
            symptom: "LED is completely dark — no light at all",
            options: [
                TroubleshootOption(text: "The resistor value is too high", icon: "line.3.horizontal"),
                TroubleshootOption(text: "The LED is inserted backwards (wrong polarity)", icon: "arrow.left.arrow.right"),
                TroubleshootOption(text: "The battery is dead", icon: "battery.0"),
                TroubleshootOption(text: "The wire is too long", icon: "line.diagonal")
            ],
            correctIndex: 1,
            explanation: "LEDs are diodes — they only work in one direction! The longer leg (anode) goes to positive, the shorter leg (cathode) to negative. If reversed, no current flows and the LED stays dark."
        ),
        TroubleshootScenario(
            description: "Your circuit has a battery, resistor, and LED. The LED lit up briefly, then went dark and smells burned.",
            symptom: "LED flashed once then died, with a burning smell",
            options: [
                TroubleshootOption(text: "No current-limiting resistor (or value too low)", icon: "exclamationmark.triangle.fill"),
                TroubleshootOption(text: "The battery voltage is too low", icon: "battery.25"),
                TroubleshootOption(text: "The LED is the wrong color", icon: "paintbrush.fill"),
                TroubleshootOption(text: "The breadboard is broken", icon: "rectangle.split.3x3")
            ],
            correctIndex: 0,
            explanation: "Without a proper current-limiting resistor, too much current flows through the LED, burning it out. Always use R = (V_supply - V_LED) / I_LED. For a typical red LED with 5V: R = (5 - 2) / 0.02 = 150Ω minimum."
        ),
        TroubleshootScenario(
            description: "In your series circuit with two resistors, the total resistance measures correctly but the voltage across R1 reads 0V.",
            symptom: "Multimeter shows 0V across one resistor but correct total resistance",
            options: [
                TroubleshootOption(text: "R1 has short-circuited internally", icon: "bolt.fill"),
                TroubleshootOption(text: "The multimeter probes are on the same node", icon: "arrow.triangle.merge"),
                TroubleshootOption(text: "R2 is absorbing all the voltage", icon: "line.3.horizontal"),
                TroubleshootOption(text: "The battery is reversed", icon: "arrow.left.arrow.right")
            ],
            correctIndex: 1,
            explanation: "If both multimeter probes touch the same node (same wire/connection), the voltage reading will be 0V because there's no potential difference. Make sure to place probes on opposite sides of the component you're measuring."
        )
    ]
}
