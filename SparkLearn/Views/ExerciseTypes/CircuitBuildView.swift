import SwiftUI

// MARK: - Circuit Build Exercise
/// Exercise type where users drag components to build a specified circuit
struct CircuitBuildView: View {
    let targetDescription: String
    let requiredComponents: [String] // e.g. ["Battery", "Resistor", "LED"]
    let onComplete: (Bool) -> Void

    @State private var placedComponents: [String] = []
    @State private var availableComponents: [String] = []
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var draggedComponent: String?

    init(targetDescription: String, requiredComponents: [String], onComplete: @escaping (Bool) -> Void) {
        self.targetDescription = targetDescription
        self.requiredComponents = requiredComponents
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 20) {
            // Target description
            VStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DS.primary)

                Text("Build this circuit:")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)

                Text(targetDescription)
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.padding)

            // Build area
            ZStack {
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(DS.border.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                            .foregroundColor(DS.border)
                    )

                if placedComponents.isEmpty {
                    Text("Drag components here")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.textTertiary)
                } else {
                    FlowLayout(spacing: 12) {
                        ForEach(placedComponents, id: \.self) { component in
                            ComponentChip(name: component, isPlaced: true) {
                                withAnimation(DS.feedbackAnim) {
                                    placedComponents.removeAll { $0 == component }
                                    availableComponents.append(component)
                                }
                                Haptics.light()
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .frame(minHeight: 120)
            .padding(.horizontal, DS.padding)

            // Progress indicator
            HStack(spacing: 4) {
                ForEach(0..<requiredComponents.count, id: \.self) { i in
                    Circle()
                        .fill(i < placedComponents.count ? DS.success : DS.border)
                        .frame(width: 8, height: 8)
                }
            }

            // Available components tray
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Components")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
                    .padding(.horizontal, DS.padding)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableComponents, id: \.self) { component in
                            ComponentChip(name: component, isPlaced: false) {
                                withAnimation(DS.feedbackAnim) {
                                    placedComponents.append(component)
                                    availableComponents.removeAll { $0 == component }
                                }
                                Haptics.light()
                            }
                        }
                    }
                    .padding(.horizontal, DS.padding)
                }
            }

            Spacer()

            // Check button
            PrimaryButton("Check Circuit", icon: "bolt.fill") {
                checkAnswer()
            }
            .padding(.horizontal, DS.padding)
            .disabled(placedComponents.count < requiredComponents.count)
            .opacity(placedComponents.count < requiredComponents.count ? 0.5 : 1.0)
        }
        .onAppear {
            // Shuffle available components with distractors
            var all = requiredComponents
            let distractors = ["Transistor", "Relay", "Crystal", "Op-Amp"]
            all += distractors.shuffled().prefix(2)
            availableComponents = all.shuffled()
        }
    }

    private func checkAnswer() {
        let sortedPlaced = placedComponents.sorted()
        let sortedRequired = requiredComponents.sorted()
        isCorrect = sortedPlaced == sortedRequired
        showResult = true

        if isCorrect {
            Haptics.success()
            SoundCue.success()
        } else {
            Haptics.error()
            SoundCue.error()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete(isCorrect)
        }
    }
}

// MARK: - Component Chip
struct ComponentChip: View {
    let name: String
    let isPlaced: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconForComponent(name))
                    .font(.system(size: 14, weight: .semibold))
                Text(name)
                    .font(DS.captionFont)
                if isPlaced {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundColor(isPlaced ? .white : DS.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isPlaced ? DS.primary : DS.cardBg)
            )
            .overlay(
                Capsule()
                    .stroke(isPlaced ? Color.clear : DS.border, lineWidth: 1)
            )
            .shadow(color: DS.cardShadow, radius: 4, y: 2)
        }
    }

    private func iconForComponent(_ name: String) -> String {
        switch name.lowercased() {
        case "battery": return "battery.100"
        case "resistor": return "line.3.horizontal"
        case "led": return "lightbulb.fill"
        case "capacitor": return "rectangle.split.2x1"
        case "wire": return "line.diagonal"
        case "switch": return "switch.2"
        case "buzzer": return "speaker.wave.2.fill"
        case "motor": return "gear"
        case "diode": return "arrow.right.circle"
        case "fuse": return "bolt.slash.fill"
        default: return "cpu"
        }
    }
}
