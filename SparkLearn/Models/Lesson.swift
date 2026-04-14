import Foundation
import SwiftUI

// MARK: - Unit
struct CourseUnit: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let lessons: [Lesson]
}

// MARK: - Lesson
struct Lesson: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let exercises: [Exercise]
}

// MARK: - Exercise
struct Exercise: Identifiable {
    let id = UUID()
    let type: ExerciseType
    let question: String
    let hint: String?
    let sceneType: SceneType?
    let explanation: String
}

enum ExerciseType {
    /// Classic multiple choice with text or image options
    case multipleChoice(options: [AnswerOption], correctIndex: Int)

    /// Tap tokens to fill blanks in a formula — e.g. "V = _ × _"
    case tapToFill(template: String, tokens: [String], correctOrder: [String])

    /// User types a numeric answer
    case numericInput(correctValue: Double, unit: String, tolerance: Double)

    /// Label parts of a diagram — user taps hotspots
    case diagramLabel(labels: [DiagramLabel])

    /// "Safe or Unsafe?" binary choice with image context
    case safetyScenario(isSafe: Bool, scenarioDescription: String)

    /// Flashcard: show a prompt, user recalls the answer then self-rates
    case flashcard(front: String, back: String, frontIcon: String?)

    /// Circuit Build: drag components to build a specified circuit
    case circuitBuild(targetDescription: String, requiredComponents: [String])

    /// Waveform Match: match oscilloscope patterns to circuit behaviors
    case waveformMatch(waveforms: [String], correctIndex: Int)

    /// Troubleshoot: find the bug in a broken circuit
    case troubleshoot(symptom: String, options: [String], correctIndex: Int)

    /// Code Completion: fill in Arduino code blanks
    case codeCompletion(template: String, options: [String], correctAnswer: String)
}

struct AnswerOption: Identifiable {
    let id = UUID()
    let text: String
    let isImage: Bool // if true, text is an SF Symbol name
}

struct DiagramLabel: Identifiable {
    let id = UUID()
    let componentName: String
    let position: CGPoint // normalized 0…1
    let symbol: String // SF Symbol
}

// MARK: - Scene Types for 3D
enum SceneType: String {
    case atom
    case battery
    case lightBulb
    case circuit
    case resistor
    case led
    case capacitor
    case diode
    case switchToggle
    case lightning
    case seriesCircuit
    case parallelCircuit
    case multimeter
    case breadboard
    case arduino
    case fuseBox
    // New 3D models
    case wire
    case potentiometer
    case transistor
    case relay
    case transformer
    case inductor
    case timer555
    case opAmp
    case photoresistor
    case thermistor
    case pirSensor
    case ultrasonicSensor
    case buzzer
    case servoMotor
    case dcMotor
    case stepperMotor
    case sevenSegment
    case lcd16x2
    case rgbLED
    case solarCell
    case esp32
    case raspberryPiPico
    case oscilloscope
    case solderingIron
    case customPCB
}

// MARK: - XP & Gamification
struct LessonResult {
    let lessonId: UUID
    let correctCount: Int
    let totalCount: Int
    let xpEarned: Int
    let perfectRun: Bool
}

enum CurriculumTier: String, CaseIterable, Codable {
    case foundations
    case applied
    case lab
    case safety

    var title: String {
        switch self {
        case .foundations:
            "Foundations"
        case .applied:
            "Applied Skills"
        case .lab:
            "Lab Ready"
        case .safety:
            "Safety"
        }
    }

    var icon: String {
        switch self {
        case .foundations:
            "book.closed.fill"
        case .applied:
            "wrench.and.screwdriver.fill"
        case .lab:
            "cpu.fill"
        case .safety:
            "shield.fill"
        }
    }
}

enum LearnerStage: String, CaseIterable, Codable {
    case beginner
    case explorer
    case builder

    var title: String {
        switch self {
        case .beginner:
            "Beginner"
        case .explorer:
            "Explorer"
        case .builder:
            "Builder"
        }
    }
}

enum LearningGoal: String, CaseIterable, Codable {
    case understandBasics
    case buildProjects
    case prepareForClass
    case staySafe

