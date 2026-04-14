import Foundation

// MARK: - AI Tutor Service (Claude API Integration)

/// Hint progression: vague → specific → near-answer
enum HintLevel: Int {
    case nudge = 0      // "Think about what happens when..."
    case guided = 1     // "Remember that in a series circuit..."
    case specific = 2   // "The formula you need is V = I × R, and the current is..."
}

/// AI Tutor message
struct TutorMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: String, Codable {
        case user, assistant, system
    }

    init(role: MessageRole, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

/// Cached hint for offline usage
struct CachedHint: Codable {
    let exercisePattern: String
    let hintLevel: Int
    let hint: String
}

// MARK: - AI Tutor Service
@MainActor
class AITutorService: ObservableObject {
    @Published var isLoading = false
    @Published var conversationHistory: [TutorMessage] = []
    @Published var questionsUsedThisLesson: Int = 0
    @Published var currentHintLevel: HintLevel = .nudge

    private let maxQuestionsPerLesson = 5
    private let apiKey: String? = nil // Set via environment or secure config
    private let cacheKey = "ai_hint_cache"

    // Pre-written hints for offline mode (organized by concept)
    private let offlineHints: [String: [String]] = [
        "ohms_law": [
            "Think about the relationship between voltage, current, and resistance. They're all connected!",
            "Ohm's Law states that V = I × R. If you know two of these values, you can find the third.",
            "To find the missing value: V = I × R, I = V / R, R = V / I. Plug in the numbers you know."
        ],
        "series_circuit": [
            "In a series circuit, all components share the same path. What does that mean for the current?",
            "In series circuits, current is the same everywhere. Voltage divides across components proportionally to their resistance.",
            "Total resistance in series: R_total = R1 + R2 + R3... Use this with Ohm's Law to find the answer."
        ],
        "parallel_circuit": [
            "Parallel circuits have branches. Think about what stays the same across all branches.",
            "In parallel circuits, voltage is the same across all branches. Current divides based on resistance.",
            "For parallel resistance: 1/R_total = 1/R1 + 1/R2. Calculate R_total, then use V = I × R_total."
        ],
        "resistor_values": [
            "Resistors use color bands to show their value. Each color represents a number.",
            "The first two bands are digits, the third is a multiplier. Black=0, Brown=1, Red=2, Orange=3...",
            "Read the bands: first digit × 10 + second digit, then multiply by the multiplier band value."
        ],
        "capacitor": [
            "A capacitor stores energy in an electric field. Think of it like a tiny rechargeable battery.",
            "Capacitance is measured in Farads (F). Most capacitors are microfarads (µF) or picofarads (pF).",
            "In series: 1/C_total = 1/C1 + 1/C2. In parallel: C_total = C1 + C2. Opposite of resistors!"
        ],
        "led_safety": [
            "LEDs are diodes — they only work in one direction. But there's something else critical...",
            "LEDs need a current-limiting resistor! Without one, too much current flows and the LED burns out.",
            "Use R = (V_supply - V_LED) / I_LED. Typical: V_LED ≈ 2V, I_LED ≈ 20mA. So R = (5-2)/0.02 = 150Ω."
        ],
        "arduino_basics": [
            "Arduino programs have two main functions. What are they, and what does each one do?",
            "setup() runs once at the start. loop() runs repeatedly forever. Most of your code goes in loop().",
            "Use pinMode() in setup to configure pins. Use digitalWrite() or analogWrite() in loop to control outputs."
        ],
        "safety_general": [
            "Before working with any circuit, always think: what could go wrong?",
            "Key safety rules: never work on live circuits, check connections before powering on, and use proper fuses.",
            "The most dangerous scenarios involve water + electricity, high voltage, or no overcurrent protection."
        ],
        "default": [
            "Take a moment to re-read the question carefully. The answer is in the details!",
            "Try eliminating options you know are wrong. Sometimes the process of elimination is the fastest path.",
            "Think about the fundamental principle being tested here. Go back to basics."
        ]
    ]

    var canAskQuestion: Bool {
        questionsUsedThisLesson < maxQuestionsPerLesson
    }

    var questionsRemaining: Int {
        max(0, maxQuestionsPerLesson - questionsUsedThisLesson)
    }

    // MARK: - Get Hint

    func getHint(for concept: String, question: String, hintLevel: HintLevel) -> String {
        currentHintLevel = hintLevel

        // Try to find concept-specific hints
        let key = findClosestConceptKey(for: concept)
        let hints = offlineHints[key] ?? offlineHints["default"]!

        let levelIndex = min(hintLevel.rawValue, hints.count - 1)
        return hints[levelIndex]
    }

    func getProgressiveHint(for concept: String, question: String) -> String {
        let hint = getHint(for: concept, question: question, hintLevel: currentHintLevel)

        // Advance to next level for next time
        if let nextLevel = HintLevel(rawValue: currentHintLevel.rawValue + 1) {
            currentHintLevel = nextLevel
        }

        return hint
    }

    func resetHintLevel() {
        currentHintLevel = .nudge
    }

    // MARK: - AI Explanation (Post-Answer)

    func generateExplanation(question: String, correctAnswer: String, userAnswer: String, concept: String, isCorrect: Bool) -> String {
        if isCorrect {
            return generateCorrectExplanation(concept: concept, answer: correctAnswer)
        } else {
            return generateIncorrectExplanation(concept: concept, correctAnswer: correctAnswer, userAnswer: userAnswer)
        }
    }

    private func generateCorrectExplanation(concept: String, answer: String) -> String {
        let explanations: [String: String] = [
            "ohms_law": "Exactly right! You applied Ohm's Law (V = I × R) correctly. This is the foundation of circuit analysis — once it clicks, everything else builds on it.",
            "series_circuit": "Perfect! In a series circuit, the same current flows through every component. You correctly calculated how the values relate.",
            "parallel_circuit": "Spot on! Parallel circuits maintain the same voltage across branches while current divides. You've got a solid grasp of this.",
            "resistor_values": "Great job reading those color bands! This is a skill that becomes second nature with practice.",
            "capacitor": "Correct! Capacitors can be tricky because they behave opposite to resistors in series/parallel — you handled it perfectly.",
            "led_safety": "Right! Always protect your LEDs with a current-limiting resistor. You've got the safety mindset.",
            "arduino_basics": "Nice work! Understanding the Arduino's program structure is the first step to building amazing projects.",
            "safety_general": "Excellent safety awareness! This kind of thinking prevents real-world accidents."
        ]

        let key = findClosestConceptKey(for: concept)
        return explanations[key] ?? "Correct! You clearly understand this concept. Keep building on this knowledge."
    }

    private func generateIncorrectExplanation(concept: String, correctAnswer: String, userAnswer: String) -> String {
        let explanations: [String: String] = [
            "ohms_law": "The correct answer is \(correctAnswer). Remember: V = I × R connects voltage, current, and resistance. If you know any two, you can find the third. A common mistake is mixing up which variable to solve for.",
            "series_circuit": "The answer is \(correctAnswer). In series circuits, current stays the same everywhere, but voltage splits across components. Total resistance is R1 + R2 + R3...",
            "parallel_circuit": "The answer is \(correctAnswer). In parallel, voltage is the same across all branches. For resistance: 1/R_total = 1/R1 + 1/R2. This is the opposite of series!",
            "resistor_values": "The correct answer is \(correctAnswer). Color band reading: first band = first digit, second band = second digit, third band = multiplier. Practice makes perfect!",
            "capacitor": "The answer is \(correctAnswer). Remember: capacitors in parallel ADD (C_total = C1 + C2), but in series they combine like parallel resistors (1/C_total = 1/C1 + 1/C2).",
            "led_safety": "The answer is \(correctAnswer). LEDs always need a current-limiting resistor! Without one, the LED draws too much current and burns out. R = (V_supply - V_LED) / I_LED.",
            "arduino_basics": "The answer is \(correctAnswer). Arduino sketches always have setup() (runs once) and loop() (runs forever). Use pinMode() to configure and digitalRead/Write to interact.",
            "safety_general": "The answer is \(correctAnswer). Safety is non-negotiable in electronics. Always de-energize before working, use appropriate protection, and think before you connect."
        ]

        let key = findClosestConceptKey(for: concept)
        return explanations[key] ?? "The correct answer is \(correctAnswer). Don't worry — making mistakes is part of learning! Review this concept and try again."
    }

    // MARK: - Ask Sparky (Chat Mode)

    func askSparky(question: String, currentLesson: String, currentConcept: String) async -> String {
        guard canAskQuestion else {
            return "I've answered \(maxQuestionsPerLesson) questions this lesson! Try working through the exercises — you've got this! 💡"
        }

        questionsUsedThisLesson += 1

        // Add user message to history
        conversationHistory.append(TutorMessage(role: .user, content: question))

        // Generate response (offline mode — pattern matching)
        let response = generateOfflineResponse(question: question, concept: currentConcept)

        conversationHistory.append(TutorMessage(role: .assistant, content: response))

        AnalyticsService.shared.track(.askSparkyUsed, properties: [
            "lesson": currentLesson,
            "concept": currentConcept,
            "questions_used": questionsUsedThisLesson
        ])

        return response
    }

    func resetForNewLesson() {
        questionsUsedThisLesson = 0
        conversationHistory.removeAll()
        currentHintLevel = .nudge
    }

    // MARK: - Claude API Integration

    func askClaudeAPI(question: String, context: String) async -> String? {
        guard let apiKey = apiKey, !apiKey.isEmpty else { return nil }

        // TODO: Implement actual Claude API call
        // let url = URL(string: "https://api.anthropic.com/v1/messages")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "content-type")
        // request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        // request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        //
        // let body: [String: Any] = [
        //     "model": "claude-sonnet-4-20250514",
        //     "max_tokens": 300,
        //     "system": "You are Sparky, a friendly electronics tutor in the SparkLearn app...",
        //     "messages": [["role": "user", "content": question]]
        // ]
        // request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        //
        // let (data, _) = try await URLSession.shared.data(for: request)
        // parse response...

        return nil
    }

    // MARK: - Helpers

    private func findClosestConceptKey(for concept: String) -> String {
        let lowered = concept.lowercased()
        if lowered.contains("ohm") || lowered.contains("v=ir") { return "ohms_law" }
        if lowered.contains("series") { return "series_circuit" }
        if lowered.contains("parallel") { return "parallel_circuit" }
        if lowered.contains("resistor") || lowered.contains("color") { return "resistor_values" }
        if lowered.contains("capacitor") || lowered.contains("farad") { return "capacitor" }
        if lowered.contains("led") || lowered.contains("diode") { return "led_safety" }
        if lowered.contains("arduino") || lowered.contains("code") { return "arduino_basics" }
        if lowered.contains("safety") || lowered.contains("danger") { return "safety_general" }
        return "default"
    }

    private func generateOfflineResponse(question: String, concept: String) -> String {
        let q = question.lowercased()

        // Pattern-based responses
        if q.contains("what is") || q.contains("what's") {
            let key = findClosestConceptKey(for: q)
            let definitions: [String: String] = [
                "ohms_law": "Ohm's Law (V = I × R) describes the relationship between voltage (V), current (I), and resistance (R) in a circuit. It's the most important equation in electronics! Think of voltage as water pressure, current as flow rate, and resistance as pipe width.",
                "series_circuit": "A series circuit is one where all components are connected end-to-end in a single path. Current is the same through each component, but voltage divides across them based on their resistance.",
                "parallel_circuit": "A parallel circuit has multiple paths for current to flow. Each branch gets the full source voltage, but current divides among branches. More branches = lower total resistance!",
                "capacitor": "A capacitor stores electrical energy in an electric field between two conductive plates. It charges up when voltage is applied and releases energy when disconnected. Measured in Farads (F).",
                "resistor_values": "Resistors limit current flow in a circuit. Their values are shown by colored bands. A typical resistor has 4 bands: digit, digit, multiplier, and tolerance. Brown-Black-Red = 1,000Ω = 1kΩ.",
                "default": "Great question! This concept is covered in your current lesson. Try working through the exercises — each one builds your understanding step by step. If you're stuck on a specific part, ask me about it!"
            ]
            let key2 = findClosestConceptKey(for: q)
            return definitions[key2] ?? definitions["default"]!
        }

        if q.contains("why") {
            return "That's a deep question! In electronics, 'why' often comes down to the physics of electron flow. The key principle here relates to \(concept). Try thinking about what happens at the atomic level — electrons follow the path of least resistance, and energy is always conserved."
        }

        if q.contains("how") {
            return "Here's how to approach this: First, identify what values you know. Then, find the right formula (Ohm's Law is your best friend here). Finally, plug in the numbers. Remember: units matter! Always check that your answer makes physical sense."
        }

        if q.contains("help") || q.contains("stuck") || q.contains("confused") {
            return "No worries — everyone gets stuck sometimes! Let's break this down. Look at the question again: what information are you given? What are you solving for? Once you identify those two things, the right formula usually becomes clear. You can do this!"
        }

        return "Interesting question! Here's what I know about \(concept): the key is understanding the fundamental relationship between the components. Try re-reading the question and focusing on the specific values given. If you need more help, ask me about a specific part that's confusing!"
    }
}
