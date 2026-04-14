import SwiftUI

// MARK: - Achievement Gallery View
struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager()
    @State private var selectedCategory: AchievementCategory?
    @State private var showUnlockAnimation = false
    @State private var selectedAchievement: Achievement?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Stats
                achievementHeader

                // Category Filter
                categoryFilter

                // Achievement Grid
                achievementGrid

                // Recently unlocked
                if let recent = achievementManager.recentlyUnlocked {
                    recentlyUnlockedCard(recent)
                }
            }
            .padding(.bottom, 32)
        }
        .background(DS.heroBackground.ignoresSafeArea())
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
        }
    }

    // MARK: - Header
    private var achievementHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                AnimatedProgressRing(
                    progress: achievementManager.completionFraction,
                    size: 80,
                    lineWidth: 8,
                    color: DS.gold
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievements")
                        .font(DS.titleFont)
                        .foregroundColor(DS.textPrimary)

                    Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount) unlocked")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(DS.gold)
                            .font(.system(size: 14))
                        Text("\(achievementManager.totalPoints) points")
                            .font(DS.captionFont)
                            .foregroundColor(DS.gold)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, DS.padding)

            // Display badges
            if !achievementManager.displayBadges().isEmpty {
                HStack(spacing: 12) {
                    ForEach(achievementManager.displayBadges()) { badge in
                        VStack(spacing: 4) {
                            IconBadge(icon: badge.icon, color: badge.category.color, size: 44)
                            Text(badge.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(DS.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, DS.padding)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(AchievementCategory.allCases, id: \.rawValue) { category in
                    FilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, DS.padding)
        }
    }

    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        let filtered = selectedCategory != nil
            ? achievementManager.achievements(for: selectedCategory!)
            : achievementManager.achievements

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filtered) { achievement in
                AchievementCard(achievement: achievement) {
                    selectedAchievement = achievement
                }
            }
        }
        .padding(.horizontal, DS.padding)
    }

    // MARK: - Recently Unlocked
    private func recentlyUnlockedCard(_ achievement: Achievement) -> some View {
        GlassCardAccent(accent: achievement.category.color) {
            HStack(spacing: 16) {
                ZStack {
                    IconBadge(icon: achievement.icon, color: achievement.category.color, size: 56)

                    SparkleRingEffect(isActive: $showUnlockAnimation, color: achievement.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Just Unlocked!")
                        .font(DS.captionFont)
                        .foregroundColor(achievement.category.color)

                    Text(achievement.title)
                        .font(DS.headlineFont)
                        .foregroundColor(DS.textPrimary)

                    Text(achievement.description)
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, DS.padding)
        .onAppear {
            showUnlockAnimation = true
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? achievement.category.color.opacity(0.15) : DS.border.opacity(0.3))
                        .frame(width: 56, height: 56)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(achievement.isUnlocked ? achievement.category.color : DS.textTertiary)

                    if !achievement.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(DS.textTertiary)
                            .offset(x: 18, y: 18)
                    }
                }

                Text(achievement.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(achievement.isUnlocked ? DS.textPrimary : DS.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                // Progress bar
                if !achievement.isUnlocked {
                    ProgressBar(progress: achievement.progressFraction, color: achievement.category.color, height: 4)
                        .padding(.horizontal, 8)
                }

                // Rarity badge
                Text(achievement.rarity.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(achievement.rarity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(achievement.rarity.color.opacity(0.12)))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(DS.cardBg)
                    .shadow(color: DS.cardShadow, radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = DS.primary
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            onTap()
        }) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(DS.captionFont)
            }
            .foregroundColor(isSelected ? .white : DS.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? color : DS.border.opacity(0.3))
            )
        }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            // Close handle
            RoundedRectangle(cornerRadius: 3)
                .fill(DS.border)
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Icon
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: achievement.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? achievement.category.color : DS.textTertiary)
            }

            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                Text(achievement.description)
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Rarity
            HStack(spacing: 8) {
                Image(systemName: "diamond.fill")
                    .foregroundColor(achievement.rarity.color)
                Text(achievement.rarity.label)
                    .font(DS.headlineFont)
                    .foregroundColor(achievement.rarity.color)
                Text("+\(achievement.rarity.points) pts")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textTertiary)
            }

            // Progress
            if !achievement.isUnlocked {
                VStack(spacing: 8) {
                    ProgressBar(progress: achievement.progressFraction, color: achievement.category.color)
                    Text("\(achievement.progress) / \(achievement.requirement)")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }
                .padding(.horizontal, 40)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DS.success)
                    Text("Unlocked")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.success)
                    if let date = achievement.unlockedAt {
                        Text(date, style: .date)
                            .font(DS.captionFont)
                            .foregroundColor(DS.textTertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.padding)
    }
}
