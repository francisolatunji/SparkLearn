import Foundation
import SwiftUI

// MARK: - League Tiers
enum LeagueTier: Int, CaseIterable, Codable, Comparable {
    case bronze = 0
    case silver = 1
    case gold = 2
    case platinum = 3
    case diamond = 4
    case master = 5
    case grandmaster = 6
    case legend = 7
    case champion = 8
    case sparkLord = 9

    static func < (lhs: LeagueTier, rhs: LeagueTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        case .legend: return "Legend"
        case .champion: return "Champion"
        case .sparkLord: return "Spark Lord"
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "shield.fill"
        case .silver: return "shield.fill"
        case .gold: return "shield.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        case .master: return "star.circle.fill"
        case .grandmaster: return "star.circle.fill"
        case .legend: return "bolt.shield.fill"
        case .champion: return "trophy.fill"
        case .sparkLord: return "bolt.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .platinum: return Color(hex: "00CED1")
        case .diamond: return Color(hex: "B9F2FF")
        case .master: return Color(hex: "FF6B6B")
        case .grandmaster: return Color(hex: "C084FC")
        case .legend: return Color(hex: "F472B6")
        case .champion: return Color(hex: "FBBF24")
        case .sparkLord: return Color(hex: "3B82F6")
        }
    }

    var nextTier: LeagueTier? {
        LeagueTier(rawValue: rawValue + 1)
    }

    var previousTier: LeagueTier? {
        rawValue > 0 ? LeagueTier(rawValue: rawValue - 1) : nil
    }
}

// MARK: - League Participant
struct LeagueParticipant: Identifiable, Codable {
    let id: String
    var displayName: String
    var weeklyXP: Int
    var avatarEmoji: String
    var isCurrentUser: Bool

    var rank: Int? // set when sorted

    init(id: String, displayName: String, weeklyXP: Int, avatarEmoji: String = "⚡", isCurrentUser: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.weeklyXP = weeklyXP
        self.avatarEmoji = avatarEmoji
        self.isCurrentUser = isCurrentUser
    }
}

// MARK: - League Manager
@MainActor
class LeagueManager: ObservableObject {
    @Published var currentTier: LeagueTier = .bronze
    @Published var weeklyXP: Int = 0
    @Published var participants: [LeagueParticipant] = []
    @Published var currentRank: Int = 1
    @Published var weekStartDate: Date = Date()
    @Published var promotionZone: Bool = false
    @Published var demotionZone: Bool = false
    @Published var hasShield: Bool = false

    private let tierKey = "league_tier"
    private let weeklyXPKey = "league_weekly_xp"
    private let weekStartKey = "league_week_start"
    private let shieldKey = "league_shield"

    let promotionCount = 10
    let demotionCount = 5
    let leagueSize = 30

    init() {
        load()
        checkWeekReset()
        generateSimulatedLeague()
    }

    // MARK: - Core

    func addWeeklyXP(_ xp: Int) {
        weeklyXP += xp
        updateRank()
        save()
    }

    func checkWeekReset() {
        let calendar = Calendar.current
        let now = Date()

        // Check if we're in a new week (Monday-based)
        if let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start {
            if weekStart > weekStartDate {
                processWeekEnd()
                weekStartDate = weekStart
                weeklyXP = 0
                generateSimulatedLeague()
                save()
            }
        }
    }

    private func processWeekEnd() {
        let rank = currentRank

        if rank <= promotionCount {
            // Promotion
            if let next = currentTier.nextTier {
                currentTier = next
                promotionZone = false
            }
        } else if rank > leagueSize - demotionCount {
            // Demotion (unless shielded)
            if hasShield {
                hasShield = false
            } else if let prev = currentTier.previousTier {
                currentTier = prev
            }
            demotionZone = false
        }

        save()
    }

    func activateShield() {
        hasShield = true
        save()
    }

    // MARK: - Simulated League

