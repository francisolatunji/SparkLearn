import Foundation

// MARK: - Concept Mastery Model

struct ConceptMastery: Codable, Identifiable {
    let id: String // concept identifier
    let conceptName: String
    let unitNumber: Int

    var totalAttempts: Int
    var correctAttempts: Int
    var averageResponseTime: Double // seconds
    var lastAttemptDate: Date?
    var consecutiveCorrect: Int
    var consecutiveIncorrect: Int

    init(id: String, conceptName: String, unitNumber: Int) {
        self.id = id
        self.conceptName = conceptName
        self.unitNumber = unitNumber
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.averageResponseTime = 0
        self.lastAttemptDate = nil
        self.consecutiveCorrect = 0
        self.consecutiveIncorrect = 0
    }

    // MARK: Mastery Score Components

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }

    /// Speed score: 1.0 = fast (< 3s), 0.0 = slow (> 20s)
    var speedScore: Double {
        guard averageResponseTime > 0 else { return 0.5 }
        return max(0, min(1.0, 1.0 - (averageResponseTime - 3.0) / 17.0))
    }

    /// Consistency: based on consecutive correct/incorrect streaks
    var consistency: Double {
        if totalAttempts < 3 { return 0.5 }
        if consecutiveCorrect >= 5 { return 1.0 }
        if consecutiveCorrect >= 3 { return 0.8 }
        if consecutiveIncorrect >= 3 { return 0.1 }
        return accuracy // fall back to accuracy
    }

    /// Recency: decays over time since last attempt
    var recency: Double {
        guard let lastDate = lastAttemptDate else { return 0 }
        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        // Exponential decay: halflife = 7 days
        return exp(-0.693 * Double(daysSince) / 7.0)
    }

    /// Composite mastery score (0.0 - 1.0)
    var masteryScore: Double {
        let weights = (accuracy: 0.4, speed: 0.15, consistency: 0.25, recency: 0.2)
        return accuracy * weights.accuracy +
               speedScore * weights.speed +
               consistency * weights.consistency +
               recency * weights.recency
    }

    /// Mastery level
    var level: MasteryLevel {
        switch masteryScore {
        case 0..<0.2: return .novice
        case 0.2..<0.4: return .learning
        case 0.4..<0.6: return .developing
        case 0.6..<0.8: return .proficient
        case 0.8...1.0: return .mastered
        default: return .novice
        }
    }
}

enum MasteryLevel: String, Codable {
    case novice = "Novice"
    case learning = "Learning"
    case developing = "Developing"
    case proficient = "Proficient"
    case mastered = "Mastered"

    var color: String {
        switch self {
        case .novice: return "EF4444"
        case .learning: return "F97316"
        case .developing: return "EAB308"
        case .proficient: return "22C55E"
        case .mastered: return "3B82F6"
        }
    }

