import SwiftUI

struct DuoFeedbackBanner: View {
    let isCorrect: Bool
    let title: String
    let explanation: String
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 36, height: 36)
                        Image(systemName: isCorrect ? "checkmark" : "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: appeared)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(explanation)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                // Continue / Got It button
                Button(action: {
                    Haptics.light()
                    onContinue()
                }) {
                    Text(isCorrect ? "CONTINUE" : "GOT IT")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(isCorrect ? DS.duoGreen : DS.duoRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: DS.buttonCorner)
                                .fill(Color.white)
                        )
                }
            }
            .padding(20)
            .padding(.bottom, 16)
        }
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(isCorrect ? DS.duoGreen : DS.duoRed)
            .ignoresSafeArea(edges: .bottom)
        )
        .onAppear {
            withAnimation(DS.duoSlide) { appeared = true }
        }
    }
}