    func generateSimulatedLeague() {
        let names = [
            "Alex", "Jordan", "Casey", "Morgan", "Taylor", "Riley",
            "Quinn", "Avery", "Parker", "Sage", "Drew", "Cameron",
            "Reese", "Blake", "Charlie", "Dana", "Emery", "Frankie",
            "Hayden", "Indie", "Jules", "Kai", "Lane", "Micah",
            "Noel", "Oakley", "Peyton", "River", "Shay"
        ]

        let emojis = ["⚡", "🔧", "💡", "🔋", "🎯", "🚀", "🌟", "🔬", "🎓", "💪"]

        var simulated: [LeagueParticipant] = names.prefix(leagueSize - 1).enumerated().map { i, name in
            let xpRange: ClosedRange<Int>
            switch currentTier {
            case .bronze: xpRange = 20...300
            case .silver: xpRange = 50...500
            case .gold: xpRange = 100...700
            case .platinum: xpRange = 200...1000
            default: xpRange = 300...1500
            }
            return LeagueParticipant(
                id: "sim_\(i)",
                displayName: name,
                weeklyXP: Int.random(in: xpRange),
                avatarEmoji: emojis.randomElement() ?? "⚡"
            )
        }

        // Add current user
        simulated.append(LeagueParticipant(
            id: "current_user",
            displayName: "You",
            weeklyXP: weeklyXP,
            avatarEmoji: "⚡",
            isCurrentUser: true
        ))

        // Sort by XP descending
        simulated.sort { $0.weeklyXP > $1.weeklyXP }

        // Assign ranks
        for i in simulated.indices {
            simulated[i].rank = i + 1
        }

        participants = simulated
        updateRank()
    }

    private func updateRank() {
        // Update current user's XP in participants
        if let index = participants.firstIndex(where: { $0.isCurrentUser }) {
            participants[index].weeklyXP = weeklyXP
        }

        // Re-sort
        participants.sort { $0.weeklyXP > $1.weeklyXP }
        for i in participants.indices {
            participants[i].rank = i + 1
        }

        if let userRank = participants.first(where: { $0.isCurrentUser })?.rank {
            currentRank = userRank
            promotionZone = userRank <= promotionCount
            demotionZone = userRank > leagueSize - demotionCount
        }
    }

    // MARK: - Persistence

    private func load() {
        currentTier = LeagueTier(rawValue: UserDefaults.standard.integer(forKey: tierKey)) ?? .bronze
        weeklyXP = UserDefaults.standard.integer(forKey: weeklyXPKey)
        weekStartDate = (UserDefaults.standard.object(forKey: weekStartKey) as? Date) ?? Date()
        hasShield = UserDefaults.standard.bool(forKey: shieldKey)
    }

    private func save() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: tierKey)
        UserDefaults.standard.set(weeklyXP, forKey: weeklyXPKey)
        UserDefaults.standard.set(weekStartDate, forKey: weekStartKey)
        UserDefaults.standard.set(hasShield, forKey: shieldKey)
    }
}

// MARK: - Daily Quest System

enum QuestType: String, Codable, CaseIterable {
    case completeLessons = "Complete Lessons"
    case achieveCombo = "Achieve Combo"
    case practiceReview = "Practice Review"
    case tryNewType = "Try New Exercise Type"
    case spendTime = "Spend Time Learning"
    case perfectLesson = "Perfect Lesson"
    case viewModels = "View 3D Models"
    case buildCircuit = "Build a Circuit"

    var icon: String {
        switch self {
        case .completeLessons: return "book.fill"
        case .achieveCombo: return "flame.fill"
        case .practiceReview: return "arrow.clockwise"
        case .tryNewType: return "square.grid.3x3.fill"
        case .spendTime: return "clock.fill"
        case .perfectLesson: return "star.fill"
        case .viewModels: return "cube.fill"
        case .buildCircuit: return "hammer.fill"
        }
    }

    var xpReward: Int {
        switch self {
        case .completeLessons: return 30
        case .achieveCombo: return 20
        case .practiceReview: return 25
        case .tryNewType: return 15
        case .spendTime: return 20
        case .perfectLesson: return 40
        case .viewModels: return 15
        case .buildCircuit: return 35
        }
    }
}

struct DailyQuest: Identifiable, Codable {
    let id: String
    let type: QuestType
    let title: String
    let requirement: Int
    var progress: Int
    var isCompleted: Bool
    let xpReward: Int

    var progressFraction: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
}

// MARK: - Treasure Chest
enum TreasureRarity: String, Codable {
    case common, rare, epic, legendary

    var probability: Double {
        switch self {
        case .common: return 0.60
        case .rare: return 0.25
        case .epic: return 0.12
        case .legendary: return 0.03
        }
    }

    var color: Color {
        switch self {
        case .common: return Color(hex: "94A3B8")
        case .rare: return Color(hex: "3B82F6")
        case .epic: return Color(hex: "8B5CF6")
        case .legendary: return Color(hex: "F59E0B")
        }
    }
}

enum TreasureReward: Codable {
    case bonusXP(Int)
    case gems(Int)
    case streakFreeze
    case xpBoost
    case cosmeticItem(String)

