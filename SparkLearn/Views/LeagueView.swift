import SwiftUI

// MARK: - League View
struct LeagueView: View {
    @EnvironmentObject var progress: ProgressManager
    @StateObject private var leagueManager = LeagueManager()
    @State private var showTierInfo = false
    @State private var selectedTab = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // League Header
                leagueHeader

                // Time remaining
                weekTimer

                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Leaderboard").tag(0)
                    Text("All Tiers").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DS.padding)

                if selectedTab == 0 {
                    leaderboardList
                } else {
                    tiersList
                }
            }
            .padding(.bottom, 32)
        }
        .background(DS.heroBackground.ignoresSafeArea())
    }

    // MARK: - League Header
    private var leagueHeader: some View {
        VStack(spacing: 12) {
            // Tier icon with glow
            ZStack {
                Circle()
                    .fill(leagueManager.currentTier.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: leagueManager.currentTier.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [leagueManager.currentTier.color, leagueManager.currentTier.color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: leagueManager.currentTier.color.opacity(0.4), radius: 12)
            }
            .pulseGlow(color: leagueManager.currentTier.color)

            Text(leagueManager.currentTier.title)
                .font(DS.titleFont)
                .foregroundColor(DS.textPrimary)

            Text("Rank #\(leagueManager.currentRank) of \(leagueManager.leagueSize)")
                .font(DS.bodyFont)
                .foregroundColor(DS.textSecondary)

            // Promotion/demotion zone indicator
            if leagueManager.promotionZone {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(DS.success)
                    Text("Promotion Zone!")
                        .font(DS.captionFont)
                        .foregroundColor(DS.success)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(DS.success.opacity(0.12)))
            } else if leagueManager.demotionZone {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(DS.error)
                    Text("Demotion Zone")
                        .font(DS.captionFont)
                        .foregroundColor(DS.error)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(DS.error.opacity(0.12)))
            }

            // Weekly XP
            HStack(spacing: 16) {
                StatChip(icon: "bolt.fill", value: "\(leagueManager.weeklyXP)", label: "Weekly XP", color: DS.accent)

                if leagueManager.hasShield {
                    StatChip(icon: "shield.fill", value: "Active", label: "Shield", color: DS.success)
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Week Timer
    private var weekTimer: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(DS.textTertiary)
            Text("Week resets Monday")
                .font(DS.captionFont)
                .foregroundColor(DS.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(DS.border.opacity(0.5)))
    }

    // MARK: - Leaderboard
    private var leaderboardList: some View {
        VStack(spacing: 2) {
            ForEach(leagueManager.participants) { participant in
                LeaderboardRow(
                    participant: participant,
                    isPromotion: (participant.rank ?? 0) <= leagueManager.promotionCount,
                    isDemotion: (participant.rank ?? 0) > leagueManager.leagueSize - leagueManager.demotionCount
                )
            }
        }
        .padding(.horizontal, DS.padding)
    }

    // MARK: - Tiers List
    private var tiersList: some View {
        VStack(spacing: 12) {
            ForEach(LeagueTier.allCases, id: \.rawValue) { tier in
                HStack(spacing: 16) {
                    Image(systemName: tier.icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(tier.color)
                        .frame(width: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.title)
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)
                        Text(tier == leagueManager.currentTier ? "Current" : "")
                            .font(DS.captionFont)
                            .foregroundColor(DS.success)
                    }

                    Spacer()

                    if tier == leagueManager.currentTier {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DS.success)
                    } else if tier < leagueManager.currentTier {
                        Image(systemName: "checkmark")
                            .foregroundColor(DS.textTertiary)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(DS.textTertiary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(tier == leagueManager.currentTier ? tier.color.opacity(0.1) : DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(tier == leagueManager.currentTier ? tier.color.opacity(0.3) : DS.border, lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal, DS.padding)
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let participant: LeagueParticipant
    let isPromotion: Bool
    let isDemotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(participant.rank ?? 0)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 30)

            // Avatar
            Text(participant.avatarEmoji)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(participant.isCurrentUser ? DS.primary.opacity(0.15) : DS.border.opacity(0.3))
                )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.system(size: 15, weight: participant.isCurrentUser ? .bold : .medium, design: .rounded))
                    .foregroundColor(participant.isCurrentUser ? DS.primary : DS.textPrimary)
            }

            Spacer()

            // XP
            Text("\(participant.weeklyXP) XP")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(DS.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(participant.isCurrentUser ? DS.primary.opacity(0.06) : Color.clear)
        )
        .overlay(alignment: .leading) {
            if isPromotion {
                Rectangle()
                    .fill(DS.success)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            } else if isDemotion {
                Rectangle()
                    .fill(DS.error)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }

    private var rankColor: Color {
        switch participant.rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return DS.textSecondary
        }
    }
}
