import SwiftUI

struct FlashcardView: View {
    let front: String
    let back: String
    let frontIcon: String?
    @Binding var answered: Bool
    @Binding var wasCorrect: Bool
    let onAnswer: (Bool) -> Void

    @State private var flipped = false
    @State private var showRating = false
    @State private var cardPressed = false

    var body: some View {
        VStack(spacing: 24) {
            // Card
            ZStack {
                // Visible card edge during flip
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(DS.primary)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .opacity(flipped ? 0 : 0) // Always behind, visible as edge artifact
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .stroke(DS.primary, lineWidth: 4)
                            .opacity(0.3)
                    )

                // Back (answer)
                cardFace(
                    content: back,
                    icon: "checkmark.circle",
                    color: DS.success,
                    isBack: true
                )
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)

                // Front (question)
                cardFace(
                    content: front,
                    icon: frontIcon ?? "questionmark.circle",
                    color: DS.primary,
                    isBack: false
                )
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 0 : 1)
            }
            .frame(height: 220)
            .onTapGesture {
                guard !flipped else { return }
                Haptics.light()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    flipped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showRating = true
                    }
                }
            }
            .scaleEffect(cardPressed ? 0.98 : 1)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !flipped else { return }
                        cardPressed = true
                    }
                    .onEnded { _ in
                        cardPressed = false
                    }
            )

            if !flipped {
                Text("Tap the card to reveal the answer")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textTertiary)
            }

            // Self-rating buttons
            if showRating && !answered {
                VStack(spacing: 12) {
                    Text("Did you know it?")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)

                    HStack(spacing: 14) {
                        ratingButton(
                            title: "Nope",
                            icon: "xmark",
                            color: DS.error,
                            correct: false
                        )

                        ratingButton(
                            title: "Kind of",
                            icon: "minus",
                            color: DS.warning,
                            correct: false
                        )

                        ratingButton(
                            title: "Got it!",
                            icon: "checkmark",
                            color: DS.success,
                            correct: true
                        )
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DS.tapAnim, value: cardPressed)
        .animation(DS.feedbackAnim, value: flipped)
    }

    private func cardFace(content: String, icon: String, color: Color, isBack: Bool) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(color)

            Text(content)
                .font(.system(size: isBack ? 22 : 18, weight: isBack ? .bold : .semibold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            if !isBack {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 11))
                    Text("Tap to flip")
                        .font(DS.smallFont)
                }
                .foregroundColor(DS.textTertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)

                // Subtle diagonal pattern on front face only
                if !isBack {
                    Canvas { context, size in
                        let spacing: CGFloat = 18
                        for x in stride(from: -size.height, through: size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                            context.stroke(path, with: .color(color.opacity(0.04)), lineWidth: 1)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
                    .allowsHitTesting(false)
                }
            }
        )
    }

    private func ratingButton(title: String, icon: String, color: Color, correct: Bool) -> some View {
        Button(action: {
            Haptics.medium()
            wasCorrect = correct
            answered = true
            onAnswer(correct)
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadius)
                    .fill(color.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}
