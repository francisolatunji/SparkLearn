import Foundation

// MARK: - Firebase Configuration
// When adding Firebase SDK via SPM, uncomment the Firebase imports and implementations.
// For now, this provides the configuration constants and Firestore schema definitions.

/// Firestore collection paths
enum FirestoreCollections {
    static let users = "users"
    static let progress = "progress"
    static let leaderboards = "leaderboards"
    static let challenges = "challenges"
    static let analytics = "analytics"
    static let achievements = "achievements"
    static let leagues = "leagues"
    static let classrooms = "classrooms"
    static let circuitShares = "circuit_shares"
    static let friendships = "friendships"
    static let dailyQuests = "daily_quests"
    static let spacedRepetition = "spaced_repetition"
}

/// Remote Config keys for A/B testing gamification parameters
enum RemoteConfigKeys {
    static let xpPerCorrect = "xp_per_correct"
    static let xpBonusPerfect = "xp_bonus_perfect"
    static let heartRechargeMinutes = "heart_recharge_minutes"
    static let maxHearts = "max_hearts"
    static let leaguePromotionCount = "league_promotion_count"
    static let leagueDemotionCount = "league_demotion_count"
    static let dailyQuestCount = "daily_quest_count"
    static let aiHintDelay = "ai_hint_delay_seconds"
    static let streakFreezeGemCost = "streak_freeze_gem_cost"
    static let treasureChestEnabled = "treasure_chest_enabled"
}

/// Firebase configuration manager
/// Handles initialization, Remote Config, and feature flags
@MainActor
class FirebaseConfigManager: ObservableObject {
    static let shared = FirebaseConfigManager()

    @Published var isConfigured = false
    @Published var featureFlags: [String: Any] = [:]

    // Default values (used when Firebase is not yet configured)
    private let defaults: [String: Any] = [
        RemoteConfigKeys.xpPerCorrect: 10,
        RemoteConfigKeys.xpBonusPerfect: 20,
        RemoteConfigKeys.heartRechargeMinutes: 15,
        RemoteConfigKeys.maxHearts: 5,
        RemoteConfigKeys.leaguePromotionCount: 10,
        RemoteConfigKeys.leagueDemotionCount: 5,
        RemoteConfigKeys.dailyQuestCount: 3,
        RemoteConfigKeys.aiHintDelay: 15,
        RemoteConfigKeys.streakFreezeGemCost: 50,
        RemoteConfigKeys.treasureChestEnabled: true
    ]

    private init() {
        featureFlags = defaults
    }

    func configure() {
        // TODO: Initialize Firebase
        // FirebaseApp.configure()
        // setupRemoteConfig()
        isConfigured = true
    }

    func value<T>(for key: String) -> T? {
        featureFlags[key] as? T
    }

    func intValue(for key: String) -> Int {
        (featureFlags[key] as? Int) ?? 0
    }

    func boolValue(for key: String) -> Bool {
        (featureFlags[key] as? Bool) ?? false
    }

    // MARK: - Remote Config Fetch
    func fetchRemoteConfig() async {
        // TODO: Implement when Firebase is added
        // let remoteConfig = RemoteConfig.remoteConfig()
        // try? await remoteConfig.fetch(withExpirationDuration: 3600)
        // remoteConfig.activate()
        // Update featureFlags from remote values
    }
}
