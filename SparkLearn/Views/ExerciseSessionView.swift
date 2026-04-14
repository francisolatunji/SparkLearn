import SwiftUI

struct ExerciseSessionView: View {
    let lesson: Lesson
    let unitColor: Color
    @EnvironmentObject var progress: ProgressManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var sessionComplete = false
    @State private var xpEarned = 0
    @State private var combo = 0
    @State private var feedbackMood: MascotMood = .happy
    @State private var feedbackLine = "Let's build your streak."
    @State private var confettiTrigger = 0
    @State private var transitionPulse = false
    @State private var challengeIndices: Set<Int> = []
    @State private var boltRainTrigger = 0
    @State private var showOutOfHearts = false

    @State private var xpPopTrigger = 0
    @State private var showComboFire = false

    var body: some View {
        ZStack {
            DS.lessonBackground.ignoresSafeArea()

            // Combo fire effect - real-time ember particles when on a hot streak
            if showComboFire {
                EmberParticleView(
                    particleCount: 50,
                    baseColor: .orange,
                    secondaryColor: .yellow,
                    speed: 2.0
                )
                .opacity(0.3)
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            ConfettiBurstView(trigger: confettiTrigger)
                .allowsHitTesting(false)
            BoltRainView(trigger: boltRainTrigger)
                .allowsHitTesting(false)

            if sessionComplete {
                SessionCompleteView(
                    correctCount: correctCount,
                    totalCount: lesson.exercises.count,
                    xpEarned: xpEarned,
                    onDone: { dismiss() }
                )
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                VStack(spacing: 0) {
                    topBar
                    sessionCoachBar
                    exerciseContent
                        .id(currentIndex) // force fresh view per exercise
                }
                .transition(.opacity)
            }

            if showOutOfHearts {
                OutOfHeartsOverlay(
                    nextHeartDate: progress.nextHeartDate,
                    onExit: { dismiss() },
                    onRefill: {
                        progress.refillHearts()
                        showOutOfHearts = false
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.35), value: sessionComplete)
        .onAppear {
            progress.refreshHearts()
            progress.setLastOpenedLesson(lesson.id)
            configureChallenges()
            showOutOfHearts = !progress.canStartLesson
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: { Haptics.light(); dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.textTertiary)
                    .frame(width: 32, height: 32)
            }

            ProgressBar(
                progress: Double(currentIndex) / Double(lesson.exercises.count),
                color: unitColor,
                height: 10
            )

            // Hearts with glow when low
            ZStack {
                if progress.hearts <= 2 {
                    Circle()
                        .fill(.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                        .blur(radius: 6)
                }
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("\(progress.hearts)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .contentTransition(.numericText())
                }
            }

            // XP with PhaseAnimator pop
            ZStack {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                    Text("\(xpEarned)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText())
                }

                // Floating +XP pop
                XPPopView(xp: progress.xpPerCorrect, trigger: xpPopTrigger)
                    .offset(y: -24)
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.vertical, 12)
    }

    private var sessionCoachBar: some View {
        HStack(spacing: 10) {
            MascotView(size: 34, mood: feedbackMood, animate: true)
            Text(feedbackLine)
                .font(DS.captionFont)
                .foregroundStyle(DS.textSecondary)
                .lineLimit(1)
            Spacer()
            if challengeIndices.contains(currentIndex) {
                Text("Spark Challenge")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(DS.accent))
                    .pulseGlow(color: DS.accent, radius: 8)
            }
            if combo >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("x\(combo)")
                        .contentTransition(.numericText())
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.orange.opacity(0.12)))
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.bottom, 8)
    }

    private var exerciseContent: some View {
        ExerciseView(
            exercise: lesson.exercises[currentIndex],
            onAnswer: handleAnswer
        )
        .scaleEffect(transitionPulse ? 0.98 : 1)
        .opacity(transitionPulse ? 0.85 : 1)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(DS.transitionAnim, value: transitionPulse)
    }

    private func handleAnswer(correct: Bool) {
        guard progress.canStartLesson else {
            showOutOfHearts = true
            return
        }

        withAnimation(DS.tapAnim) { transitionPulse = true }
        SoundCue.tap()

        let comboBonus = progress.recordAnswer(correct: correct)
        let isChallenge = challengeIndices.contains(currentIndex)
        if correct {
            correctCount += 1
            combo = progress.currentCombo
            feedbackMood = combo >= 4 ? .celebrating : .happy
            feedbackLine = isChallenge
                ? "Sparky challenge cleared. Big win."
                : combo >= 4 ? "Hot streak. Keep it going." : "Nice hit. Next one."
            xpEarned += progress.xpPerCorrect + comboBonus + (isChallenge ? 12 : 0)
            xpPopTrigger += 1
            Haptics.success()
            SoundCue.success()

            // Show fire embers when combo is hot
            if combo >= 4 {
                withAnimation(.easeIn(duration: 0.3)) { showComboFire = true }
                SparkHaptics.shared.playStreakBuzz()
            }

            if [3, 5, 10].contains(combo) {
                confettiTrigger += 1
                SoundCue.streak()
                SparkHaptics.shared.playCelebration()
            }

            if isChallenge {
                confettiTrigger += 1
                boltRainTrigger += 1
                SparkHaptics.shared.playElectricShock()
            }
        } else {
            progress.loseHeart()
            combo = 0
            feedbackMood = .encouraging
            feedbackLine = isChallenge ? "Tough one. Sparky wants you to slow down and reset." : "Close. Think about current flow."
            withAnimation(.easeOut(duration: 0.3)) { showComboFire = false }
            Haptics.error()
            SoundCue.error()
            if !progress.canStartLesson {
                showOutOfHearts = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(DS.transitionAnim) {
                transitionPulse = false
                if showOutOfHearts {
                    return
                } else if currentIndex < lesson.exercises.count - 1 {
                    currentIndex += 1
                } else {
                    let perfect = correctCount == lesson.exercises.count
                    if perfect {
                        xpEarned += progress.xpBonusPerfect
                        confettiTrigger += 1
                        SoundCue.celebration()
                    }
                    let result = LessonResult(
                        lessonId: lesson.id,
                        correctCount: correctCount,
                        totalCount: lesson.exercises.count,
                        xpEarned: xpEarned,
                        perfectRun: perfect
                    )
                    progress.completeLesson(result)
                    Haptics.success()
                    if !perfect { SoundCue.success() }
                    progress.clearLastOpenedLesson()
                    sessionComplete = true
                }
            }
        }
    }

    private func configureChallenges() {
        guard challengeIndices.isEmpty else { return }
        let total = lesson.exercises.count
        let challengeCount = min(2, max(1, total / 4))
        challengeIndices = Set((0..<total).shuffled().prefix(challengeCount))
    }
}

// MARK: - Exercise View
struct ExerciseView: View {
    let exercise: Exercise
    let onAnswer: (Bool) -> Void

    @State private var answered = false
    @State private var wasCorrect = false
    @State private var feedbackAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 3D scene
                    if let sceneType = exercise.sceneType {
                        Scene3DView(sceneType: sceneType)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: DS.cornerRadius))
                            .padding(.horizontal, DS.padding)
                    }

