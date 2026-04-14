import Foundation
import SwiftUI

// MARK: - Achievement System

enum AchievementCategory: String, CaseIterable, Codable {
    case streak = "Streak"
    case mastery = "Mastery"
    case speed = "Speed"
    case explorer = "Explorer"
    case social = "Social"
    case builder = "Builder"
    case knowledge = "Knowledge"

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .mastery: return "star.fill"
        case .speed: return "bolt.fill"
        case .explorer: return "safari.fill"
        case .social: return "person.2.fill"
        case .builder: return "hammer.fill"
        case .knowledge: return "brain.head.profile.fill"
        }
    }

    var color: Color {
        switch self {
        case .streak: return Color(hex: "F97316")
        case .mastery: return Color(hex: "EAB308")
        case .speed: return Color(hex: "3B82F6")
        case .explorer: return Color(hex: "8B5CF6")
        case .social: return Color(hex: "EC4899")
        case .builder: return Color(hex: "14B8A6")
        case .knowledge: return Color(hex: "6366F1")
        }
    }
}

enum AchievementRarity: String, Codable {
    case common, rare, epic, legendary

    var label: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
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

    var points: Int {
        switch self {
        case .common: return 10
        case .rare: return 25
        case .epic: return 50
        case .legendary: return 100
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let requirement: Int // threshold to unlock
    var progress: Int
    var isUnlocked: Bool
    var unlockedAt: Date?

    var progressFraction: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }
}

// MARK: - Achievement Definitions
enum AchievementStore {
    static let all: [Achievement] = streak + mastery + speed + explorer + social + builder + knowledge

    // MARK: Streak Achievements
    static let streak: [Achievement] = [
        Achievement(id: "streak_3", title: "Getting Started", description: "Maintain a 3-day streak", icon: "flame.fill", category: .streak, rarity: .common, requirement: 3, progress: 0, isUnlocked: false),
        Achievement(id: "streak_7", title: "Week Warrior", description: "Maintain a 7-day streak", icon: "flame.fill", category: .streak, rarity: .common, requirement: 7, progress: 0, isUnlocked: false),
        Achievement(id: "streak_30", title: "Monthly Spark", description: "Maintain a 30-day streak", icon: "flame.fill", category: .streak, rarity: .rare, requirement: 30, progress: 0, isUnlocked: false),
        Achievement(id: "streak_100", title: "Century Surge", description: "Maintain a 100-day streak", icon: "flame.fill", category: .streak, rarity: .epic, requirement: 100, progress: 0, isUnlocked: false),
        Achievement(id: "streak_365", title: "Year of Lightning", description: "Maintain a 365-day streak", icon: "flame.fill", category: .streak, rarity: .legendary, requirement: 365, progress: 0, isUnlocked: false),
    ]

    // MARK: Mastery Achievements
    static let mastery: [Achievement] = [
        Achievement(id: "master_unit_1", title: "Foundations Master", description: "Complete Unit 1 with 100%", icon: "star.fill", category: .mastery, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "perfect_lesson_1", title: "Perfect Score", description: "Get a perfect score on any lesson", icon: "checkmark.seal.fill", category: .mastery, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "perfect_lesson_5", title: "Perfectionist", description: "Get 5 perfect lessons", icon: "checkmark.seal.fill", category: .mastery, rarity: .rare, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "perfect_lesson_20", title: "Flawless", description: "Get 20 perfect lessons", icon: "checkmark.seal.fill", category: .mastery, rarity: .epic, requirement: 20, progress: 0, isUnlocked: false),
        Achievement(id: "all_units", title: "Graduate", description: "Complete all units", icon: "graduationcap.fill", category: .mastery, rarity: .legendary, requirement: 20, progress: 0, isUnlocked: false),
        Achievement(id: "complete_5_units", title: "Halfway There", description: "Complete 5 units", icon: "star.fill", category: .mastery, rarity: .rare, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "complete_10_units", title: "Double Digits", description: "Complete 10 units", icon: "star.fill", category: .mastery, rarity: .epic, requirement: 10, progress: 0, isUnlocked: false),
    ]

