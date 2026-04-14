import Foundation

// MARK: - Analytics Event Types
enum AnalyticsEvent: String {
    // Core learning events
    case lessonStarted = "lesson_started"
    case lessonCompleted = "lesson_completed"
    case exerciseAnswered = "exercise_answered"
    case exerciseSkipped = "exercise_skipped"

    // Gamification events
    case streakExtended = "streak_extended"
    case streakBroken = "streak_broken"
    case heartLost = "heart_lost"
    case heartRefilled = "heart_refilled"
    case levelUp = "level_up"
    case comboAchieved = "combo_achieved"
    case achievementUnlocked = "achievement_unlocked"
    case leaguePromoted = "league_promoted"
    case leagueDemoted = "league_demoted"
    case dailyQuestCompleted = "daily_quest_completed"
    case treasureChestOpened = "treasure_chest_opened"
    case gemsEarned = "gems_earned"
    case gemsSpent = "gems_spent"

    // 3D interaction events
    case scene3DViewed = "3d_scene_viewed"
    case circuitBuilt = "circuit_built"
    case componentInspected = "component_inspected"
    case currentFlowSimulated = "current_flow_simulated"
    case failureModeTriggered = "failure_mode_triggered"

    // AR events
    case arSessionStarted = "ar_session_started"
    case arComponentPlaced = "ar_component_placed"
    case arScanToLearn = "ar_scan_to_learn"

    // Social events
    case challengeSent = "challenge_sent"
    case challengeCompleted = "challenge_completed"
    case friendAdded = "friend_added"
    case circuitShared = "circuit_shared"
    case classroomJoined = "classroom_joined"

    // AI events
    case aiHintRequested = "ai_hint_requested"
    case aiExplanationViewed = "ai_explanation_viewed"
    case askSparkyUsed = "ask_sparky_used"

    // Engagement events
    case appOpened = "app_opened"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case onboardingCompleted = "onboarding_completed"
    case diagnosticCompleted = "diagnostic_completed"
    case dailyGoalReached = "daily_goal_reached"
    case reviewSessionStarted = "review_session_started"
}

// MARK: - Analytics Service
final class AnalyticsService {
    static let shared = AnalyticsService()

    private var eventQueue: [QueuedEvent] = []
    private let maxQueueSize = 500
    private let queueKey = "analytics_event_queue"
    private var sessionStartTime: Date?
    private var currentSessionId: String?

    private init() {
        loadQueue()
        startSession()
    }

    // MARK: - Event Tracking

    func track(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        var enrichedProperties = properties
        enrichedProperties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        enrichedProperties["session_id"] = currentSessionId ?? "unknown"

        let queuedEvent = QueuedEvent(
            name: event.rawValue,
            properties: enrichedProperties.mapValues { "\($0)" },
            timestamp: Date()
        )

        eventQueue.append(queuedEvent)

        // Trim queue if too large
        if eventQueue.count > maxQueueSize {
            eventQueue.removeFirst(eventQueue.count - maxQueueSize)
        }

        saveQueue()

        // TODO: When Firebase is added, also log to Firebase Analytics
        // Analytics.logEvent(event.rawValue, parameters: enrichedProperties)

        #if DEBUG
        print("[Analytics] \(event.rawValue): \(enrichedProperties)")
        #endif
    }

    // MARK: - Convenience Methods

    func trackLessonStarted(lessonId: String, unitNumber: Int) {
        track(.lessonStarted, properties: [
            "lesson_id": lessonId,
            "unit_number": unitNumber
        ])
    }

    func trackLessonCompleted(lessonId: String, score: Int, xpEarned: Int, perfect: Bool, timeSeconds: Int) {
        track(.lessonCompleted, properties: [
            "lesson_id": lessonId,
            "score": score,
            "xp_earned": xpEarned,
            "perfect": perfect,
            "time_seconds": timeSeconds
        ])
    }

    func trackExerciseAnswered(exerciseId: String, correct: Bool, timeSeconds: Double, exerciseType: String) {
        track(.exerciseAnswered, properties: [
            "exercise_id": exerciseId,
            "correct": correct,
            "time_seconds": timeSeconds,
            "exercise_type": exerciseType
        ])
    }

    func trackAchievementUnlocked(achievementId: String, category: String) {
        track(.achievementUnlocked, properties: [
            "achievement_id": achievementId,
            "category": category
        ])
    }

    func track3DInteraction(sceneType: String, interactionType: String, duration: Double) {
        track(.scene3DViewed, properties: [
            "scene_type": sceneType,
            "interaction_type": interactionType,
            "duration": duration
        ])
    }

    // MARK: - Session Management

    func startSession() {
        currentSessionId = UUID().uuidString
        sessionStartTime = Date()
        track(.sessionStarted)
    }

    func endSession() {
        if let start = sessionStartTime {
            let duration = Date().timeIntervalSince(start)
            track(.sessionEnded, properties: ["duration_seconds": Int(duration)])
        }
        currentSessionId = nil
        sessionStartTime = nil
    }

    // MARK: - Queue Management

    func flushQueue() async {
        guard !eventQueue.isEmpty else { return }

        let eventsToSend = eventQueue
        eventQueue.removeAll()
        saveQueue()

        // TODO: Send to Firebase/backend
        // try? await BackendService.shared.sendAnalytics(eventsToSend)

        #if DEBUG
        print("[Analytics] Flushed \(eventsToSend.count) events")
        #endif
    }

    var pendingEventCount: Int { eventQueue.count }

    private func saveQueue() {
        if let data = try? JSONEncoder().encode(eventQueue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }

    private func loadQueue() {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let saved = try? JSONDecoder().decode([QueuedEvent].self, from: data) else { return }
        eventQueue = saved
    }
}

// MARK: - Queued Event Model
struct QueuedEvent: Codable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
}