                    // Question
                    Text(exercise.question)
                        .font(DS.titleFont)
                        .foregroundColor(DS.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.padding)

                    // Hint
                    if let hint = exercise.hint, !answered {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 12, weight: .medium))
                            Text(hint)
                                .font(DS.captionFont)
                        }
                        .foregroundColor(DS.warning)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(DS.warning.opacity(0.08)))
                    }

                    // Exercise UI
                    exerciseTypeView
                        .padding(.horizontal, DS.padding)
                }
                .padding(.top, 12)
                .padding(.bottom, 120) // space for feedback bar
            }

            Spacer(minLength: 0)

            // Feedback bar (slides up from bottom)
            if answered {
                feedbackBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .offset(y: feedbackAppeared ? 0 : 60)
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            feedbackAppeared = true
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: answered)
    }

    @ViewBuilder
    private var exerciseTypeView: some View {
        switch exercise.type {
        case .multipleChoice(let options, let correctIndex):
            MultipleChoiceView(
                options: options, correctIndex: correctIndex,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        case .tapToFill(let template, let tokens, let correctOrder):
            TapToFillView(
                template: template, tokens: tokens, correctOrder: correctOrder,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        case .numericInput(let correctValue, let unit, let tolerance):
            NumericInputView(
                correctValue: correctValue, unit: unit, tolerance: tolerance,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        case .diagramLabel(let labels):
            DiagramLabelView(
                labels: labels,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        case .safetyScenario(let isSafe, let description):
            SafetyScenarioView(
                isSafe: isSafe, scenarioDescription: description,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        case .flashcard(let front, let back, let frontIcon):
            FlashcardView(
                front: front, back: back, frontIcon: frontIcon,
                answered: $answered, wasCorrect: $wasCorrect,
                onAnswer: onAnswer
            )
        }
    }

    private var feedbackBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .font(.system(size: 24, weight: .bold))
                    .scaleEffect(feedbackAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: feedbackAppeared)

                VStack(alignment: .leading, spacing: 3) {
                    Text(wasCorrect
                         ? ["Nice!", "Correct!", "You got it!", "Great work!"].randomElement()!
                         : ["Not quite — here's why:", "Almost! Let's learn:", "Good try! The answer:"].randomElement()!)
                        .font(.system(size: 17, weight: .bold, design: .rounded))

                    Text(exercise.explanation)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .opacity(0.9)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
        .foregroundColor(.white)
        .padding(DS.padding)
        .padding(.bottom, 8)
        .background(
            ZStack {
                (wasCorrect ? DS.success : Color(hex: "7C3AED"))

                // Shimmer sweep on correct
                if wasCorrect {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.3)
                        .offset(x: feedbackAppeared ? geo.size.width : -geo.size.width * 0.3)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: feedbackAppeared)
                    }
                    .clipped()
                }
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Session Complete Screen
struct SessionCompleteView: View {
    let correctCount: Int
    let totalCount: Int
    let xpEarned: Int
    let onDone: () -> Void

    @State private var animate = false
    @State private var confettiTrigger = 0
    @State private var displayedXP = 0

    var pct: Double { Double(correctCount) / Double(max(1, totalCount)) }
    var perfect: Bool { correctCount == totalCount }

    var body: some View {
        ZStack {
            // Warm radial gradient for perfect runs
            if perfect {
                RadialGradient(
                    colors: [DS.gold.opacity(0.08), .clear],
                    center: .center,
                    startRadius: 40,
                    endRadius: 300
                )
                .ignoresSafeArea()
                .opacity(animate ? 1 : 0)

                // Celebration embers + lightning for perfect runs
                EmberParticleView(
                    particleCount: 35,
                    baseColor: DS.gold,
                    secondaryColor: .orange,
                    speed: 3.5
                )
                .opacity(animate ? 0.4 : 0)
                .allowsHitTesting(false)

                ElectricArcView(color: DS.gold, branchColor: .orange, arcCount: 1, intensity: 0.5)
                    .opacity(animate ? 0.3 : 0)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 28) {
                Spacer()

                // Mascot
                MascotView(
                    size: 120,
                    mood: perfect ? .celebrating : pct >= 0.5 ? .happy : .encouraging
                )
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1 : 0)

                // Title
                Text(perfect ? "Perfect!" : pct >= 0.7 ? "Great job!" : pct >= 0.5 ? "Good effort!" : "Keep going!")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 10)

                Text("\(correctCount) of \(totalCount) correct")
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textSecondary)
                    .opacity(animate ? 1 : 0)

                // XP badge with counting animation
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                    Text("+\(displayedXP) XP")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.orange.opacity(0.1)))
                .scaleEffect(animate ? 1.0 : 0.8)
                .opacity(animate ? 1 : 0)

                // Stars with spark bursts
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { star in
                        let thresholds = [0.01, 0.5, 1.0]
                        let earned = pct >= thresholds[star]
                        ZStack {
                            if animate && earned {
                                // Star burst effect
                                ForEach(0..<5, id: \.self) { p in
                                    Circle()
                                        .fill(DS.gold)
                                        .frame(width: 3, height: 3)
                                        .offset(
                                            x: cos(Double(p) * 72 * .pi / 180) * 20,
                                            y: sin(Double(p) * 72 * .pi / 180) * 20
                                        )
                                        .opacity(0.6)
                                }
                            }

                            Image(systemName: earned ? "star.fill" : "star")
                                .font(.system(size: 34))
                                .foregroundColor(DS.gold)
                                .shadow(color: earned ? DS.gold.opacity(0.4) : .clear, radius: 8)
                        }
                        .scaleEffect(animate && earned ? 1.15 : 0.7)
                        .opacity(animate ? 1 : 0.3)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.5)
                            .delay(0.5 + Double(star) * 0.2),
                            value: animate
                        )
                    }
                }

                // Stats summary
                if animate {
                    HStack(spacing: 16) {
                        statBadge(icon: "percent", value: "\(Int(pct * 100))%", label: "Accuracy")
                        statBadge(icon: "checkmark.circle", value: "\(correctCount)/\(totalCount)", label: "Correct")
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                PrimaryButton("Continue") { onDone() }
                    .padding(.horizontal, DS.padding)
                    .padding(.bottom, 40)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 20)
            }
        }
        .overlay {
            ConfettiBurstView(trigger: confettiTrigger)
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animate = true
            }
            if perfect { confettiTrigger += 1 }
            // Counting XP animation
            animateXPCounter()
        }
    }

    private func animateXPCounter() {
        let steps = min(xpEarned, 20)
        guard steps > 0 else { displayedXP = xpEarned; return }
        let perStep = xpEarned / steps
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + Double(i) * 0.04) {
                withAnimation(.easeOut(duration: 0.08)) {
                    displayedXP = min(xpEarned, perStep * i)
                }
            }
        }
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(DS.textPrimary)
            Text(label)
                .font(DS.smallFont)
                .foregroundStyle(DS.textTertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ConfettiBurstView: View {
    let trigger: Int
    private let colors: [Color] = [.orange, .yellow, .green, .blue, .purple, .pink, DS.gold, DS.electricBlue]
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<40, id: \.self) { i in
                    let angle = Double(i) * (360.0 / 40.0) + Double.random(in: -10...10)
                    let radius = CGFloat(animate ? Int.random(in: 80...200) : 6)
                    let size = CGFloat([6, 8, 10, 5, 12, 7, 9, 4][i % 8])

                    Group {
                        if i % 3 == 0 {
                            // Diamond confetti
                            Rectangle()
                                .fill(colors[i % colors.count])
                                .frame(width: size * 0.7, height: size)
                                .rotationEffect(.degrees(animate ? Double(i * 30) : 0))
                        } else if i % 3 == 1 {
                            // Strip confetti
                            RoundedRectangle(cornerRadius: 1)
                                .fill(colors[i % colors.count])
                                .frame(width: size * 0.35, height: size)
                                .rotationEffect(.degrees(animate ? Double(i * 25) : 0))
                        } else {
                            // Circle confetti
                            Circle()
                                .fill(colors[i % colors.count])
                                .frame(width: size, height: size)
                        }
                    }
                    .offset(
                        x: cos(angle * .pi / 180) * radius,
                        y: sin(angle * .pi / 180) * radius + (animate ? CGFloat(i % 5) * 12 : 0)
                    )
                    .opacity(animate ? 0 : 1)
                }
            }
            .position(x: geo.size.width / 2, y: 140)
            .onChange(of: trigger) {
                animate = false
                withAnimation(.easeOut(duration: 0.85)) {
                    animate = true
                }
            }
        }
    }
}