    // MARK: Speed Achievements
    static let speed: [Achievement] = [
        Achievement(id: "speed_3s", title: "Lightning Fast", description: "Answer correctly in under 3 seconds", icon: "bolt.fill", category: .speed, rarity: .rare, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "speed_lesson_2m", title: "Speed Run", description: "Complete a lesson in under 2 minutes", icon: "timer", category: .speed, rarity: .rare, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "combo_5", title: "On Fire", description: "Get a 5x combo", icon: "flame.fill", category: .speed, rarity: .common, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "combo_10", title: "Unstoppable", description: "Get a 10x combo", icon: "flame.fill", category: .speed, rarity: .rare, requirement: 10, progress: 0, isUnlocked: false),
        Achievement(id: "combo_25", title: "Legendary Combo", description: "Get a 25x combo", icon: "flame.fill", category: .speed, rarity: .epic, requirement: 25, progress: 0, isUnlocked: false),
        Achievement(id: "combo_50", title: "Combo God", description: "Get a 50x combo", icon: "flame.fill", category: .speed, rarity: .legendary, requirement: 50, progress: 0, isUnlocked: false),
    ]

    // MARK: Explorer Achievements
    static let explorer: [Achievement] = [
        Achievement(id: "first_3d", title: "3D Explorer", description: "View your first 3D model", icon: "cube.fill", category: .explorer, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "all_3d", title: "Model Collector", description: "View all 3D models", icon: "cube.fill", category: .explorer, rarity: .epic, requirement: 40, progress: 0, isUnlocked: false),
        Achievement(id: "first_ar", title: "Reality Bender", description: "Use AR mode for the first time", icon: "arkit", category: .explorer, rarity: .rare, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "all_exercise_types", title: "Jack of All Trades", description: "Try all exercise types", icon: "square.grid.3x3.fill", category: .explorer, rarity: .rare, requirement: 10, progress: 0, isUnlocked: false),
        Achievement(id: "daily_review_10", title: "Review Regular", description: "Complete 10 daily review sessions", icon: "arrow.clockwise", category: .explorer, rarity: .rare, requirement: 10, progress: 0, isUnlocked: false),
    ]

    // MARK: Social Achievements
    static let social: [Achievement] = [
        Achievement(id: "first_challenge", title: "Challenger", description: "Send your first challenge", icon: "person.2.fill", category: .social, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "win_challenge_5", title: "Champion", description: "Win 5 challenges", icon: "trophy.fill", category: .social, rarity: .rare, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "league_top3", title: "Podium Finish", description: "Finish top 3 in a league", icon: "medal.fill", category: .social, rarity: .rare, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "league_diamond", title: "Diamond League", description: "Reach Diamond league", icon: "diamond.fill", category: .social, rarity: .epic, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "share_circuit", title: "Sharer", description: "Share a circuit creation", icon: "square.and.arrow.up.fill", category: .social, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "add_friend_5", title: "Popular", description: "Add 5 friends", icon: "person.badge.plus", category: .social, rarity: .rare, requirement: 5, progress: 0, isUnlocked: false),
    ]

    // MARK: Builder Achievements
    static let builder: [Achievement] = [
        Achievement(id: "build_circuit_1", title: "First Build", description: "Build your first circuit", icon: "hammer.fill", category: .builder, rarity: .common, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "build_circuit_5", title: "Circuit Crafter", description: "Build 5 circuits", icon: "hammer.fill", category: .builder, rarity: .rare, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "build_circuit_20", title: "Master Builder", description: "Build 20 circuits", icon: "hammer.fill", category: .builder, rarity: .epic, requirement: 20, progress: 0, isUnlocked: false),
        Achievement(id: "simulate_10", title: "Simulator", description: "Run 10 current flow simulations", icon: "waveform.path.ecg", category: .builder, rarity: .rare, requirement: 10, progress: 0, isUnlocked: false),
        Achievement(id: "find_bugs_3", title: "Debugger", description: "Find 3 circuit bugs in troubleshoot mode", icon: "ladybug.fill", category: .builder, rarity: .rare, requirement: 3, progress: 0, isUnlocked: false),
        Achievement(id: "failure_modes", title: "Failure Expert", description: "Trigger all failure modes", icon: "exclamationmark.triangle.fill", category: .builder, rarity: .epic, requirement: 5, progress: 0, isUnlocked: false),
    ]

