import SwiftUI

struct DuoStatsBar: View {
    let streak: Int
    let xp: Int
    let hearts: Int
    let dailyXP: Int
    let dailyGoal: Int

    var body: some View {
        HStack(spacing: 0) {
            // Streak
            DuoStreakFlame(streakCount: streak, size: 22)
                .frame(maxWidth: .infinity)

            dividerLine

            // Daily XP progress
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DS.duoYellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dailyXP)/\(dailyGoal)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DS.duoText)
                        .contentTransition(.numericText())

                    GeometryReader { geo in
                        Capsule()
                            .fill(DS.duoBorder)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(DS.duoYellow)
                                    .frame(width: max(0, geo.size.width * min(1, Double(dailyXP) / Double(max(1, dailyGoal)))))
                            }
                    }
                    .frame(height: 6)
                }
                .frame(width: 60)
            }
            .frame(maxWidth: .infinity)

            dividerLine

            // Hearts
            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DS.duoRed)
                Text("\(hearts)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DS.duoRed)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(DS.duoBorder)
            .frame(width: 1, height: 28)
    }
}