struct BoltRainView: View {
    let trigger: Int
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<22, id: \.self) { index in
                    let boltSize = CGFloat([14, 18, 24, 16, 28, 20, 12, 22, 30, 15, 26, 17][index % 12])
                    ZStack {
                        // Glow trail
                        Image(systemName: "bolt.fill")
                            .font(.system(size: boltSize, weight: .bold))
                            .foregroundStyle(.yellow.opacity(0.3))
                            .blur(radius: 4)

                        // Main bolt
                        Image(systemName: "bolt.fill")
                            .font(.system(size: boltSize, weight: .bold))
                            .foregroundStyle(
                                index.isMultiple(of: 3) ? DS.gold :
                                index.isMultiple(of: 2) ? .yellow : .orange
                            )
                    }
                    .rotationEffect(.degrees(animate ? Double(index * 15) : 0))
                    .position(
                        x: CGFloat((index * 37 + 13) % max(Int(geo.size.width), 1)),
                        y: animate ? geo.size.height + 60 : -40
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(.easeIn(duration: 0.9).delay(Double(index) * 0.025), value: animate)
                }
            }
            .onChange(of: trigger) {
                animate = false
                withAnimation {
                    animate = true
                }
            }
        }
    }
}

struct OutOfHeartsOverlay: View {
    let nextHeartDate: Date?
    let onExit: () -> Void
    let onRefill: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            CardView {
                VStack(spacing: 16) {
                    MascotView(size: 88, mood: .sad)
                    Text("Out of Hearts")
                        .font(DS.titleFont)
                        .foregroundStyle(DS.textPrimary)
                    Text(nextHeartDate.map { "Next heart around \($0.formatted(date: .omitted, time: .shortened))." } ?? "Take a break and come back soon.")
                        .font(DS.bodyFont)
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)

                    PrimaryButton("Refill Hearts", icon: "heart.fill", action: onRefill)
                    SecondaryButton("Return Home", icon: "house.fill", action: onExit)
                }
            }
            .padding(.horizontal, 28)
        }
    }
}