    var description: String {
        switch self {
        case .bonusXP(let amount): return "+\(amount) XP"
        case .gems(let amount): return "+\(amount) Gems"
        case .streakFreeze: return "Streak Freeze"
        case .xpBoost: return "2x XP Boost (1hr)"
        case .cosmeticItem(let name): return name
        }
    }

    var icon: String {
        switch self {
        case .bonusXP: return "sparkles"
        case .gems: return "diamond.fill"
        case .streakFreeze: return "snowflake"
        case .xpBoost: return "bolt.fill"
        case .cosmeticItem: return "tshirt.fill"
        }
    }
}

// MARK: - Quest Manager
@MainActor
class QuestManager: ObservableObject {
    @Published var dailyQuests: [DailyQuest] = []
    @Published var allQuestsCompleted: Bool = false
    @Published var treasureChestAvailable: Bool = false
    @Published var lastQuestRefresh: Date?

    private let questsKey = "daily_quests"
    private let refreshKey = "daily_quests_refresh"

    init() {
        load()
        checkRefresh()
    }

    func checkRefresh() {
        let calendar = Calendar.current
        if let lastRefresh = lastQuestRefresh, calendar.isDateInToday(lastRefresh) {
            return
        }
        generateDailyQuests()
    }

    func generateDailyQuests() {
        let types = QuestType.allCases.shuffled().prefix(3)

        dailyQuests = types.enumerated().map { index, type in
            let requirement: Int
            let title: String

            switch type {
            case .completeLessons:
                requirement = Int.random(in: 2...4)
                title = "Complete \(requirement) lessons"
            case .achieveCombo:
                requirement = Int.random(in: 3...7)
                title = "Get a \(requirement)x combo"
            case .practiceReview:
                requirement = 1
                title = "Complete a review session"
            case .tryNewType:
                requirement = 1
                title = "Try a new exercise type"
            case .spendTime:
                requirement = Int.random(in: 5...15)
                title = "Spend \(requirement) minutes learning"
            case .perfectLesson:
                requirement = 1
                title = "Get a perfect lesson score"
            case .viewModels:
                requirement = Int.random(in: 2...5)
                title = "View \(requirement) 3D models"
            case .buildCircuit:
                requirement = 1
                title = "Build a circuit"
            }

            return DailyQuest(
                id: "quest_\(index)_\(Date().timeIntervalSince1970)",
                type: type,
                title: title,
                requirement: requirement,
                progress: 0,
                isCompleted: false,
                xpReward: type.xpReward
            )
        }

        lastQuestRefresh = Date()
        allQuestsCompleted = false
        treasureChestAvailable = false
        save()
    }

    func updateProgress(for type: QuestType, increment: Int = 1) {
        for i in dailyQuests.indices {
            if dailyQuests[i].type == type && !dailyQuests[i].isCompleted {
                dailyQuests[i].progress += increment
                if dailyQuests[i].progress >= dailyQuests[i].requirement {
                    dailyQuests[i].isCompleted = true
                }
            }
        }

        allQuestsCompleted = dailyQuests.allSatisfy(\.isCompleted)
        if allQuestsCompleted && !treasureChestAvailable {
            treasureChestAvailable = true
        }

        save()
    }

    func openTreasureChest() -> (TreasureRarity, TreasureReward) {
        treasureChestAvailable = false
        save()

        let roll = Double.random(in: 0...1)
        let rarity: TreasureRarity
        if roll < 0.03 { rarity = .legendary }
        else if roll < 0.15 { rarity = .epic }
        else if roll < 0.40 { rarity = .rare }
        else { rarity = .common }

        let reward: TreasureReward
        switch rarity {
        case .common:
            reward = .bonusXP(Int.random(in: 50...100))
        case .rare:
            reward = [.gems(Int.random(in: 10...25)), .bonusXP(Int.random(in: 100...150))].randomElement()!
        case .epic:
            reward = [.streakFreeze, .gems(Int.random(in: 25...50)), .bonusXP(Int.random(in: 150...200))].randomElement()!
        case .legendary:
            reward = [.xpBoost, .gems(Int.random(in: 50...100)), .cosmeticItem("Golden Sparky")].randomElement()!
        }

        return (rarity, reward)
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(dailyQuests) {
            UserDefaults.standard.set(data, forKey: questsKey)
        }
        UserDefaults.standard.set(lastQuestRefresh, forKey: refreshKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: questsKey),
           let saved = try? JSONDecoder().decode([DailyQuest].self, from: data) {
            dailyQuests = saved
            allQuestsCompleted = saved.allSatisfy(\.isCompleted)
        }
        lastQuestRefresh = UserDefaults.standard.object(forKey: refreshKey) as? Date
    }
}