    var icon: String {
        switch self {
        case .novice: return "circle"
        case .learning: return "circle.lefthalf.filled"
        case .developing: return "circle.inset.filled"
        case .proficient: return "checkmark.circle"
        case .mastered: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Adaptive Learning Engine
@MainActor
class AdaptiveLearningEngine: ObservableObject {
    @Published var conceptMasteries: [ConceptMastery] = []
    @Published var recommendedNextLessonId: String?
    @Published var weakConcepts: [ConceptMastery] = []
    @Published var strongConcepts: [ConceptMastery] = []

    private let storageKey = "concept_masteries"
    private let diagnosticKey = "diagnostic_results"
    private let diagnosticCompleteKey = "diagnostic_complete"

    @Published var diagnosticComplete: Bool = false
    @Published var diagnosticScores: [Int: Double] = [:] // unit -> score
    @Published var startingUnit: Int = 1

    init() {
        load()
        analyze()
    }

    // MARK: - Record Attempt

    func recordAttempt(conceptId: String, conceptName: String, unitNumber: Int, correct: Bool, responseTime: Double) {
        if let index = conceptMasteries.firstIndex(where: { $0.id == conceptId }) {
            var mastery = conceptMasteries[index]
            mastery.totalAttempts += 1
            if correct {
                mastery.correctAttempts += 1
                mastery.consecutiveCorrect += 1
                mastery.consecutiveIncorrect = 0
            } else {
                mastery.consecutiveIncorrect += 1
                mastery.consecutiveCorrect = 0
            }

            // Running average of response time
            let n = Double(mastery.totalAttempts)
            mastery.averageResponseTime = mastery.averageResponseTime * (n - 1) / n + responseTime / n

            mastery.lastAttemptDate = Date()
            conceptMasteries[index] = mastery
        } else {
            var newMastery = ConceptMastery(id: conceptId, conceptName: conceptName, unitNumber: unitNumber)
            newMastery.totalAttempts = 1
            newMastery.correctAttempts = correct ? 1 : 0
            newMastery.consecutiveCorrect = correct ? 1 : 0
            newMastery.consecutiveIncorrect = correct ? 0 : 1
            newMastery.averageResponseTime = responseTime
            newMastery.lastAttemptDate = Date()
            conceptMasteries.append(newMastery)
        }

        save()
        analyze()
    }

    // MARK: - Analysis

    func analyze() {
        weakConcepts = conceptMasteries
            .filter { $0.masteryScore < 0.4 && $0.totalAttempts > 0 }
            .sorted { $0.masteryScore < $1.masteryScore }

        strongConcepts = conceptMasteries
            .filter { $0.masteryScore >= 0.8 }
            .sorted { $0.masteryScore > $1.masteryScore }
    }

    // MARK: - Adaptive Difficulty

    /// Determine if the current exercise should be skipped (too easy)
    func shouldSkipExercise(conceptId: String) -> Bool {
        guard let mastery = conceptMasteries.first(where: { $0.id == conceptId }) else { return false }
        return mastery.masteryScore > 0.9 && mastery.consecutiveCorrect >= 3
    }

    /// Determine if a harder variant should be shown
    func shouldShowHarderVariant(conceptId: String) -> Bool {
        guard let mastery = conceptMasteries.first(where: { $0.id == conceptId }) else { return false }
        return mastery.consecutiveCorrect >= 3 && mastery.accuracy > 0.8
    }

    /// Determine if a hint should be proactively offered
    func shouldOfferHint(conceptId: String) -> Bool {
        guard let mastery = conceptMasteries.first(where: { $0.id == conceptId }) else { return true }
        return mastery.consecutiveIncorrect >= 2 || mastery.accuracy < 0.3
    }

    // MARK: - Interleaving

    /// Get an interleaved exercise order mixing weak and strong concepts
    func interleaveExercises(from exerciseIds: [String]) -> [String] {
        let weak = exerciseIds.filter { id in
            let mastery = conceptMasteries.first { $0.id == id }
            return (mastery?.masteryScore ?? 0) < 0.5
        }
        let strong = exerciseIds.filter { id in
            let mastery = conceptMasteries.first { $0.id == id }
            return (mastery?.masteryScore ?? 0) >= 0.5
        }

        // Interleave: 2 weak, 1 strong, repeat
        var result: [String] = []
        var weakIdx = 0, strongIdx = 0

        while weakIdx < weak.count || strongIdx < strong.count {
            for _ in 0..<2 {
                if weakIdx < weak.count {
                    result.append(weak[weakIdx])
                    weakIdx += 1
                }
            }
            if strongIdx < strong.count {
                result.append(strong[strongIdx])
                strongIdx += 1
            }
        }

        return result
    }

    // MARK: - Diagnostic Quiz

    func recordDiagnosticResult(unitNumber: Int, score: Double) {
        diagnosticScores[unitNumber] = score
        save()
    }

    func completeDiagnostic() {
        diagnosticComplete = true

        // Find starting unit: first unit where score < 70%
        startingUnit = 1
        for unit in 1...20 {
            let score = diagnosticScores[unit] ?? 0
            if score < 0.7 {
                startingUnit = unit
                break
            }
            if unit == 20 { startingUnit = 20 } // mastered everything
        }

        UserDefaults.standard.set(true, forKey: diagnosticCompleteKey)
        save()
    }

    // MARK: - Stats

    var overallMastery: Double {
        guard !conceptMasteries.isEmpty else { return 0 }
        return conceptMasteries.reduce(0) { $0 + $1.masteryScore } / Double(conceptMasteries.count)
    }

    func masteryForUnit(_ unit: Int) -> Double {
        let unitConcepts = conceptMasteries.filter { $0.unitNumber == unit }
        guard !unitConcepts.isEmpty else { return 0 }
        return unitConcepts.reduce(0) { $0 + $1.masteryScore } / Double(unitConcepts.count)
    }

    var weakestUnit: Int? {
        let unitScores = Dictionary(grouping: conceptMasteries, by: \.unitNumber)
            .mapValues { concepts in
                concepts.reduce(0) { $0 + $1.masteryScore } / Double(concepts.count)
            }
        return unitScores.min(by: { $0.value < $1.value })?.key
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(conceptMasteries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let data = try? JSONEncoder().encode(diagnosticScores) {
            UserDefaults.standard.set(data, forKey: diagnosticKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ConceptMastery].self, from: data) {
            conceptMasteries = saved
        }
        if let data = UserDefaults.standard.data(forKey: diagnosticKey),
           let saved = try? JSONDecoder().decode([Int: Double].self, from: data) {
            diagnosticScores = saved
        }
        diagnosticComplete = UserDefaults.standard.bool(forKey: diagnosticCompleteKey)
    }
}
