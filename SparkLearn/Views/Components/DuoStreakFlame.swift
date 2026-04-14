import SwiftUI

struct DuoStreakFlame: View {
    let streakCount: Int
    var size: CGFloat = 28

    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(DS.duoOrange)
                .scaleEffect(animating ? 1.08 : 1.0)
                .rotationEffect(.degrees(animating ? 2 : -2))

            if streakCount > 0 {
                Text("\(streakCount)")
                    .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(DS.duoOrange)
                    .contentTransition(.numericText())
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}
