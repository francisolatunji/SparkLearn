import SwiftUI

// MARK: - Daily Quest View
struct DailyQuestView: View {
    @StateObject private var questManager = QuestManager()
    @State private var showTreasureChest = false
    @State private var treasureResult: (TreasureRarity, TreasureReward)?
    @State private var showConfetti = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Daily Quests")
                        .font(DS.titleFont)
                        .foregroundColor(DS.textPrimary)

                    Text("Complete all quests to unlock a Treasure Chest!")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.textSecondary)
                }
                .padding(.top, 16)

                // Quest Cards
                ForEach(questManager.dailyQuests) { quest in
                    QuestCard(quest: quest)
                }

                // Treasure Chest
                if questManager.allQuestsCompleted {
                    treasureChestCard
                }

                // Refresh timer
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(DS.textTertiary)
                    Text("New quests at midnight")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textTertiary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, DS.padding)
            .padding(.bottom, 32)
        }
        .background(DS.heroBackground.ignoresSafeArea())
        .overlay {
            if showConfetti {
                ConfettiBurst(isActive: $showConfetti)
            }
        }
        .sheet(isPresented: $showTreasureChest) {
            if let (rarity, reward) = treasureResult {
                TreasureChestRevealView(rarity: rarity, reward: reward)
            }
        }
    }

    private var treasureChestCard: some View {
        CardView(accent: DS.gold) {
            VStack(spacing: 16) {
                ZStack {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: DS.gold.opacity(0.4), radius: 12)
                }
                .pulseGlow(color: DS.gold)

                Text("Treasure Chest Ready!")
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)

                Text("You completed all daily quests")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)

                PrimaryButton("Open Chest", icon: "lock.open.fill") {
                    let result = questManager.openTreasureChest()
                    treasureResult = result
                    showTreasureChest = true
                    showConfetti = true
                    Haptics.success()
                    SoundCue.celebration()
                }
            }
        }
    }
}

// MARK: - Quest Card
struct QuestCard: View {
    let quest: DailyQuest

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(quest.isCompleted ? DS.success.opacity(0.15) : DS.primary.opacity(0.1))
                    .frame(width: 48, height: 48)

                if quest.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DS.success)
                } else {
                    Image(systemName: quest.type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DS.primary)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(quest.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(quest.isCompleted ? DS.textTertiary : DS.textPrimary)
                    .strikethrough(quest.isCompleted)

                ProgressBar(
                    progress: quest.progressFraction,
                    color: quest.isCompleted ? DS.success : DS.primary,
                    height: 6
                )

                Text("\(quest.progress)/\(quest.requirement)")
                    .font(DS.smallFont)
                    .foregroundColor(DS.textTertiary)
            }

            Spacer()

            // Reward
            VStack(spacing: 2) {
                Text("+\(quest.xpReward)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(quest.isCompleted ? DS.success : DS.accent)
                Text("XP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(DS.textTertiary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 8, y: 4)
        )
        .opacity(quest.isCompleted ? 0.7 : 1.0)
    }
}

// MARK: - Treasure Chest Reveal View
struct TreasureChestRevealView: View {
    let rarity: TreasureRarity
    let reward: TreasureReward
    @Environment(\.dismiss) var dismiss
    @State private var revealed = false
    @State private var showSparkles = false

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Rarity label
                Text(rarity.rawValue.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundColor(rarity.color)
                    .opacity(revealed ? 1 : 0)

                // Reward icon
                ZStack {
                    // Glow
                    Circle()
                        .fill(rarity.color.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)

                    if revealed {
                        SparkleRingEffect(isActive: $showSparkles, color: rarity.color)
                    }

                    Image(systemName: reward.icon)
                        .font(.system(size: revealed ? 72 : 56, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [rarity.color, rarity.color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: rarity.color.opacity(0.5), radius: 20)
                        .scaleEffect(revealed ? 1.0 : 0.5)
                        .opacity(revealed ? 1 : 0)
                }

                // Reward description
                VStack(spacing: 8) {
                    Text(reward.description)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Added to your inventory")
                        .font(DS.bodyFont)
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(revealed ? 1 : 0)

                Spacer()

                // Chest animation
                if !revealed {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: DS.gold.opacity(0.5), radius: 20)
                            .floating(amplitude: 6, duration: 1.5)

                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                revealed = true
                                showSparkles = true
                            }
                            Haptics.success()
                            SoundCue.celebration()
                        } label: {
                            Text("TAP TO OPEN")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .tracking(3)
                                .foregroundColor(DS.gold)
                                .shimmer()
                        }
                    }
                }

                if revealed {
                    PrimaryButton("Collect") {
                        dismiss()
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
    }
}
