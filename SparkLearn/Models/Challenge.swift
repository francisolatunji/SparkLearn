import Foundation
import SwiftUI

// MARK: - Challenge Status

enum ChallengeStatus: String, Codable, CaseIterable {
    case pending
    case active
    case completed

    var label: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .active: return "bolt.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending: return DS.warning
        case .active: return DS.primary
        case .completed: return DS.success
        }
    }
}

// MARK: - Challenge Difficulty

enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy: return DS.success
        case .medium: return DS.warning
        case .hard: return DS.error
        }
    }

    var questionCount: Int {
        switch self {
        case .easy: return 5
        case .medium: return 8
        case .hard: return 12
        }
    }

    var xpReward: Int {
        switch self {
        case .easy: return 30
        case .medium: return 60
        case .hard: return 100
        }
    }
}

// MARK: - Challenge Topic

enum ChallengeTopic: String, Codable, CaseIterable {
    case ohmsLaw = "Ohm's Law"
    case circuitBasics = "Circuit Basics"
    case resistors = "Resistors"
    case voltage = "Voltage & Current"
    case safety = "Electrical Safety"
    case seriesParallel = "Series & Parallel"
    case power = "Power & Energy"
    case magnetism = "Magnetism"
    case acDc = "AC vs DC"
    case components = "Components"

    var icon: String {
        switch self {
        case .ohmsLaw: return "function"
        case .circuitBasics: return "point.3.connected.trianglepath.dotted"
        case .resistors: return "rectangle.split.3x3"
        case .voltage: return "bolt.fill"
        case .safety: return "shield.checkered"
        case .seriesParallel: return "arrow.triangle.branch"
        case .power: return "battery.100.bolt"
        case .magnetism: return "magnet"
        case .acDc: return "waveform.path"
        case .components: return "cpu.fill"
        }
    }

    var color: Color {
        switch self {
        case .ohmsLaw: return DS.primary
        case .circuitBasics: return DS.accent
        case .resistors: return DS.deepPurple
        case .voltage: return DS.electricBlue
        case .safety: return DS.error
        case .seriesParallel: return DS.mint
        case .power: return DS.warning
        case .magnetism: return Color(hex: "EC4899")
        case .acDc: return DS.success
        case .components: return Color(hex: "6366F1")
        }
    }
}

// MARK: - Challenge Model

struct Challenge: Identifiable, Codable {
    let id: String
    let senderName: String
    let senderAvatar: String
    let topic: ChallengeTopic
    let difficulty: ChallengeDifficulty
    let questionsCount: Int
    var senderScore: Int?
    var recipientScore: Int?
    var status: ChallengeStatus
    let createdAt: Date
    let expiresAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }

    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }

    var timeRemainingFormatted: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var winner: String? {
        guard status == .completed,
              let s = senderScore,
              let r = recipientScore else { return nil }
        if s > r { return senderName }
        if r > s { return "You" }
        return "Tie"
    }

    var isChallengeOfTheWeek: Bool { false }
}

// MARK: - Weekly Challenge

struct WeeklyChallenge: Identifiable, Codable {
    let id: String
    let topic: ChallengeTopic
    let difficulty: ChallengeDifficulty
    let title: String
    let description: String
    let xpBonus: Int
    let participantCount: Int
    let weekStartDate: Date
}

// MARK: - Challenge Manager

