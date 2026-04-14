import Foundation
import SwiftUI

class ProgressManager: ObservableObject {
    @Published var totalXP: Int = 0
    @Published var currentStreak: Int = 0
    @Published var hearts: Int = 5
    @Published var completedLessons: Set<String> = [] // lesson id strings
    @Published var lessonScores: [String: Int] = [:] // lesson id -> best score %
    @Published var lastActiveDate: Date?
    @Published var level: Int = 1
    @Published var currentCombo: Int = 0
    @Published var bestCombo: Int = 0
    @Published var dailyXP: Int = 0
    @Published var dailyReminderEnabled: Bool = true
    @Published var reminderTime: Date = Calendar.current.date(
        bySettingHour: 19, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @Published var soundEffectsEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var reducedMotionEnabled: Bool = false
    @Published var immersiveLearningEnabled: Bool = true
    @Published var notificationsEnabled: Bool = false
    @Published var dailyXPGoal: Int = 120
    @Published var lastOpenedLessonID: String?
    @Published var lastHeartRefillDate: Date?

    // MARK: - New Gamification Fields
    @Published var gems: Int = 0
    @Published var totalPerfectLessons: Int = 0
    @Published var completedUnits: Int = 0
    @Published var circuitsBuilt: Int = 0
    @Published var modelsViewed: Int = 0
    @Published var hasStreakFreeze: Bool = false
    @Published var xpBoostActive: Bool = false
    @Published var xpBoostExpiry: Date?
    @Published var weeklyXP: Int = 0
    @Published var weekStartDate: Date = Date()
    @Published var challengesSent: Int = 0
    @Published var challengesWon: Int = 0
    @Published var friendCount: Int = 0
    @Published var sparkyCosumeId: String = "default"
    @Published var timeSpentTodaySeconds: Int = 0

    private let xpKey = "totalXP"
    private let streakKey = "currentStreak"
    private let heartsKey = "hearts"
    private let completedKey = "completedLessons"
    private let scoresKey = "lessonScores"
    private let lastDateKey = "lastActiveDate"
    private let levelKey = "level"
    private let bestComboKey = "bestCombo"
    private let dailyXPKey = "dailyXP"
    private let dailyXPDateKey = "dailyXPDate"
    private let dailyReminderEnabledKey = "dailyReminderEnabled"
    private let reminderTimeKey = "reminderTime"
    private let soundEffectsEnabledKey = "soundEffectsEnabled"
    private let hapticsEnabledKey = "hapticsEnabled"
    private let reducedMotionEnabledKey = "reducedMotionEnabled"
    private let immersiveLearningEnabledKey = "immersiveLearningEnabled"
    private let notificationsEnabledKey = "notificationsEnabled"
    private let dailyXPGoalKey = "dailyXPGoal"
    private let lastOpenedLessonIDKey = "lastOpenedLessonID"
    private let lastHeartRefillDateKey = "lastHeartRefillDate"
    private let gemsKey = "gems"
    private let perfectLessonsKey = "totalPerfectLessons"
    private let completedUnitsKey = "completedUnits"
    private let circuitsBuiltKey = "circuitsBuilt"
    private let modelsViewedKey = "modelsViewed"
    private let streakFreezeKey = "hasStreakFreeze"
    private let xpBoostActiveKey = "xpBoostActive"
    private let xpBoostExpiryKey = "xpBoostExpiry"
    private let weeklyXPKey = "weeklyXP"
    private let weekStartDateKey = "weekStartDate"
    private let sparkyCostumeKey = "sparkyCostumeId"

    let maxHearts = 5
    let xpPerCorrect = 10
    let xpBonusPerfect = 20
    let xpPerLevel = 100
    let heartRechargeInterval: TimeInterval = 15 * 60

    init() {
        load()
        checkStreak()
    }

    private func load() {
        totalXP = UserDefaults.standard.integer(forKey: xpKey)
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        hearts = UserDefaults.standard.object(forKey: heartsKey) as? Int ?? 5
        level = max(1, UserDefaults.standard.integer(forKey: levelKey))
        if let saved = UserDefaults.standard.array(forKey: completedKey) as? [String] {
            completedLessons = Set(saved)
        }
        if let saved = UserDefaults.standard.dictionary(forKey: scoresKey) as? [String: Int] {
            lessonScores = saved
        }
        lastActiveDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date
        bestCombo = UserDefaults.standard.integer(forKey: bestComboKey)
        refreshDailyXPBucket()
        dailyXP = UserDefaults.standard.integer(forKey: dailyXPKey)
        dailyReminderEnabled = UserDefaults.standard.object(forKey: dailyReminderEnabledKey) as? Bool ?? true
        reminderTime = UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? reminderTime
        soundEffectsEnabled = UserDefaults.standard.object(forKey: soundEffectsEnabledKey) as? Bool ?? true
        hapticsEnabled = UserDefaults.standard.object(forKey: hapticsEnabledKey) as? Bool ?? true
        reducedMotionEnabled = UserDefaults.standard.object(forKey: reducedMotionEnabledKey) as? Bool ?? false
        immersiveLearningEnabled = UserDefaults.standard.object(forKey: immersiveLearningEnabledKey) as? Bool ?? true
        notificationsEnabled = UserDefaults.standard.object(forKey: notificationsEnabledKey) as? Bool ?? false
        dailyXPGoal = max(30, UserDefaults.standard.object(forKey: dailyXPGoalKey) as? Int ?? 120)
        lastOpenedLessonID = UserDefaults.standard.string(forKey: lastOpenedLessonIDKey)
        lastHeartRefillDate = UserDefaults.standard.object(forKey: lastHeartRefillDateKey) as? Date ?? Date()
        gems = UserDefaults.standard.integer(forKey: gemsKey)
        totalPerfectLessons = UserDefaults.standard.integer(forKey: perfectLessonsKey)
        completedUnits = UserDefaults.standard.integer(forKey: completedUnitsKey)
        circuitsBuilt = UserDefaults.standard.integer(forKey: circuitsBuiltKey)
        modelsViewed = UserDefaults.standard.integer(forKey: modelsViewedKey)
        hasStreakFreeze = UserDefaults.standard.bool(forKey: streakFreezeKey)
        xpBoostActive = UserDefaults.standard.bool(forKey: xpBoostActiveKey)
        xpBoostExpiry = UserDefaults.standard.object(forKey: xpBoostExpiryKey) as? Date
        weeklyXP = UserDefaults.standard.integer(forKey: weeklyXPKey)
        weekStartDate = (UserDefaults.standard.object(forKey: weekStartDateKey) as? Date) ?? Date()
        sparkyCosumeId = UserDefaults.standard.string(forKey: sparkyCostumeKey) ?? "default"
        checkXPBoostExpiry()
        refreshHearts()
    }

    private func save() {
        UserDefaults.standard.set(totalXP, forKey: xpKey)
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(hearts, forKey: heartsKey)
        UserDefaults.standard.set(Array(completedLessons), forKey: completedKey)
        UserDefaults.standard.set(lessonScores, forKey: scoresKey)
        UserDefaults.standard.set(lastActiveDate, forKey: lastDateKey)
        UserDefaults.standard.set(level, forKey: levelKey)
        UserDefaults.standard.set(bestCombo, forKey: bestComboKey)
        UserDefaults.standard.set(dailyXP, forKey: dailyXPKey)
        UserDefaults.standard.set(dailyReminderEnabled, forKey: dailyReminderEnabledKey)
        UserDefaults.standard.set(reminderTime, forKey: reminderTimeKey)
        UserDefaults.standard.set(soundEffectsEnabled, forKey: soundEffectsEnabledKey)
        UserDefaults.standard.set(hapticsEnabled, forKey: hapticsEnabledKey)
        UserDefaults.standard.set(reducedMotionEnabled, forKey: reducedMotionEnabledKey)
        UserDefaults.standard.set(immersiveLearningEnabled, forKey: immersiveLearningEnabledKey)
        UserDefaults.standard.set(notificationsEnabled, forKey: notificationsEnabledKey)
        UserDefaults.standard.set(dailyXPGoal, forKey: dailyXPGoalKey)
        UserDefaults.standard.set(lastOpenedLessonID, forKey: lastOpenedLessonIDKey)
        UserDefaults.standard.set(lastHeartRefillDate, forKey: lastHeartRefillDateKey)
        UserDefaults.standard.set(gems, forKey: gemsKey)
        UserDefaults.standard.set(totalPerfectLessons, forKey: perfectLessonsKey)
        UserDefaults.standard.set(completedUnits, forKey: completedUnitsKey)
        UserDefaults.standard.set(circuitsBuilt, forKey: circuitsBuiltKey)
        UserDefaults.standard.set(modelsViewed, forKey: modelsViewedKey)
        UserDefaults.standard.set(hasStreakFreeze, forKey: streakFreezeKey)
        UserDefaults.standard.set(xpBoostActive, forKey: xpBoostActiveKey)
        UserDefaults.standard.set(xpBoostExpiry, forKey: xpBoostExpiryKey)
        UserDefaults.standard.set(weeklyXP, forKey: weeklyXPKey)
        UserDefaults.standard.set(weekStartDate, forKey: weekStartDateKey)
        UserDefaults.standard.set(sparkyCosumeId, forKey: sparkyCostumeKey)
    }

    private func refreshDailyXPBucket() {
        let cal = Calendar.current
        if let bucketDate = UserDefaults.standard.object(forKey: dailyXPDateKey) as? Date,
           cal.isDateInToday(bucketDate) {
            return
        }
        UserDefaults.standard.set(Date(), forKey: dailyXPDateKey)
        UserDefaults.standard.set(0, forKey: dailyXPKey)
    }

    private func checkStreak() {
        guard let last = lastActiveDate else { return }
        let cal = Calendar.current
        if cal.isDateInToday(last) { return }
        if cal.isDateInYesterday(last) { return }
        // Streak broken
        currentStreak = 0
        save()
    }

    func recordActivity() {
        let cal = Calendar.current
        if let last = lastActiveDate, cal.isDateInToday(last) { return }
        if let last = lastActiveDate, cal.isDateInYesterday(last) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        lastActiveDate = Date()
        save()
    }

    func completeLesson(_ result: LessonResult) {
        let idStr = result.lessonId.uuidString
        completedLessons.insert(idStr)

        totalXP += result.xpEarned
        dailyXP += result.xpEarned

        let pct = result.totalCount > 0 ? Int(Double(result.correctCount) / Double(result.totalCount) * 100) : 0
        let prev = lessonScores[idStr] ?? 0
        if pct > prev { lessonScores[idStr] = pct }

        level = max(1, totalXP / xpPerLevel + 1)

        recordActivity()
        save()
    }

    func loseHeart() {
        refreshHearts()
        hearts = max(0, hearts - 1)
        currentCombo = 0
        lastHeartRefillDate = Date()
        save()
    }

    func refillHearts() {
        hearts = maxHearts
        lastHeartRefillDate = Date()
        save()
    }

    func refreshHearts() {
        guard hearts < maxHearts else {
            lastHeartRefillDate = Date()
            return
        }

        let now = Date()
        let reference = lastHeartRefillDate ?? now
        let elapsed = now.timeIntervalSince(reference)
        guard elapsed >= heartRechargeInterval else { return }

        let recovered = Int(elapsed / heartRechargeInterval)
        hearts = min(maxHearts, hearts + recovered)
        let consumed = TimeInterval(recovered) * heartRechargeInterval
        lastHeartRefillDate = reference.addingTimeInterval(consumed)
        save()
    }

    var canStartLesson: Bool {
        refreshHearts()
        return hearts > 0
    }

    var nextHeartDate: Date? {
        guard hearts < maxHearts else { return nil }
        let reference = lastHeartRefillDate ?? Date()
        return reference.addingTimeInterval(heartRechargeInterval)
    }

    var xpInCurrentLevel: Int { totalXP % xpPerLevel }
    var xpProgressFraction: Double { Double(xpInCurrentLevel) / Double(xpPerLevel) }
    var dailyXPProgress: Double { min(1, Double(dailyXP) / Double(dailyXPGoal)) }

    func recordAnswer(correct: Bool) -> Int {
        guard correct else {
            currentCombo = 0
            return 0
        }

        currentCombo += 1
        bestCombo = max(bestCombo, currentCombo)

        // Keep reward density high without inflating progression too aggressively.
        if currentCombo >= 10 { return 6 }
        if currentCombo >= 5 { return 4 }
        if currentCombo >= 3 { return 2 }
        return 0
    }

    func isLessonCompleted(_ lessonId: UUID) -> Bool {
        completedLessons.contains(lessonId.uuidString)
    }

    func scoreForLesson(_ lessonId: UUID) -> Int? {
        lessonScores[lessonId.uuidString]
    }

    func updateDailyReminderEnabled(_ enabled: Bool) {
        dailyReminderEnabled = enabled
        if enabled && notificationsEnabled {
            NotificationCoordinator.scheduleDailyReminder(at: reminderTime)
        } else {
            NotificationCoordinator.clearDailyReminder()
        }
        save()
    }

    func updateReminderTime(_ date: Date) {
        reminderTime = date
        if dailyReminderEnabled && notificationsEnabled {
            NotificationCoordinator.scheduleDailyReminder(at: date)
        }
        save()
    }

    func updateSoundEffectsEnabled(_ enabled: Bool) {
        soundEffectsEnabled = enabled
        save()
    }

    func updateHapticsEnabled(_ enabled: Bool) {
        hapticsEnabled = enabled
        save()
    }

    func updateReducedMotionEnabled(_ enabled: Bool) {
        reducedMotionEnabled = enabled
        save()
    }

    func updateImmersiveLearningEnabled(_ enabled: Bool) {
        immersiveLearningEnabled = enabled
        save()
    }

    func updateNotificationsEnabled(_ enabled: Bool) {
        notificationsEnabled = enabled
        dailyReminderEnabled = enabled ? dailyReminderEnabled : false
        if enabled && dailyReminderEnabled {
            NotificationCoordinator.scheduleDailyReminder(at: reminderTime)
        } else {
            NotificationCoordinator.clearDailyReminder()
        }
        save()
    }

    func updateDailyXPGoal(_ value: Int) {
        dailyXPGoal = max(30, value)
        save()
    }

    func setLastOpenedLesson(_ lessonId: UUID) {
        lastOpenedLessonID = lessonId.uuidString
        save()
    }

    func clearLastOpenedLesson() {
        lastOpenedLessonID = nil
        save()
    }

    // MARK: - Gems
    func addGems(_ amount: Int) {
        gems += amount
        save()
    }

    func spendGems(_ amount: Int) -> Bool {
        guard gems >= amount else { return false }
        gems -= amount
        save()
        return true
    }

    // MARK: - Streak Freeze
    func purchaseStreakFreeze() -> Bool {
        let cost = 50
        guard spendGems(cost) else { return false }
        hasStreakFreeze = true
        save()
        return true
    }

    func useStreakFreeze() {
        hasStreakFreeze = false
        save()
    }

    // MARK: - XP Boost
    func activateXPBoost() {
        xpBoostActive = true
        xpBoostExpiry = Date().addingTimeInterval(3600) // 1 hour
        save()
    }

    func checkXPBoostExpiry() {
        if let expiry = xpBoostExpiry, Date() > expiry {
            xpBoostActive = false
            xpBoostExpiry = nil
            save()
        }
    }

    var xpMultiplier: Int {
        checkXPBoostExpiry()
        return xpBoostActive ? 2 : 1
    }

    // MARK: - Weekly XP
    func addWeeklyXP(_ xp: Int) {
        weeklyXP += xp
        save()
    }

    // MARK: - Builder Stats
    func recordCircuitBuilt() {
        circuitsBuilt += 1
        save()
    }

    func recordModelViewed() {
        modelsViewed += 1
        save()
    }

    func recordPerfectLesson() {
        totalPerfectLessons += 1
        save()
    }

    // MARK: - Costume
    func setSparkyCostume(_ id: String) {
        sparkyCosumeId = id
        save()
    }

    // MARK: - Sync Snapshot
    func createSnapshot() -> ProgressSnapshot {
        ProgressSnapshot(
            totalXP: totalXP,
            currentStreak: currentStreak,
            hearts: hearts,
            completedLessons: Array(completedLessons),
            lessonScores: lessonScores,
            level: level,
            lastSyncedAt: Date()
        )
    }
}
