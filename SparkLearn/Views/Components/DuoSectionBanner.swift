import SwiftUI

struct DuoSectionBanner: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let lessonCount: Int
    let completedCount: Int

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // Progress pill
            Text("\(completedCount)/\(lessonCount)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(color)
        )
    }
}