@MainActor
class ChallengeManager: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var weeklyChallenge: WeeklyChallenge?

    private let storageKey = "user_challenges"
    private let weeklyKey = "weekly_challenge"
    private let weeklyDateKey = "weekly_challenge_date"

    var pendingChallenges: [Challenge] {
        challenges.filter { $0.status == .pending && !$0.isExpired }
    }

    var activeChallenges: [Challenge] {
        challenges.filter { $0.status == .active && !$0.isExpired }
    }

    var completedChallenges: [Challenge] {
        challenges.filter { $0.status == .completed }
    }

    init() {
        load()
        checkWeeklyChallenge()
        if challenges.isEmpty {
            generateSimulatedChallenges()
        }
    }

    // MARK: - Actions

    func sendChallenge(to friendName: String, avatar: String, topic: ChallengeTopic, difficulty: ChallengeDifficulty) {
        let challenge = Challenge(
            id: UUID().uuidString,
            senderName: "You",
            senderAvatar: "⚡",
            topic: topic,
            difficulty: difficulty,
            questionsCount: difficulty.questionCount,
            senderScore: nil,
            recipientScore: nil,
            status: .pending,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 3600)
        )
        challenges.insert(challenge, at: 0)
        save()
    }

    func acceptChallenge(_ challengeId: String) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeId }) else { return }
        challenges[index].status = .active
        save()
    }

    func completeChallenge(_ challengeId: String, yourScore: Int) {
        guard let index = challenges.firstIndex(where: { $0.id == challengeId }) else { return }
        challenges[index].recipientScore = yourScore
        if challenges[index].senderScore == nil {
            challenges[index].senderScore = Int.random(in: 40...95)
        }
        challenges[index].status = .completed
        save()
    }

    func declineChallenge(_ challengeId: String) {
        challenges.removeAll { $0.id == challengeId }
        save()
    }

    // MARK: - Weekly Challenge

    func checkWeeklyChallenge() {
        let calendar = Calendar.current
        if let weekly = weeklyChallenge,
           let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()),
           weekly.weekStartDate >= weekInterval.start {
            return
        }
        generateWeeklyChallengeOfTheWeek()
    }

    func generateWeeklyChallengeOfTheWeek() {
        let topic = ChallengeTopic.allCases.randomElement() ?? .ohmsLaw
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

        weeklyChallenge = WeeklyChallenge(
            id: UUID().uuidString,
            topic: topic,
            difficulty: .hard,
            title: "\(topic.rawValue) Showdown",
            description: "Compete against the community in this week's featured challenge. Top scorers earn bonus XP!",
            xpBonus: 150,
            participantCount: Int.random(in: 234...1892),
            weekStartDate: weekStart
        )
        saveWeekly()
    }

    // MARK: - Simulated Data

    func generateSimulatedChallenges() {
        let names = ["Alex", "Jordan", "Casey", "Morgan", "Taylor", "Riley", "Quinn", "Avery"]
        let avatars = ["🧑‍🔧", "👩‍🔬", "🧑‍💻", "👨‍🏫", "👩‍🎓", "🧑‍🔬", "👨‍💼", "👩‍🔧"]
        let topics = ChallengeTopic.allCases
        let difficulties = ChallengeDifficulty.allCases

        var simulated: [Challenge] = []

        // 2 pending challenges
        for i in 0..<2 {
            let topic = topics.randomElement()!
            let diff = difficulties.randomElement()!
            simulated.append(Challenge(
                id: "sim_pending_\(i)",
                senderName: names[i],
                senderAvatar: avatars[i],
                topic: topic,
                difficulty: diff,
                questionsCount: diff.questionCount,
                senderScore: Int.random(in: 60...95),
                recipientScore: nil,
                status: .pending,
                createdAt: Date().addingTimeInterval(-Double.random(in: 1800...7200)),
                expiresAt: Date().addingTimeInterval(Double.random(in: 10800...86400))
            ))
        }

        // 1 active challenge
        let activeTopic = topics.randomElement()!
        let activeDiff = difficulties.randomElement()!
        simulated.append(Challenge(
            id: "sim_active_0",
            senderName: names[2],
            senderAvatar: avatars[2],
            topic: activeTopic,
            difficulty: activeDiff,
            questionsCount: activeDiff.questionCount,
            senderScore: Int.random(in: 55...90),
            recipientScore: nil,
            status: .active,
            createdAt: Date().addingTimeInterval(-3600),
            expiresAt: Date().addingTimeInterval(20 * 3600)
        ))

        // 3 completed challenges
        for i in 0..<3 {
            let topic = topics.randomElement()!
            let diff = difficulties.randomElement()!
            let sScore = Int.random(in: 50...100)
            let rScore = Int.random(in: 50...100)
            simulated.append(Challenge(
                id: "sim_completed_\(i)",
                senderName: names[3 + i],
                senderAvatar: avatars[3 + i],
                topic: topic,
                difficulty: diff,
                questionsCount: diff.questionCount,
                senderScore: sScore,
                recipientScore: rScore,
                status: .completed,
                createdAt: Date().addingTimeInterval(-Double(i + 1) * 86400),
                expiresAt: Date().addingTimeInterval(-Double(i) * 86400)
            ))
        }

        challenges = simulated
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Challenge].self, from: data) {
            challenges = saved
        }
    }

    private func saveWeekly() {
        if let data = try? JSONEncoder().encode(weeklyChallenge) {
            UserDefaults.standard.set(data, forKey: weeklyKey)
        }
    }
}