    // MARK: Knowledge Achievements
    static let knowledge: [Achievement] = [
        Achievement(id: "ohms_law_master", title: "Ohm's Law Master", description: "Get 10 Ohm's Law questions right in a row", icon: "brain.head.profile.fill", category: .knowledge, rarity: .rare, requirement: 10, progress: 0, isUnlocked: false),
        Achievement(id: "safety_complete", title: "Safety First", description: "Complete all safety lessons", icon: "shield.checkered", category: .knowledge, rarity: .rare, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "diagnostic_90", title: "Top Student", description: "Score 90%+ on the diagnostic quiz", icon: "brain.head.profile.fill", category: .knowledge, rarity: .epic, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "xp_1000", title: "XP Hunter", description: "Earn 1,000 total XP", icon: "sparkles", category: .knowledge, rarity: .common, requirement: 1000, progress: 0, isUnlocked: false),
        Achievement(id: "xp_5000", title: "XP Legend", description: "Earn 5,000 total XP", icon: "sparkles", category: .knowledge, rarity: .rare, requirement: 5000, progress: 0, isUnlocked: false),
        Achievement(id: "xp_10000", title: "XP Mythic", description: "Earn 10,000 total XP", icon: "sparkles", category: .knowledge, rarity: .epic, requirement: 10000, progress: 0, isUnlocked: false),
        Achievement(id: "xp_50000", title: "XP Immortal", description: "Earn 50,000 total XP", icon: "sparkles", category: .knowledge, rarity: .legendary, requirement: 50000, progress: 0, isUnlocked: false),
    ]
}

// MARK: - Achievement Manager
@MainActor
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    @Published var totalPoints: Int = 0

    private let storageKey = "user_achievements"

    init() {
        load()
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved progress with definitions (in case new achievements were added)
            let savedDict = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
            achievements = AchievementStore.all.map { definition in
                if let saved = savedDict[definition.id] {
                    return saved
                }
                return definition
            }
        } else {
            achievements = AchievementStore.all
        }
        totalPoints = achievements.filter(\.isUnlocked).reduce(0) { $0 + $1.rarity.points }
    }

    func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Check & Unlock

    func checkStreak(_ streak: Int) {
        updateProgress(for: ["streak_3", "streak_7", "streak_30", "streak_100", "streak_365"], value: streak)
    }

    func checkCombo(_ combo: Int) {
        updateProgress(for: ["combo_5", "combo_10", "combo_25", "combo_50"], value: combo)
    }

    func checkXP(_ xp: Int) {
        updateProgress(for: ["xp_1000", "xp_5000", "xp_10000", "xp_50000"], value: xp)
    }

    func checkPerfectLessons(_ count: Int) {
        updateProgress(for: ["perfect_lesson_1", "perfect_lesson_5", "perfect_lesson_20"], value: count)
    }

    func checkCompletedUnits(_ count: Int) {
        updateProgress(for: ["master_unit_1", "complete_5_units", "complete_10_units", "all_units"], value: count)
    }

    func checkCircuitsBuilt(_ count: Int) {
        updateProgress(for: ["build_circuit_1", "build_circuit_5", "build_circuit_20"], value: count)
    }

    func unlock(id: String) {
        guard let index = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) else { return }
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = Date()
        achievements[index].progress = achievements[index].requirement
        recentlyUnlocked = achievements[index]
        totalPoints += achievements[index].rarity.points
        save()
        AnalyticsService.shared.trackAchievementUnlocked(achievementId: id, category: achievements[index].category.rawValue)
    }

    private func updateProgress(for ids: [String], value: Int) {
        for id in ids {
            guard let index = achievements.firstIndex(where: { $0.id == id }) else { continue }
            achievements[index].progress = value
            if value >= achievements[index].requirement && !achievements[index].isUnlocked {
                unlock(id: id)
            }
        }
        save()
    }

    // Filtered views
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    var unlockedCount: Int { achievements.filter(\.isUnlocked).count }
    var totalCount: Int { achievements.count }
    var completionFraction: Double { Double(unlockedCount) / Double(max(1, totalCount)) }

    func displayBadges(limit: Int = 3) -> [Achievement] {
        achievements.filter(\.isUnlocked)
            .sorted { ($0.rarity.points, $0.unlockedAt ?? .distantPast) > ($1.rarity.points, $1.unlockedAt ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }
}