    var title: String {
        switch self {
        case .understandBasics:
            "Understand Basics"
        case .buildProjects:
            "Build Projects"
        case .prepareForClass:
            "Prepare for Class"
        case .staySafe:
            "Stay Safe"
        }
    }

    var subtitle: String {
        switch self {
        case .understandBasics:
            "Focus on core concepts and confidence."
        case .buildProjects:
            "Prioritize circuits, components, and Arduino."
        case .prepareForClass:
            "Keep concepts organized for quizzes and labs."
        case .staySafe:
            "Learn safe habits before touching hardware."
        }
    }
}

extension CourseUnit {
    var tier: CurriculumTier {
        switch number {
        case 1, 2:
            .foundations
        case 3, 4, 5:
            .applied
        case 6, 7:
            .lab
        default:
            .safety
        }
    }

    var estimatedMinutes: Int {
        lessons.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var keyOutcomes: [String] {
        switch number {
        case 1:
            ["Read voltage, current, and resistance", "Use Ohm's Law without guesswork"]
        case 2:
            ["Compare series and parallel behavior", "Predict what fails and why"]
        case 3:
            ["Pick the right component", "Interpret resistor and capacitor basics"]
        case 4:
            ["Measure circuits accurately", "Use a multimeter with intent"]
        case 5:
            ["Build on a breadboard", "Translate diagrams into real layouts"]
        case 6:
            ["Program simple Arduino behavior", "Connect code to hardware"]
        case 7:
            ["Troubleshoot common circuit faults", "Debug step by step"]
        default:
            ["Spot unsafe setups", "Choose safer actions before powering on"]
        }
    }
}

extension Lesson {
    var estimatedMinutes: Int {
        max(4, exercises.count * 2)
    }

    var stage: LearnerStage {
        if title.localizedCaseInsensitiveContains("quiz") {
            return .builder
        }
        if exercises.count >= 6 {
            return .explorer
        }
        return .beginner
    }

    var summary: String {
        switch title {
        case let title where title.localizedCaseInsensitiveContains("Voltage"):
            "Build an intuition for electrical pressure and common voltage sources."
        case let title where title.localizedCaseInsensitiveContains("Current"):
            "Learn how charge moves and how much current common parts can handle."
        case let title where title.localizedCaseInsensitiveContains("Resistance"):
            "Use resistance and Ohm's Law to predict circuit behavior."
        case let title where title.localizedCaseInsensitiveContains("Series"):
            "See what changes when components share one path."
        case let title where title.localizedCaseInsensitiveContains("Parallel"):
            "Understand why parallel branches keep systems flexible."
        case let title where title.localizedCaseInsensitiveContains("Resistor"):
            "Read values, calculate limits, and choose resistor sizes."
        case let title where title.localizedCaseInsensitiveContains("Capacitor"):
            "Understand storage, smoothing, and polarity."
        case let title where title.localizedCaseInsensitiveContains("LED"):
            "Drive diodes safely and identify polarity."
        case let title where title.localizedCaseInsensitiveContains("Arduino"):
            "Connect simple code with physical inputs and outputs."
        default:
            "Practice core electronics ideas with fast feedback."
        }
    }

    var skillTags: [String] {
        var tags: [String] = []
        if title.localizedCaseInsensitiveContains("Voltage") || title.localizedCaseInsensitiveContains("Current") || title.localizedCaseInsensitiveContains("Resistance") {
            tags.append("Core Theory")
        }
        if title.localizedCaseInsensitiveContains("Series") || title.localizedCaseInsensitiveContains("Parallel") {
            tags.append("Circuit Analysis")
        }
        if title.localizedCaseInsensitiveContains("Resistor") || title.localizedCaseInsensitiveContains("Capacitor") || title.localizedCaseInsensitiveContains("LED") {
            tags.append("Components")
        }
        if title.localizedCaseInsensitiveContains("Safety") {
            tags.append("Safety")
        }
        if tags.isEmpty {
            tags.append("Practice")
        }
        return tags
    }
}
