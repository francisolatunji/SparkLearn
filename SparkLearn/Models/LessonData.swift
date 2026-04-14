import SwiftUI

struct CourseData {

    // MARK: - All Units
    static let units: [CourseUnit] = [unit1, unit1b, unit2, unit3, unit3b, unit4, unit5, unit6, unit7, unit8, unit11, unit12, unit13, unit14, unit15, unit16, unit17, unit18, unit19, unit20]

    // ──────────────────────────────────────────────
    // UNIT 1B — Flashcard Recall: Basics
    // ──────────────────────────────────────────────
    static let unit1b = CourseUnit(
        number: 1,
        title: "Recall: Basics",
        subtitle: "Flashcard practice — V, I, R",
        icon: "rectangle.on.rectangle.angled",
        color: Color(hex: "F59E0B"),
        lessons: [
            Lesson(title: "Symbol Recall", icon: "character.textbox", exercises: [
                Exercise(
                    type: .flashcard(front: "Symbol: V", back: "Voltage — the electrical pressure that pushes electrons. Measured in Volts.", frontIcon: "bolt"),
                    question: "What does this symbol represent?",
                    hint: nil, sceneType: nil,
                    explanation: "V stands for Voltage, measured in Volts."
                ),
                Exercise(
                    type: .flashcard(front: "Symbol: I", back: "Current — the flow of electrons through a conductor. Measured in Amperes (Amps).", frontIcon: "arrow.right"),
                    question: "What does this symbol represent?",
                    hint: nil, sceneType: nil,
                    explanation: "I stands for Current (from French 'intensité'), measured in Amps."
                ),
                Exercise(
                    type: .flashcard(front: "Symbol: R", back: "Resistance — opposition to current flow. Measured in Ohms (Ω).", frontIcon: "equal.circle"),
                    question: "What does this symbol represent?",
                    hint: nil, sceneType: nil,
                    explanation: "R stands for Resistance, measured in Ohms."
                ),
                Exercise(
                    type: .flashcard(front: "Symbol: Ω", back: "Ohm — the unit of electrical resistance. Named after Georg Ohm.", frontIcon: "textformat"),
                    question: "What does this symbol represent?",
                    hint: nil, sceneType: nil,
                    explanation: "Ω (Omega) is the symbol for Ohms, the unit of resistance."
                ),
                Exercise(
                    type: .flashcard(front: "V = I × R", back: "Ohm's Law — Voltage equals Current times Resistance.", frontIcon: "function"),
                    question: "What law is this?",
                    hint: nil, sceneType: nil,
                    explanation: "Ohm's Law: the fundamental relationship between voltage, current, and resistance."
                ),
                Exercise(
                    type: .numericInput(correctValue: 10, unit: "mA", tolerance: 0),
                    question: "Quick calc: 5V across 500Ω. Current in mA?",
                    hint: "I = V/R, then convert A to mA.",
                    sceneType: nil,
                    explanation: "I = 5/500 = 0.01A = 10mA."
                ),
                Exercise(
                    type: .numericInput(correctValue: 12, unit: "V", tolerance: 0),
                    question: "Quick calc: 0.5A through 24Ω. Voltage?",
                    hint: "V = I × R",
                    sceneType: nil,
                    explanation: "V = 0.5 × 24 = 12V."
                ),
                Exercise(
                    type: .flashcard(front: "What's the difference between AC and DC?", back: "AC alternates direction (wall outlets, 60Hz).\nDC flows one direction (batteries, USB).", frontIcon: "waveform"),
                    question: "Recall: AC vs DC",
                    hint: nil, sceneType: nil,
                    explanation: "AC = Alternating Current (mains power). DC = Direct Current (batteries)."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 1 — Voltage, Current, Resistance
    // ──────────────────────────────────────────────
    static let unit1 = CourseUnit(
        number: 1,
        title: "Power Basics",
        subtitle: "Voltage, current & Ohm's Law",
        icon: "bolt.fill",
        color: Color("AccentGreen"),
        lessons: [
            Lesson(title: "What is Voltage?", icon: "battery.100", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The speed of electrons", isImage: false),
                            AnswerOption(text: "The push that moves electrons", isImage: false),
                            AnswerOption(text: "The number of electrons", isImage: false),
                            AnswerOption(text: "The weight of a wire", isImage: false)
                        ],
                        correctIndex: 1
                    ),
                    question: "What is voltage?",
                    hint: "Think of water pressure in a pipe.",
                    sceneType: .battery,
                    explanation: "Voltage is the electrical pressure — the force that pushes electrons through a circuit. Measured in Volts (V)."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Voltage is measured in ___",
                        tokens: ["Amps", "Volts", "Ohms", "Watts"],
                        correctOrder: ["Volts"]
                    ),
                    question: "Fill in the blank:",
                    hint: "Named after Alessandro Volta.",
                    sceneType: nil,
                    explanation: "The unit of voltage is the Volt (V), named after the inventor of the first battery."
                ),
                Exercise(
                    type: .numericInput(correctValue: 9, unit: "V", tolerance: 0),
                    question: "A standard rectangular battery (like in a smoke detector) is rated at how many volts?",
                    hint: "It's a single digit number.",
                    sceneType: .battery,
                    explanation: "A standard 9V battery provides 9 volts. These rectangular batteries are common in smoke detectors and guitar pedals."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Touching the terminals of a car battery (12V) with both wet hands."),
                    question: "Safe or Unsafe?",
                    hint: "Water conducts electricity.",
                    sceneType: nil,
                    explanation: "Unsafe! Water greatly reduces your skin's resistance, allowing more current to flow. A 12V car battery can deliver hundreds of amps."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "1.5 V", isImage: false),
                            AnswerOption(text: "5 V", isImage: false),
                            AnswerOption(text: "12 V", isImage: false),
                            AnswerOption(text: "120 V", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is the voltage of a standard AA battery?",
                    hint: "It's the lowest option.",
                    sceneType: .battery,
                    explanation: "A single AA battery provides 1.5 volts. When you stack them in series, the voltages add up!"
                )
            ]),

            Lesson(title: "What is Current?", icon: "arrow.right.arrow.left", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The flow of electrons through a conductor", isImage: false),
                            AnswerOption(text: "The resistance of a wire", isImage: false),
                            AnswerOption(text: "The color of a resistor", isImage: false),
                            AnswerOption(text: "The size of a battery", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is electrical current?",
                    hint: "Think of water flowing through a pipe.",
                    sceneType: .circuit,
                    explanation: "Current is the flow of electrons through a conductor. It's like the flow rate of water in a pipe."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Current is measured in ___",
                        tokens: ["Volts", "Amps", "Ohms", "Farads"],
                        correctOrder: ["Amps"]
                    ),
                    question: "Fill in the blank:",
                    hint: "Named after André-Marie Ampère.",
                    sceneType: nil,
                    explanation: "Current is measured in Amperes (Amps, A). 1 Amp = about 6.24 × 10¹⁸ electrons flowing per second!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "From + to − (conventional)", isImage: false),
                            AnswerOption(text: "From − to + (electron flow)", isImage: false),
                            AnswerOption(text: "Both are used", isImage: false),
                            AnswerOption(text: "In circles only", isImage: false)
                        ],
                        correctIndex: 2
                    ),
                    question: "Which direction does current flow?",
                    hint: "There are two conventions.",
                    sceneType: .circuit,
                    explanation: "Both! Conventional current flows + to −, but electrons actually flow − to +. Most schematics use conventional current."
                ),
                Exercise(
                    type: .numericInput(correctValue: 20, unit: "mA", tolerance: 0),
                    question: "A typical LED needs about ___ milliamps of current to light up.",
                    hint: "It's a common round number between 10 and 30.",
                    sceneType: .led,
                    explanation: "Most standard LEDs are rated for about 20mA (0.020 Amps). Too much current will burn them out!"
                ),
                Exercise(
                    type: .safetyScenario(isSafe: true, scenarioDescription: "Using a current-limiting resistor before an LED in a 5V circuit."),
                    question: "Safe or Unsafe?",
                    hint: "Resistors protect components.",
                    sceneType: nil,
                    explanation: "Safe! The resistor limits the current so the LED doesn't burn out. Always use a resistor with LEDs."
                )
            ]),

            Lesson(title: "Resistance & Ohm's Law", icon: "equal.circle.fill", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "How much a material opposes current flow", isImage: false),
                            AnswerOption(text: "How fast electrons move", isImage: false),
                            AnswerOption(text: "The color of a wire", isImage: false),
                            AnswerOption(text: "The voltage of a battery", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is resistance?",
                    hint: "Think of a narrow pipe slowing water flow.",
                    sceneType: .resistor,
                    explanation: "Resistance is how much a material opposes the flow of electric current. Measured in Ohms (Ω)."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "V = ___ × ___",
                        tokens: ["I", "R", "P", "C"],
                        correctOrder: ["I", "R"]
                    ),
                    question: "Ohm's Law: fill in the formula.",
                    hint: "Voltage = Current × Resistance",
                    sceneType: nil,
                    explanation: "Ohm's Law: V = I × R. Voltage equals Current times Resistance. This is the most important formula in electronics!"
                ),
                Exercise(
                    type: .numericInput(correctValue: 5, unit: "mA", tolerance: 0),
                    question: "You have 5V across a 1kΩ resistor. What current flows? (in mA)",
                    hint: "I = V / R. Don't forget: 1kΩ = 1000Ω.",
                    sceneType: .resistor,
                    explanation: "I = V/R = 5V / 1000Ω = 0.005A = 5mA. Converting between mA and A is a key skill!"
                ),
                Exercise(
                    type: .numericInput(correctValue: 100, unit: "Ω", tolerance: 0),
                    question: "You need 50mA of current from a 5V source. What resistance do you need? (in Ω)",
                    hint: "R = V / I. Convert mA to A first.",
                    sceneType: nil,
                    explanation: "R = V/I = 5V / 0.05A = 100Ω. Always convert milliamps to amps before using Ohm's Law."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "I = ___ / ___",
                        tokens: ["V", "R", "P", "I"],
                        correctOrder: ["V", "R"]
                    ),
                    question: "Rearrange Ohm's Law to find current:",
                    hint: "Divide voltage by resistance.",
                    sceneType: nil,
                    explanation: "I = V / R. If you know the voltage and resistance, divide to find the current."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Current doubles", isImage: false),
                            AnswerOption(text: "Current halves", isImage: false),
                            AnswerOption(text: "Current stays the same", isImage: false),
                            AnswerOption(text: "The circuit explodes", isImage: false)
                        ],
                        correctIndex: 1
                    ),
                    question: "If you double the resistance in a circuit (same voltage), what happens to current?",
                    hint: "I = V / R — what happens when R gets bigger?",
                    sceneType: nil,
                    explanation: "Current halves! Since I = V/R, doubling R means the current is divided by 2."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 2 — Series vs Parallel
    // ──────────────────────────────────────────────
    static let unit2 = CourseUnit(
        number: 2,
        title: "Circuit Types",
        subtitle: "Series & parallel circuits",
        icon: "point.3.connected.trianglepath.dotted",
        color: Color("AccentBlue"),
        lessons: [
            Lesson(title: "Series Circuits", icon: "arrow.right", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Components are on a single path", isImage: false),
                            AnswerOption(text: "Components are on multiple paths", isImage: false),
                            AnswerOption(text: "Components have no connections", isImage: false),
                            AnswerOption(text: "There is no battery", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What defines a series circuit?",
                    hint: "Think of a single lane road.",
                    sceneType: .seriesCircuit,
                    explanation: "In a series circuit, all components share a single path. Current flows through each one in order."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "R_total = R₁ ___ R₂",
                        tokens: ["+", "−", "×", "÷"],
                        correctOrder: ["+"]
                    ),
                    question: "In a series circuit, how do you find total resistance?",
                    hint: "Resistances stack up.",
                    sceneType: nil,
                    explanation: "In series, total resistance is the sum: R_total = R₁ + R₂ + R₃... Resistance adds up!"
                ),
                Exercise(
                    type: .numericInput(correctValue: 300, unit: "Ω", tolerance: 0),
                    question: "Three 100Ω resistors in series. Total resistance?",
                    hint: "Just add them up!",
                    sceneType: .seriesCircuit,
                    explanation: "100Ω + 100Ω + 100Ω = 300Ω. In series, resistances simply add together."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The other lights go out too", isImage: false),
                            AnswerOption(text: "The other lights get brighter", isImage: false),
                            AnswerOption(text: "Nothing happens to the others", isImage: false),
                            AnswerOption(text: "The battery charges up", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "In a series circuit with 3 lights, one burns out. What happens?",
                    hint: "There's only one path for current...",
                    sceneType: nil,
                    explanation: "All lights go out! In series, if one component breaks, the entire circuit is broken — no current can flow."
                ),
                Exercise(
                    type: .numericInput(correctValue: 3, unit: "V", tolerance: 0),
                    question: "Two 1.5V batteries in series. Total voltage?",
                    hint: "Voltages add in series.",
                    sceneType: .battery,
                    explanation: "1.5V + 1.5V = 3V. In series, voltages add together. That's how flashlights get more voltage from multiple batteries."
                )
            ]),

            Lesson(title: "Parallel Circuits", icon: "arrow.triangle.branch", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Components share the same two nodes", isImage: false),
                            AnswerOption(text: "Components are in a line", isImage: false),
                            AnswerOption(text: "There's only one wire", isImage: false),
                            AnswerOption(text: "The battery is in the middle", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What defines a parallel circuit?",
                    hint: "Multiple paths, like lanes on a highway.",
                    sceneType: .parallelCircuit,
                    explanation: "In parallel, components share the same two connection points. Each has its own path for current."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The same across all branches", isImage: false),
                            AnswerOption(text: "Different in each branch", isImage: false),
                            AnswerOption(text: "Zero", isImage: false),
                            AnswerOption(text: "Double in each branch", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "In a parallel circuit, the voltage across each branch is...",
                    hint: "All branches connect to the same two nodes.",
                    sceneType: .parallelCircuit,
                    explanation: "Voltage is the same across all parallel branches! They share the same two connection points."
                ),
                Exercise(
                    type: .numericInput(correctValue: 50, unit: "Ω", tolerance: 0),
                    question: "Two 100Ω resistors in parallel. Total resistance? (in Ω)",
                    hint: "1/R_total = 1/R₁ + 1/R₂",
                    sceneType: nil,
                    explanation: "1/R = 1/100 + 1/100 = 2/100 → R = 50Ω. Parallel resistance is always LESS than the smallest resistor!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The others stay on", isImage: false),
                            AnswerOption(text: "All go out", isImage: false),
                            AnswerOption(text: "They all get dimmer", isImage: false),
                            AnswerOption(text: "The battery stops", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "In a parallel circuit with 3 lights, one burns out. What happens?",
                    hint: "Each light has its own path.",
                    sceneType: nil,
                    explanation: "The others stay on! Each branch is independent. This is why houses use parallel wiring."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Connecting a wire directly across a battery's terminals with no load (short circuit)."),
                    question: "Safe or Unsafe?",
                    hint: "What's the resistance of a plain wire?",
                    sceneType: nil,
                    explanation: "Extremely unsafe! This is a short circuit. With nearly zero resistance, massive current flows, causing heat, fire, or explosion."
                )
            ]),

            Lesson(title: "Series vs Parallel Quiz", icon: "questionmark.diamond", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Series", isImage: false),
                            AnswerOption(text: "Parallel", isImage: false),
                            AnswerOption(text: "Both", isImage: false),
                            AnswerOption(text: "Neither", isImage: false)
                        ],
                        correctIndex: 1
                    ),
                    question: "Your house wiring is mostly which type?",
                    hint: "If one light goes out, do all your lights go out?",
                    sceneType: nil,
                    explanation: "Parallel! Each outlet and light switch operates independently. If one breaks, the rest keep working."
                ),
                Exercise(
                    type: .diagramLabel(labels: [
                        DiagramLabel(componentName: "Battery", position: CGPoint(x: 0.15, y: 0.5), symbol: "battery.100"),
                        DiagramLabel(componentName: "Resistor", position: CGPoint(x: 0.5, y: 0.2), symbol: "equal.circle"),
                        DiagramLabel(componentName: "LED", position: CGPoint(x: 0.85, y: 0.5), symbol: "lightbulb"),
                        DiagramLabel(componentName: "Ground", position: CGPoint(x: 0.5, y: 0.85), symbol: "arrow.down.to.line")
                    ]),
                    question: "Tap each component to identify it:",
                    hint: "Match the symbol to its name.",
                    sceneType: .circuit,
                    explanation: "Every circuit has a power source (battery), components (resistor, LED), and a return path (ground)."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Series: same ___ everywhere. Parallel: same ___ everywhere.",
                        tokens: ["current", "voltage", "resistance", "power"],
                        correctOrder: ["current", "voltage"]
                    ),
                    question: "Complete the key rule:",
                    hint: "What's constant in each circuit type?",
                    sceneType: nil,
                    explanation: "Series circuits have the same current through all components. Parallel circuits have the same voltage across all branches."
                ),
                Exercise(
                    type: .numericInput(correctValue: 150, unit: "Ω", tolerance: 0),
                    question: "100Ω and 50Ω resistors in series. Total?",
                    hint: "In series, just add.",
                    sceneType: nil,
                    explanation: "100 + 50 = 150Ω. Series resistance is always the sum."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Total R goes down", isImage: false),
                            AnswerOption(text: "Total R goes up", isImage: false),
                            AnswerOption(text: "Total R stays the same", isImage: false),
                            AnswerOption(text: "The circuit breaks", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Adding more resistors in parallel makes total resistance...",
                    hint: "More paths = easier for current to flow.",
                    sceneType: nil,
                    explanation: "Total resistance decreases! More parallel paths means less overall opposition to current flow."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 3 — Components
    // ──────────────────────────────────────────────
    static let unit3 = CourseUnit(
        number: 3,
        title: "Components",
        subtitle: "Resistors, capacitors, LEDs & diodes",
        icon: "cpu",
        color: Color("AccentOrange"),
        lessons: [
            Lesson(title: "Resistors", icon: "equal.circle.fill", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Color-coded bands", isImage: false),
                            AnswerOption(text: "Their size", isImage: false),
                            AnswerOption(text: "Their weight", isImage: false),
                            AnswerOption(text: "They're all the same", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "How do you read a resistor's value?",
                    hint: "Look at the colored stripes.",
                    sceneType: .resistor,
                    explanation: "Resistors use color-coded bands. Each color represents a number. The color code is: Black=0, Brown=1, Red=2, Orange=3, Yellow=4, Green=5, Blue=6, Violet=7, Grey=8, White=9."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Brown, Black, Red = ___Ω",
                        tokens: ["1kΩ", "10kΩ", "100Ω", "10Ω"],
                        correctOrder: ["1kΩ"]
                    ),
                    question: "Read this resistor color code:",
                    hint: "Brown=1, Black=0, Red=×100",
                    sceneType: .resistor,
                    explanation: "Brown(1), Black(0) → 10, then Red(×100) → 10 × 100 = 1000Ω = 1kΩ."
                ),
                Exercise(
                    type: .numericInput(correctValue: 220, unit: "Ω", tolerance: 0),
                    question: "Red, Red, Brown resistor. Value in Ω?",
                    hint: "Red=2, Brown=×10",
                    sceneType: .resistor,
                    explanation: "Red(2), Red(2) → 22, Brown(×10) → 22 × 10 = 220Ω. A very common resistor for LEDs!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "It's rated power in watts", isImage: false),
                            AnswerOption(text: "Its color", isImage: false),
                            AnswerOption(text: "Its brand", isImage: false),
                            AnswerOption(text: "Nothing matters beyond resistance", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Besides resistance, what else matters when choosing a resistor?",
                    hint: "Resistors turn electrical energy into heat.",
                    sceneType: nil,
                    explanation: "Power rating (watts)! A resistor that dissipates more power than it's rated for will overheat and fail."
                ),
                Exercise(
                    type: .numericInput(correctValue: 150, unit: "Ω", tolerance: 10),
                    question: "You want to drive a red LED (2V drop, 20mA) from 5V. What resistor? (in Ω)",
                    hint: "R = (V_supply − V_LED) / I_LED",
                    sceneType: .led,
                    explanation: "R = (5V − 2V) / 0.020A = 3V / 0.020A = 150Ω. This is the most common LED circuit calculation!"
                )
            ]),

            Lesson(title: "Capacitors", icon: "battery.25", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Store electrical energy in an electric field", isImage: false),
                            AnswerOption(text: "Generate electricity", isImage: false),
                            AnswerOption(text: "Block DC current permanently", isImage: false),
                            AnswerOption(text: "Increase voltage", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What does a capacitor do?",
                    hint: "Think of it like a tiny rechargeable bucket.",
                    sceneType: .capacitor,
                    explanation: "Capacitors store energy in an electric field between two plates. They charge up and release energy quickly."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Capacitance is measured in ___",
                        tokens: ["Ohms", "Farads", "Henrys", "Volts"],
                        correctOrder: ["Farads"]
                    ),
                    question: "Fill in the unit:",
                    hint: "Named after Michael Faraday.",
                    sceneType: nil,
                    explanation: "Capacitance is measured in Farads (F). Most real capacitors are in µF (microfarads) or pF (picofarads)."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Smoothing power supply ripple", isImage: false),
                            AnswerOption(text: "Replacing batteries", isImage: false),
                            AnswerOption(text: "Making circuits louder", isImage: false),
                            AnswerOption(text: "Changing colors of LEDs", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What's a common use for capacitors in circuits?",
                    hint: "Power supplies aren't perfectly smooth.",
                    sceneType: .capacitor,
                    explanation: "Capacitors smooth out voltage fluctuations. They're called 'decoupling' or 'bypass' capacitors and are everywhere in electronics."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Discharging a large capacitor from a camera flash by shorting its leads with a screwdriver."),
                    question: "Safe or Unsafe?",
                    hint: "Large capacitors store a LOT of energy.",
                    sceneType: nil,
                    explanation: "Unsafe! Large caps can hold hundreds of volts. Short-circuiting them causes sparks, can weld tools, and damage components. Use a discharge resistor."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Yes — polarity matters", isImage: false),
                            AnswerOption(text: "No — they work either way", isImage: false),
                            AnswerOption(text: "Only ceramic ones", isImage: false),
                            AnswerOption(text: "Only at high voltage", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Do electrolytic capacitors have a + and − side?",
                    hint: "There's usually a stripe marking one side.",
                    sceneType: .capacitor,
                    explanation: "Yes! Electrolytic caps are polarized. Reversing polarity can make them fail violently (bulge or pop). The stripe marks the negative side."
                )
            ]),

            Lesson(title: "LEDs & Diodes", icon: "lightbulb.fill", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Current flows in only one direction", isImage: false),
                            AnswerOption(text: "Current flows both ways", isImage: false),
                            AnswerOption(text: "Current is blocked completely", isImage: false),
                            AnswerOption(text: "Voltage is increased", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is the key property of a diode?",
                    hint: "It's like a one-way valve.",
                    sceneType: .diode,
                    explanation: "A diode is a one-way valve for electricity. Current flows from anode (+) to cathode (−) only."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "LED stands for Light ___ Diode",
                        tokens: ["Emitting", "Electric", "Energy", "Enabled"],
                        correctOrder: ["Emitting"]
                    ),
                    question: "What does LED stand for?",
                    hint: "It makes light!",
                    sceneType: .led,
                    explanation: "LED = Light Emitting Diode. It's a special diode that produces light when current flows through it."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "The longer leg is positive (anode)", isImage: false),
                            AnswerOption(text: "The longer leg is negative", isImage: false),
                            AnswerOption(text: "Both legs are the same", isImage: false),
                            AnswerOption(text: "The flat side is positive", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "How do you tell which LED leg is positive?",
                    hint: "Longer = more positive.",
                    sceneType: .led,
                    explanation: "The longer leg is the anode (+). The shorter leg is the cathode (−). Also, the flat side of the LED body marks the cathode."
                ),
                Exercise(
                    type: .numericInput(correctValue: 2, unit: "V", tolerance: 0.2),
                    question: "A typical red LED has a forward voltage drop of about how many volts?",
                    hint: "It's a small number, less than 3.",
                    sceneType: .led,
                    explanation: "Red LEDs drop about 1.8–2.2V. Blue and white LEDs drop more (3–3.5V). This 'forward voltage' is key for calculating resistor values."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Connecting an LED directly to a 9V battery with no resistor."),
                    question: "Safe or Unsafe?",
                    hint: "LEDs need current limiting.",
                    sceneType: nil,
                    explanation: "Unsafe! Without a resistor, too much current flows and the LED burns out instantly. Always use a current-limiting resistor."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 3B — Flashcard Recall: Components
    // ──────────────────────────────────────────────
    static let unit3b = CourseUnit(
        number: 3,
        title: "Recall: Components",
        subtitle: "Flashcard practice — identify parts",
        icon: "rectangle.on.rectangle.angled",
        color: Color(hex: "F59E0B"),
        lessons: [
            Lesson(title: "Name That Component", icon: "cpu", exercises: [
                Exercise(
                    type: .flashcard(front: "Two leads, color bands, limits current", back: "Resistor — opposes the flow of current. Value read from color bands.", frontIcon: "equal.circle"),
                    question: "Name this component:",
                    hint: nil, sceneType: .resistor,
                    explanation: "Resistors limit current flow. Their value is shown by colored bands."
                ),
                Exercise(
                    type: .flashcard(front: "Two plates, stores charge, measured in Farads", back: "Capacitor — stores and releases electrical energy. Used for filtering and smoothing.", frontIcon: "battery.25"),
                    question: "Name this component:",
                    hint: nil, sceneType: .capacitor,
                    explanation: "Capacitors store charge. Electrolytic caps are polarized (+ and − sides)."
                ),
                Exercise(
                    type: .flashcard(front: "Emits light, has anode (+) and cathode (−), needs current limiting", back: "LED — Light Emitting Diode. Always use with a resistor!", frontIcon: "lightbulb"),
                    question: "Name this component:",
                    hint: nil, sceneType: .led,
                    explanation: "LEDs emit light when current flows through them. The longer leg is positive."
                ),
                Exercise(
                    type: .flashcard(front: "One-way valve for electricity, has a cathode band", back: "Diode — allows current in one direction only. Used for protection and rectification.", frontIcon: "arrow.right"),
                    question: "Name this component:",
                    hint: nil, sceneType: .diode,
                    explanation: "Diodes are one-way valves. Current flows from anode to cathode."
                ),
                Exercise(
                    type: .flashcard(front: "Brown, Black, Red, Gold resistor", back: "1kΩ ±5%\nBrown=1, Black=0, Red=×100, Gold=±5%\n10 × 100 = 1000Ω = 1kΩ", frontIcon: "number"),
                    question: "Read this resistor:",
                    hint: nil, sceneType: .resistor,
                    explanation: "Brown-Black-Red-Gold = 1kΩ with 5% tolerance."
                ),
                Exercise(
                    type: .numericInput(correctValue: 330, unit: "Ω", tolerance: 0),
                    question: "Orange, Orange, Brown resistor. Value?",
                    hint: "Orange=3, Brown=×10",
                    sceneType: .resistor,
                    explanation: "Orange(3), Orange(3) → 33, Brown(×10) → 330Ω."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Resistor", isImage: false),
                            AnswerOption(text: "Capacitor", isImage: false),
                            AnswerOption(text: "Inductor", isImage: false),
                            AnswerOption(text: "Transistor", isImage: false)
                        ],
                        correctIndex: 1
                    ),
                    question: "Which component is polarized and can explode if inserted backwards?",
                    hint: "Electrolytic ones have a + and − side.",
                    sceneType: .capacitor,
                    explanation: "Electrolytic capacitors are polarized. Reversing polarity can cause them to fail violently."
                ),
                Exercise(
                    type: .numericInput(correctValue: 220, unit: "Ω", tolerance: 10),
                    question: "Calculate: LED resistor for 3.3V supply, 2V LED, 6mA current.",
                    hint: "R = (Vsupply − VLED) / I",
                    sceneType: nil,
                    explanation: "R = (3.3 − 2) / 0.006 = 1.3/0.006 ≈ 217Ω → use 220Ω (nearest standard value)."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 4 — Digital Basics
    // ──────────────────────────────────────────────
    static let unit4 = CourseUnit(
        number: 4,
        title: "Going Digital",
        subtitle: "Logic levels, GPIO & pull resistors",
        icon: "01.square",
        color: Color("AccentPurple"),
        lessons: [
            Lesson(title: "Logic Levels", icon: "switch.2", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "HIGH (1) and LOW (0)", isImage: false),
                            AnswerOption(text: "Fast and Slow", isImage: false),
                            AnswerOption(text: "Red and Blue", isImage: false),
                            AnswerOption(text: "AC and DC", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Digital circuits use which two states?",
                    hint: "Binary: on or off.",
                    sceneType: nil,
                    explanation: "Digital electronics work with two states: HIGH (1, usually ~3.3V or 5V) and LOW (0, usually ~0V)."
                ),
                Exercise(
                    type: .numericInput(correctValue: 5, unit: "V", tolerance: 0),
                    question: "A classic Arduino Uno uses ___V logic levels.",
                    hint: "The most classic logic voltage.",
                    sceneType: .arduino,
                    explanation: "Arduino Uno uses 5V logic. HIGH = ~5V, LOW = ~0V. Many modern boards use 3.3V logic instead."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "It's unpredictable (floating)", isImage: false),
                            AnswerOption(text: "It reads HIGH", isImage: false),
                            AnswerOption(text: "It reads LOW", isImage: false),
                            AnswerOption(text: "The board shuts off", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What happens if a digital input pin is connected to nothing?",
                    hint: "No defined voltage = no defined state.",
                    sceneType: nil,
                    explanation: "A floating pin picks up electrical noise and randomly reads HIGH or LOW. That's why we need pull-up or pull-down resistors!"
                ),
                Exercise(
                    type: .tapToFill(
                        template: "A pull-___ resistor connects the pin to ___",
                        tokens: ["up", "down", "VCC", "GND"],
                        correctOrder: ["up", "VCC"]
                    ),
                    question: "Complete the definition:",
                    hint: "Pull UP = connect to the high voltage.",
                    sceneType: nil,
                    explanation: "A pull-up resistor connects the pin to VCC (supply voltage) through a resistor, giving it a default HIGH state."
                ),
                Exercise(
                    type: .numericInput(correctValue: 10, unit: "kΩ", tolerance: 0),
                    question: "The most common pull-up/pull-down resistor value is ___ kΩ.",
                    hint: "A nice round number.",
                    sceneType: nil,
                    explanation: "10kΩ is the standard pull-up/pull-down value. It's high enough to limit current but low enough to give a clean logic level."
                )
            ]),

            Lesson(title: "GPIO Pins", icon: "rectangle.connected.to.line.below", exercises: [
                Exercise(
                    type: .tapToFill(
                        template: "GPIO stands for General Purpose ___ / ___",
                        tokens: ["Input", "Output", "Internal", "Optical"],
                        correctOrder: ["Input", "Output"]
                    ),
                    question: "What does GPIO stand for?",
                    hint: "They can read or send signals.",
                    sceneType: .arduino,
                    explanation: "GPIO = General Purpose Input/Output. These pins can be configured to either read signals (input) or send signals (output)."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Read a button press", isImage: false),
                            AnswerOption(text: "Display video", isImage: false),
                            AnswerOption(text: "Connect to WiFi", isImage: false),
                            AnswerOption(text: "Charge a battery", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "A GPIO pin set as INPUT can:",
                    hint: "Input = reading something.",
                    sceneType: nil,
                    explanation: "As input, a GPIO pin reads whether it's seeing HIGH or LOW voltage — perfect for buttons, sensors, and switches."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Turn on an LED", isImage: false),
                            AnswerOption(text: "Read a sensor", isImage: false),
                            AnswerOption(text: "Measure resistance", isImage: false),
                            AnswerOption(text: "Store data", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "A GPIO pin set as OUTPUT can:",
                    hint: "Output = sending a signal.",
                    sceneType: nil,
                    explanation: "As output, a GPIO pin drives HIGH or LOW voltage — turning LEDs on/off, triggering relays, sending data signals."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Connecting a motor directly to an Arduino GPIO pin without a driver circuit."),
                    question: "Safe or Unsafe?",
                    hint: "GPIO pins can only supply small amounts of current.",
                    sceneType: nil,
                    explanation: "Unsafe! Arduino pins output max ~40mA. Motors need much more and create voltage spikes. Use a transistor or motor driver IC."
                ),
                Exercise(
                    type: .numericInput(correctValue: 40, unit: "mA", tolerance: 0),
                    question: "An Arduino Uno GPIO pin can source a maximum of about ___ mA.",
                    hint: "It's a small number, enough for an LED but not a motor.",
                    sceneType: .arduino,
                    explanation: "About 40mA max per pin (20mA recommended). Exceeding this can damage the microcontroller permanently."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 5 — Microcontrollers / Arduino
    // ──────────────────────────────────────────────
    static let unit5 = CourseUnit(
        number: 5,
        title: "Arduino Basics",
        subtitle: "Your first microcontroller",
        icon: "cpu",
        color: Color("AccentTeal"),
        lessons: [
            Lesson(title: "Meet the Arduino", icon: "rectangle.and.pencil.and.ellipsis", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "A small computer on a single board", isImage: false),
                            AnswerOption(text: "A type of battery", isImage: false),
                            AnswerOption(text: "A programming language", isImage: false),
                            AnswerOption(text: "A brand of LEDs", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is an Arduino?",
                    hint: "It's a board with a chip on it.",
                    sceneType: .arduino,
                    explanation: "An Arduino is a microcontroller board — a tiny computer that can read sensors, make decisions, and control outputs like LEDs and motors."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Arduino programs have two main functions: ___() and ___()",
                        tokens: ["setup", "loop", "main", "start"],
                        correctOrder: ["setup", "loop"]
                    ),
                    question: "Name the two required Arduino functions:",
                    hint: "One runs once, one runs forever.",
                    sceneType: nil,
                    explanation: "setup() runs once when the board powers on. loop() runs over and over forever. All Arduino programs use this structure."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "14 digital + 6 analog", isImage: false),
                            AnswerOption(text: "8 digital only", isImage: false),
                            AnswerOption(text: "100 pins", isImage: false),
                            AnswerOption(text: "2 pins total", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "How many I/O pins does an Arduino Uno have?",
                    hint: "It has both digital and analog pins.",
                    sceneType: .arduino,
                    explanation: "Arduino Uno has 14 digital pins (6 support PWM) and 6 analog input pins. That's enough for many beginner projects!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "A solderless board for prototyping circuits", isImage: false),
                            AnswerOption(text: "A type of sandwich", isImage: false),
                            AnswerOption(text: "A permanent circuit board", isImage: false),
                            AnswerOption(text: "A battery holder", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is a breadboard?",
                    hint: "You plug components in without soldering.",
                    sceneType: .breadboard,
                    explanation: "A breadboard lets you build circuits by plugging in components and wires — no soldering needed. Perfect for experimenting!"
                ),
                Exercise(
                    type: .safetyScenario(isSafe: true, scenarioDescription: "Powering an Arduino Uno through its USB cable connected to a laptop."),
                    question: "Safe or Unsafe?",
                    hint: "USB provides regulated 5V.",
                    sceneType: nil,
                    explanation: "Perfectly safe! USB provides regulated 5V at limited current. This is the standard way to power and program an Arduino."
                )
            ]),

            Lesson(title: "Your First Circuit", icon: "lightbulb.fill", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Blink an LED", isImage: false),
                            AnswerOption(text: "Build a robot", isImage: false),
                            AnswerOption(text: "Connect to the internet", isImage: false),
                            AnswerOption(text: "Play music", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What's the classic first Arduino project?",
                    hint: "The 'Hello World' of hardware.",
                    sceneType: .led,
                    explanation: "Blink! Making an LED turn on and off is the 'Hello World' of Arduino. It teaches digital output, timing, and basic wiring."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "digitalWrite(13, ___); delay(___);",
                        tokens: ["HIGH", "LOW", "1000", "0"],
                        correctOrder: ["HIGH", "1000"]
                    ),
                    question: "Complete the code to turn on an LED for 1 second:",
                    hint: "HIGH turns on, delay is in milliseconds.",
                    sceneType: nil,
                    explanation: "digitalWrite(13, HIGH) turns pin 13 on. delay(1000) waits 1000 milliseconds (1 second)."
                ),
                Exercise(
                    type: .numericInput(correctValue: 13, unit: "", tolerance: 0),
                    question: "Which Arduino Uno pin has a built-in LED?",
                    hint: "It's the highest numbered digital pin used for this.",
                    sceneType: .arduino,
                    explanation: "Pin 13 has a built-in LED on the Arduino Uno board. You can blink it without connecting any external components!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "It smoothly dims or brightens", isImage: false),
                            AnswerOption(text: "It changes color", isImage: false),
                            AnswerOption(text: "It turns off forever", isImage: false),
                            AnswerOption(text: "Nothing happens", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What does analogWrite() do to an LED?",
                    hint: "PWM = Pulse Width Modulation.",
                    sceneType: .led,
                    explanation: "analogWrite() uses PWM to simulate analog output. Values 0–255 control brightness: 0 = off, 255 = full brightness."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "analogWrite(pin, ___) is full brightness",
                        tokens: ["255", "100", "1024", "HIGH"],
                        correctOrder: ["255"]
                    ),
                    question: "What value gives maximum PWM output?",
                    hint: "8-bit resolution: 0 to ???",
                    sceneType: nil,
                    explanation: "255 is the max for analogWrite(). It's 8-bit resolution: 2⁸ = 256 levels (0–255)."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 6 — Safety & Real‑World
    // ──────────────────────────────────────────────
    static let unit6 = CourseUnit(
        number: 6,
        title: "Real World",
        subtitle: "Safety, mains power & fuses",
        icon: "shield.checkered",
        color: Color("AccentRed"),
        lessons: [
            Lesson(title: "Mains vs Low Voltage", icon: "bolt.trianglebadge.exclamationmark", exercises: [
                Exercise(
                    type: .numericInput(correctValue: 120, unit: "V", tolerance: 0),
                    question: "US household mains voltage is ___ V AC.",
                    hint: "Between 100 and 130.",
                    sceneType: nil,
                    explanation: "US mains is 120V AC (60Hz). Europe uses 230V AC (50Hz). Both are extremely dangerous!"
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Opening up a mains-powered device while it's still plugged into the wall."),
                    question: "Safe or Unsafe?",
                    hint: "Is it still connected to 120V?",
                    sceneType: nil,
                    explanation: "Extremely unsafe! Always unplug devices before opening them. Mains voltage (120V+) can kill. Capacitors inside may still hold charge even after unplugging."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "AC changes direction, DC flows one way", isImage: false),
                            AnswerOption(text: "AC is safer than DC", isImage: false),
                            AnswerOption(text: "DC is only in batteries", isImage: false),
                            AnswerOption(text: "They're the same thing", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What's the difference between AC and DC?",
                    hint: "One alternates, one is direct.",
                    sceneType: nil,
                    explanation: "AC (Alternating Current) reverses direction many times per second. DC (Direct Current) flows one direction. Batteries = DC, wall outlets = AC."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Use a DC power adapter/supply", isImage: false),
                            AnswerOption(text: "Connect Arduino directly to mains", isImage: false),
                            AnswerOption(text: "Use a longer USB cable", isImage: false),
                            AnswerOption(text: "Add more batteries", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "How should you power a project that needs mains electricity?",
                    hint: "Convert high voltage to low voltage safely.",
                    sceneType: nil,
                    explanation: "Use an approved DC power adapter (like a phone charger or laptop brick). Never wire your Arduino directly to mains power!"
                ),
                Exercise(
                    type: .safetyScenario(isSafe: true, scenarioDescription: "Using a UL-listed 5V USB phone charger to power your Arduino project permanently."),
                    question: "Safe or Unsafe?",
                    hint: "UL-listed means it's been safety tested.",
                    sceneType: nil,
                    explanation: "Safe! A certified power adapter handles the dangerous AC-to-DC conversion inside a sealed enclosure. This is the right approach."
                )
            ]),

            Lesson(title: "Fuses & Protection", icon: "exclamationmark.shield", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "A sacrificial wire that melts to break the circuit", isImage: false),
                            AnswerOption(text: "A device that makes circuits faster", isImage: false),
                            AnswerOption(text: "A type of resistor", isImage: false),
                            AnswerOption(text: "An alternative to a battery", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is a fuse?",
                    hint: "It protects by breaking.",
                    sceneType: .fuseBox,
                    explanation: "A fuse contains a thin wire that melts (blows) when too much current flows, breaking the circuit before damage occurs."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Diagnose WHY it blew, then replace", isImage: false),
                            AnswerOption(text: "Replace it with a higher-rated fuse", isImage: false),
                            AnswerOption(text: "Wrap it in aluminum foil", isImage: false),
                            AnswerOption(text: "Ignore it", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "A fuse blows repeatedly. What should you do?",
                    hint: "The fuse is a symptom, not the problem.",
                    sceneType: nil,
                    explanation: "Find the root cause! A blown fuse means something is drawing too much current. Using a bigger fuse removes the protection and risks fire."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "A circuit breaker is a ___ fuse",
                        tokens: ["resettable", "permanent", "smaller", "faster"],
                        correctOrder: ["resettable"]
                    ),
                    question: "How is a circuit breaker different from a fuse?",
                    hint: "You flip it back on instead of replacing it.",
                    sceneType: .fuseBox,
                    explanation: "A circuit breaker trips when current is too high but can be reset. A fuse must be physically replaced. Modern homes use breakers."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Replacing a 10A fuse with a 30A fuse because the 10A keeps blowing."),
                    question: "Safe or Unsafe?",
                    hint: "Why does the 10A keep blowing?",
                    sceneType: nil,
                    explanation: "Extremely unsafe! The fuse is correctly protecting the circuit. A 30A fuse would let dangerous amounts of current flow, causing overheating and possible fire."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "It detects current imbalance and cuts power instantly", isImage: false),
                            AnswerOption(text: "It makes the circuit run faster", isImage: false),
                            AnswerOption(text: "It stores extra electricity", isImage: false),
                            AnswerOption(text: "It measures voltage", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What does a GFCI outlet do?",
                    hint: "It protects against electric shock.",
                    sceneType: nil,
                    explanation: "A GFCI (Ground Fault Circuit Interrupter) detects if current is leaking (e.g., through your body to ground) and shuts off in milliseconds. Required in bathrooms and kitchens."
                )
            ]),

            Lesson(title: "Using a Multimeter", icon: "gauge.with.dots.needle.33percent", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Measure voltage, current, and resistance", isImage: false),
                            AnswerOption(text: "Generate electricity", isImage: false),
                            AnswerOption(text: "Solder components", isImage: false),
                            AnswerOption(text: "Program microcontrollers", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What does a multimeter do?",
                    hint: "Multi = many, meter = measure.",
                    sceneType: .multimeter,
                    explanation: "A multimeter measures voltage (V), current (A), and resistance (Ω). It's the most essential tool in electronics."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "To measure voltage, connect the meter in ___. To measure current, connect in ___.",
                        tokens: ["parallel", "series", "ground", "power"],
                        correctOrder: ["parallel", "series"]
                    ),
                    question: "How do you connect a multimeter?",
                    hint: "Voltage is across, current is through.",
                    sceneType: .multimeter,
                    explanation: "Voltage: meter in parallel (across the component). Current: meter in series (current flows through the meter). Getting this wrong can blow the meter's fuse!"
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Check if there's a low-resistance path (short circuit)", isImage: false),
                            AnswerOption(text: "Measure how loud a component is", isImage: false),
                            AnswerOption(text: "Test battery charge level", isImage: false),
                            AnswerOption(text: "Measure temperature", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "What is continuity mode used for?",
                    hint: "It beeps when there's a connection.",
                    sceneType: .multimeter,
                    explanation: "Continuity mode beeps when there's a low-resistance path. Great for checking if wires are connected or if traces on a PCB are intact."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Measuring current on a mains outlet by putting the multimeter probes into the wall socket in current mode."),
                    question: "Safe or Unsafe?",
                    hint: "Current mode has very low resistance.",
                    sceneType: nil,
                    explanation: "Extremely dangerous! In current mode, the meter has nearly zero resistance. Connecting to mains creates a short circuit — potentially causing an arc flash, fire, or death."
                ),
                Exercise(
                    type: .numericInput(correctValue: 4.7, unit: "kΩ", tolerance: 0.3),
                    question: "Your multimeter reads 4.7kΩ across a resistor. Is this close to a standard value? What is it?",
                    hint: "Standard values include 4.7kΩ.",
                    sceneType: nil,
                    explanation: "4.7kΩ is a standard E12 series value. Common resistor values follow the E12 series: 1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 3.9, 4.7, 5.6, 6.8, 8.2 (×10ⁿ)."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 7 — Troubleshooting Lab
    // ──────────────────────────────────────────────
    static let unit7 = CourseUnit(
        number: 7,
        title: "Troubleshooting Lab",
        subtitle: "Find faults and fix circuits",
        icon: "wrench.and.screwdriver",
        color: Color(hex: "0EA5E9"),
        lessons: [
            Lesson(title: "Broken LED Circuit", icon: "lightbulb.slash", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "LED reversed polarity", isImage: false),
                            AnswerOption(text: "Battery too fresh", isImage: false),
                            AnswerOption(text: "Wire is too short", isImage: false),
                            AnswerOption(text: "Resistor is too colorful", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "The LED does not light. Which is the most likely mistake first?",
                    hint: "Start with polarity and power path.",
                    sceneType: .led,
                    explanation: "First check LED orientation. A reversed LED blocks current and will not light."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "No light + battery good -> check ___, then ___",
                        tokens: ["polarity", "connections", "paint color", "weather"],
                        correctOrder: ["polarity", "connections"]
                    ),
                    question: "Complete a fast debug checklist:",
                    hint: "Think in order: direction then continuity.",
                    sceneType: nil,
                    explanation: "A practical debug order saves time: verify polarity, then wiring continuity."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: false, scenarioDescription: "Holding both meter probes with bare fingers while checking a live mains circuit."),
                    question: "Safe or Unsafe?",
                    hint: "You become part of the circuit.",
                    sceneType: .multimeter,
                    explanation: "Unsafe. Never handle probes like this on live mains. Use one-hand safety habits and insulated handling."
                ),
                Exercise(
                    type: .numericInput(correctValue: 3, unit: "V", tolerance: 0.2),
                    question: "Supply is 5V and LED drop is 2V. What voltage should be across the resistor?",
                    hint: "The resistor takes what's left.",
                    sceneType: .circuit,
                    explanation: "V_resistor = 5V - 2V = 3V."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Measure voltage at each node step-by-step", isImage: false),
                            AnswerOption(text: "Replace everything randomly", isImage: false),
                            AnswerOption(text: "Shake the breadboard", isImage: false),
                            AnswerOption(text: "Increase supply voltage immediately", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Best strategy for finding where a circuit fails?",
                    hint: "Trace the energy path.",
                    sceneType: .multimeter,
                    explanation: "Trace voltage node-by-node. The point where expected voltage disappears reveals the fault."
                )
            ]),
            Lesson(title: "Sensor Debug Patterns", icon: "dot.radiowaves.left.and.right", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Floating input pin", isImage: false),
                            AnswerOption(text: "Too many comments", isImage: false),
                            AnswerOption(text: "LED is green", isImage: false),
                            AnswerOption(text: "Breadboard is horizontal", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "A button input reads random values. Most likely cause?",
                    hint: "Undefined input state.",
                    sceneType: .arduino,
                    explanation: "A floating input picks up noise. Add pull-up or pull-down resistance."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "INPUT_PULLUP means default state is ___",
                        tokens: ["HIGH", "LOW", "random", "analog"],
                        correctOrder: ["HIGH"]
                    ),
                    question: "Fill in the rule:",
                    hint: "The resistor ties it to VCC.",
                    sceneType: nil,
                    explanation: "With INPUT_PULLUP enabled, unpressed state is HIGH."
                ),
                Exercise(
                    type: .numericInput(correctValue: 100, unit: "ms", tolerance: 25),
                    question: "Typical debounce delay for a button is about ___ ms.",
                    hint: "Think quick but stable.",
                    sceneType: nil,
                    explanation: "Around 50-100ms is common to remove mechanical bounce."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Use serial prints to observe live values", isImage: false),
                            AnswerOption(text: "Use a bigger battery only", isImage: false),
                            AnswerOption(text: "Remove all resistors", isImage: false),
                            AnswerOption(text: "Change wire colors", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "How do you debug unstable sensor readings in code?",
                    hint: "Observe before changing.",
                    sceneType: .arduino,
                    explanation: "Print raw values to serial first, then apply averaging or thresholds from real data."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: true, scenarioDescription: "Powering sensors from a known 5V rail and sharing common ground with the MCU."),
                    question: "Safe or Unsafe?",
                    hint: "Reference must be shared.",
                    sceneType: nil,
                    explanation: "Safe. Shared ground gives a common voltage reference so sensor data reads correctly."
                )
            ])
        ]
    )

    // ──────────────────────────────────────────────
    // UNIT 8 — Build Systems
    // ──────────────────────────────────────────────
    static let unit8 = CourseUnit(
        number: 8,
        title: "Build Systems",
        subtitle: "From parts to working projects",
        icon: "cube.box.fill",
        color: Color(hex: "14B8A6"),
        lessons: [
            Lesson(title: "Design a Mini Project", icon: "square.and.pencil", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Define inputs, logic, and outputs first", isImage: false),
                            AnswerOption(text: "Buy random parts first", isImage: false),
                            AnswerOption(text: "Start soldering immediately", isImage: false),
                            AnswerOption(text: "Skip power planning", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "First step in planning a hardware project?",
                    hint: "System thinking before wiring.",
                    sceneType: .arduino,
                    explanation: "Start with system blocks: inputs, processing logic, outputs, and power budget."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Sensor -> ___ -> Actuator",
                        tokens: ["microcontroller", "battery", "resistor color", "fuse box"],
                        correctOrder: ["microcontroller"]
                    ),
                    question: "Complete the core architecture:",
                    hint: "What makes decisions?",
                    sceneType: nil,
                    explanation: "Most embedded systems follow sense -> decide -> act."
                ),
                Exercise(
                    type: .numericInput(correctValue: 500, unit: "mA", tolerance: 60),
                    question: "A project needs 5V and 0.5A total. Required USB power current?",
                    hint: "Convert amps to milliamps.",
                    sceneType: nil,
                    explanation: "0.5A = 500mA. Choose a supply with at least that current, preferably with safety margin."
                ),
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "Prototype -> test -> refine in loops", isImage: false),
                            AnswerOption(text: "Design once and never test", isImage: false),
                            AnswerOption(text: "Only test at the end", isImage: false),
                            AnswerOption(text: "Avoid measuring anything", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Best build workflow for reliable projects?",
                    hint: "Iteration beats guessing.",
                    sceneType: .breadboard,
                    explanation: "Iterative loops reduce risk. Build small, test quickly, and refine."
                ),
                Exercise(
                    type: .flashcard(
                        front: "Project quality checklist",
                        back: "Power budget OK\nCommon ground shared\nInput states defined\nOutputs current-limited\nFailure mode considered",
                        frontIcon: "list.bullet.clipboard"
                    ),
                    question: "Recall before final wiring:",
                    hint: nil,
                    sceneType: nil,
                    explanation: "Reliable builds come from checklists, not memory."
                )
            ]),
            Lesson(title: "Failure Mode Thinking", icon: "exclamationmark.bubble", exercises: [
                Exercise(
                    type: .multipleChoice(
                        options: [
                            AnswerOption(text: "What happens if this part fails?", isImage: false),
                            AnswerOption(text: "Will this look cool on camera?", isImage: false),
                            AnswerOption(text: "Can I skip a resistor?", isImage: false),
                            AnswerOption(text: "Can I wire mains directly?", isImage: false)
                        ],
                        correctIndex: 0
                    ),
                    question: "Core reliability question during design?",
                    hint: "Think worst-case.",
                    sceneType: nil,
                    explanation: "Failure-mode thinking prevents damage and unsafe behavior."
                ),
                Exercise(
                    type: .tapToFill(
                        template: "Protect LED output with a ___ resistor",
                        tokens: ["series", "parallel", "huge", "virtual"],
                        correctOrder: ["series"]
                    ),
                    question: "Fill in the protection strategy:",
                    hint: "Current should pass through it.",
                    sceneType: .led,
                    explanation: "LEDs are protected with a series resistor to limit current."
                ),
                Exercise(
                    type: .numericInput(correctValue: 2, unit: "A", tolerance: 0),
                    question: "A fuse marked 2A should open near ___ amps.",
                    hint: "Read the label directly.",
                    sceneType: .fuseBox,
                    explanation: "Fuse current rating indicates approximate trip region for protection."
                ),
                Exercise(
                    type: .safetyScenario(isSafe: true, scenarioDescription: "Adding a fuse near the power input and strain relief on wires in a final enclosure."),
                    question: "Safe or Unsafe?",
                    hint: "Protect both electrical and mechanical paths.",
                    sceneType: nil,
                    explanation: "Safe. Input fusing and strain relief are practical reliability standards."
                ),
                Exercise(
                    type: .flashcard(
                        front: "Final mindset",
                        back: "Fast loops build skill.\nReliable systems build trust.",
                        frontIcon: "checkmark.shield"
                    ),
                    question: "What separates prototypes from products?",
                    hint: nil,
                    sceneType: nil,
                    explanation: "Product quality comes from repeatable systems, safety, and deliberate testing."
                )
            ])
        ]
    )
}
