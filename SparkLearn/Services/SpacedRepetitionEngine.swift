import Foundation

// MARK: - Spaced Repetition (SM-2 Algorithm Variant)

/// Represents a single concept/card in the SRS system
struct SRSCard: Codable, Identifiable {
    let id: String // matches exercise or concept ID
    let conceptName: String
    let unitNumber: Int

    var easinessFactor: Double // starts at 2.5
    var interval: Int // days until next review
    var repetitions: Int // number of successful reviews
    var nextReviewDate: Date
    var lastReviewDate: Date?
    var lapses: Int // number of times reset to 0

    init(id: String, conceptName: String, unitNumber: Int) {
        self.id = id
        self.conceptName = conceptName
        self.unitNumber = unitNumber
        self.easinessFactor = 2.5
        self.interval = 1
        self.repetitions = 0
        self.nextReviewDate = Date() // due immediately
        self.lastReviewDate = nil
        self.lapses = 0
    }

    var isDue: Bool {
        nextReviewDate <= Date()
    }

    var isOverdue: Bool {
        guard isDue else { return false }
        let daysPast = Calendar.current.dateComponents([.day], from: nextReviewDate, to: Date()).day ?? 0
        return daysPast > 1
    }

    /// Urgency score for prioritizing reviews (higher = more urgent)
    var urgencyScore: Double {
        guard isDue else { return 0 }
        let daysPast = Calendar.current.dateComponents([.day], from: nextReviewDate, to: Date()).day ?? 0
        let overdueFactor = max(1.0, Double(daysPast + 1))
        let difficultyFactor = max(0.5, 3.0 - easinessFactor) // harder cards more urgent
        return overdueFactor * difficultyFactor
    }
}

// MARK: - Review Quality Rating
enum ReviewQuality: Int {
    case blackout = 0       // Complete failure to recall
    case incorrect = 1      // Incorrect, but upon seeing the correct answer, recognized it
    case incorrectEasy = 2  // Incorrect, but the correct answer seemed easy to recall
    case correct = 3        // Correct with serious difficulty
    case correctEasy = 4    // Correct after some hesitation
    case perfect = 5        // Correct with no hesitation

    /// Map from binary correct/incorrect + time
    static func from(correct: Bool, responseTime: TimeInterval) -> ReviewQuality {
        if !correct {
            return .incorrect
        }
        if responseTime < 3.0 {
            return .perfect
        }
        if responseTime < 8.0 {
            return .correctEasy
        }
        return .correct
    }
}

// MARK: - Spaced Repetition Engine
@MainActor
class SpacedRepetitionEngine: ObservableObject {
    @Published var cards: [SRSCard] = []
    @Published var dueCards: [SRSCard] = []
    @Published var reviewsCompletedToday: Int = 0

    private let storageKey = "srs_cards"
    private let reviewCountKey = "srs_reviews_today"
    private let reviewDateKey = "srs_review_date"

    let maxDailyReviews = 30
    let defaultSessionSize = 10

    init() {
        load()
        refreshDueCards()
    }

    // MARK: - SM-2 Core Algorithm

    func review(cardId: String, quality: ReviewQuality) {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else { return }

        var card = cards[index]
        let q = quality.rawValue

        // Update easiness factor
        let newEF = card.easinessFactor + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        card.easinessFactor = max(1.3, newEF)

        if q < 3 {
            // Failed review: reset
            card.repetitions = 0
            card.interval = 1
            card.lapses += 1
        } else {
            // Successful review
            card.repetitions += 1
            switch card.repetitions {
            case 1: card.interval = 1
            case 2: card.interval = 6
            default: card.interval = Int(round(Double(card.interval) * card.easinessFactor))
            }
        }

        card.lastReviewDate = Date()
        card.nextReviewDate = Calendar.current.date(byAdding: .day, value: card.interval, to: Date()) ?? Date()

        cards[index] = card
        reviewsCompletedToday += 1
        save()
        refreshDueCards()
    }

    // MARK: - Card Management

    func addCard(id: String, conceptName: String, unitNumber: Int) {
        guard !cards.contains(where: { $0.id == id }) else { return }
        let card = SRSCard(id: id, conceptName: conceptName, unitNumber: unitNumber)
        cards.append(card)
        save()
        refreshDueCards()
    }

    func addCardsForLesson(lessonId: String, conceptNames: [String], unitNumber: Int) {
        for (i, name) in conceptNames.enumerated() {
            let cardId = "\(lessonId)_concept_\(i)"
            addCard(id: cardId, conceptName: name, unitNumber: unitNumber)
        }
    }

    func refreshDueCards() {
        dueCards = cards
            .filter { $0.isDue }
            .sorted { $0.urgencyScore > $1.urgencyScore }

        // Reset daily counter if new day
        let calendar = Calendar.current
        if let lastDate = UserDefaults.standard.object(forKey: reviewDateKey) as? Date,
           !calendar.isDateInToday(lastDate) {
            reviewsCompletedToday = 0
            UserDefaults.standard.set(Date(), forKey: reviewDateKey)
            UserDefaults.standard.set(0, forKey: reviewCountKey)
        }
    }

    /// Get the next batch of cards for a review session
    func sessionCards(count: Int? = nil) -> [SRSCard] {
        let limit = min(count ?? defaultSessionSize, maxDailyReviews - reviewsCompletedToday)
        return Array(dueCards.prefix(max(0, limit)))
    }

    var totalDue: Int { dueCards.count }
    var hasReviewsAvailable: Bool { !dueCards.isEmpty && reviewsCompletedToday < maxDailyReviews }

    // MARK: - Stats

    var totalCards: Int { cards.count }
    var masteredCards: Int { cards.filter { $0.interval >= 21 }.count } // 3+ weeks interval = mastered
    var learningCards: Int { cards.filter { $0.interval < 21 && $0.repetitions > 0 }.count }
    var newCards: Int { cards.filter { $0.repetitions == 0 }.count }
    var averageEasiness: Double {
        guard !cards.isEmpty else { return 2.5 }
        return cards.reduce(0) { $0 + $1.easinessFactor } / Double(cards.count)
    }

    // MARK: - Retention forecast
    func retentionForecast(days: Int = 7) -> [(date: Date, dueCount: Int)] {
        var forecast: [(Date, Int)] = []
        let calendar = Calendar.current

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            let dueOnDate = cards.filter { card in
                calendar.isDate(card.nextReviewDate, inSameDayAs: date) ||
                (card.nextReviewDate < date && dayOffset == 0)
            }.count
            forecast.append((date, dueOnDate))
        }

        return forecast
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(cards) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(reviewsCompletedToday, forKey: reviewCountKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([SRSCard].self, from: data) {
            cards = saved
        }
        reviewsCompletedToday = UserDefaults.standard.integer(forKey: reviewCountKey)
    }
}
