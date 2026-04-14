import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var progress: ProgressManager
    @State private var currentPage = 0
    @State private var appeared = false
    @State private var selectedGoal = 120

    @State private var diagnosticAnswers: [Int: Bool] = [:]
    @State private var showDiagnostic = false

    private let pages: [(title: String, body: String, mood: MascotMood)] = [
        ("Meet Sparky",
         "Sparky was reckless around electronics, ignored safety, and had no idea what voltage even meant.", .sad),
        ("The Turnaround",
         "Instead of giving up, Sparky chose grit, practice, and safer habits. One lesson at a time, he got better.", .encouraging),
        ("What do you know?",
         "Answer a few quick questions so Sparky can place you at the right level. No pressure — wrong answers help us help you!", .curious),
        ("Set Your Pace",
         "How much do you want to learn each day? SparkLearn will shape the pace around that target.", .celebrating),
        ("You're Ready!",
         "Sparky is excited to learn with you. Your first lesson is waiting — let's go!", .excited)
    ]

    var body: some View {
        ZStack {
            DS.heroBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        onboardingPage(index: i, page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 460)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? DS.primary : DS.border)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 40)

                Spacer()

                VStack(spacing: 14) {
                    if currentPage < pages.count - 1 {
                        PrimaryButton(currentPage == 2 ? "Start Quiz" : "Next") {
                            withAnimation { currentPage += 1 }
                        }
                        .padding(.horizontal, DS.padding)

                        Button("Skip") {
                            auth.completeOnboarding()
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(DS.textTertiary)
                    } else {
                        PrimaryButton("Start Learning", icon: "bolt.fill") {
                            progress.updateDailyXPGoal(selectedGoal)
                            auth.completeOnboarding()
                            Haptics.success()
                            SoundCue.celebration()
                        }
                        .padding(.horizontal, DS.padding)
                    }
                }
                .padding(.bottom, 40)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
    }

    private func onboardingPage(index: Int, page: (title: String, body: String, mood: MascotMood)) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.7))
                    .frame(width: 180, height: 180)
                AnimatedStoryBackdrop(stage: index)
                MascotView(size: 120, mood: page.mood)
            }

            DSGlassCard {
                VStack(spacing: 16) {
                    Text(page.title)
                        .font(DS.titleFont)
                        .foregroundStyle(DS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(page.body)
                        .font(DS.bodyFont)
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    // Diagnostic quiz page
                    if index == 2 {
                        DiagnosticQuizPreview()
                    }

                    // Daily goal page
                    if index == 3 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily learning target")
                                .font(DS.captionFont)
                                .foregroundStyle(DS.textSecondary)

                            FlowLayout(spacing: 10) {
                                ForEach([60, 120, 180, 240], id: \.self) { option in
                                    Button {
                                        selectedGoal = option
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text("\(option) XP")
                                                .font(DS.captionFont)
                                                .foregroundStyle(selectedGoal == option ? .white : DS.textPrimary)
                                            Text(goalLabel(option))
                                                .font(DS.smallFont)
                                                .foregroundStyle(selectedGoal == option ? .white.opacity(0.7) : DS.textTertiary)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(selectedGoal == option ? DS.primary : DS.cardBg)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DS.padding)
        }
    }
}

    private func goalLabel(_ xp: Int) -> String {
        switch xp {
        case 60: return "~5 min"
        case 120: return "~10 min"
        case 180: return "~15 min"
        case 240: return "~20 min"
        default: return ""
        }
    }
}

// MARK: - Diagnostic Quiz Preview
struct DiagnosticQuizPreview: View {
    let questions = [
        ("What unit is voltage measured in?", ["Amps", "Volts", "Ohms", "Watts"], 1),
        ("Ohm's Law states:", ["V = I + R", "V = I × R", "V = I / R", "V = I² × R"], 1),
        ("In a series circuit, current is:", ["Different everywhere", "Same everywhere", "Zero", "Infinite"], 1),
    ]

    @State private var currentQ = 0
    @State private var answers: [Int] = []
    @State private var selected: Int?

    var body: some View {
        if currentQ < questions.count {
            VStack(spacing: 12) {
                Text("Question \(currentQ + 1) of \(questions.count)")
                    .font(DS.smallFont)
                    .foregroundColor(DS.textTertiary)

                ProgressBar(progress: Double(currentQ) / Double(questions.count), color: DS.primary, height: 4)

                let q = questions[currentQ]
                Text(q.0)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                ForEach(q.1.indices, id: \.self) { i in
                    Button {
                        selected = i
                        answers.append(i)
                        Haptics.light()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                currentQ += 1
                                selected = nil
                            }
                        }
                    } label: {
                        Text(q.1[i])
                            .font(DS.captionFont)
                            .foregroundColor(selected == i ? .white : DS.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selected == i ? DS.primary : DS.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selected == i ? Color.clear : DS.border, lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(selected != nil)
                }
            }
        } else {
            VStack(spacing: 8) {
                let correct = zip(answers, questions).filter { $0.0 == $0.1.2 }.count
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DS.success)
                Text("\(correct)/\(questions.count) correct")
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)
                Text("We'll personalize your path!")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
            }
        }
    }
}

private struct AnimatedStoryBackdrop: View {
    let stage: Int
    @State private var drift = false
    @State private var ripple = false
    @State private var particleRise = false

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(ringColor.opacity(0.18), lineWidth: 12)
                .frame(width: 160, height: 160)
                .scaleEffect(drift ? 1.06 : 0.92)

            // Inner glow ring
            Circle()
                .stroke(ringColor.opacity(0.08), lineWidth: 24)
                .frame(width: 130, height: 130)
                .scaleEffect(drift ? 0.95 : 1.04)

            // Stage-specific effects
            if stage == 0 {
                // Danger sparks
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i.isMultiple(of: 2) ? DS.error : DS.warning)
                        .frame(width: 4, height: 4)
                        .offset(
                            x: cos(Double(i) * 72 * .pi / 180) * (drift ? 70 : 55),
                            y: sin(Double(i) * 72 * .pi / 180) * (drift ? 70 : 55)
                        )
                        .opacity(drift ? 0.3 : 0.8)

                }
                // Pulsing red glow
                Circle()
                    .fill(DS.error.opacity(drift ? 0.08 : 0.02))
                    .frame(width: 180, height: 180)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(DS.warning)
                    .offset(x: drift ? 24 : 14, y: drift ? -42 : -34)
                    .shadow(color: DS.warning.opacity(0.4), radius: 8)

            } else if stage == 1 {
                // Ascending sparkle particles
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat([8, 10, 12, 9, 11, 7][i])))
                        .foregroundStyle(i.isMultiple(of: 2) ? DS.accent : DS.gold)
                        .offset(
                            x: CGFloat([-30, 20, -10, 35, -25, 15][i]),
                            y: particleRise ? CGFloat([-80, -70, -90, -65, -85, -75][i]) : 10
                        )
                        .opacity(particleRise ? 0 : 0.7)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(DS.accent)
                    .offset(x: drift ? -24 : -10, y: drift ? -42 : -30)
                    .shadow(color: DS.accent.opacity(0.4), radius: 8)

            } else {
                // Target ripple rings
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(DS.primary.opacity(ripple ? 0 : 0.2), lineWidth: 2)
                        .frame(
                            width: ripple ? 200 : 40,
                            height: ripple ? 200 : 40
                        )
                        .animation(
                            .easeOut(duration: 2.0)
                            .delay(Double(i) * 0.6)
                            .repeatForever(autoreverses: false),
                            value: ripple
                        )
                }

                Image(systemName: "target")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(DS.primary)
                    .offset(x: drift ? 0 : -6, y: drift ? -46 : -32)
                    .shadow(color: DS.primary.opacity(0.4), radius: 8)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                drift = true
            }
            if stage == 1 {
                withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    particleRise = true
                }
            }
            if stage == 2 {
                ripple = true
            }
        }
    }

    private var ringColor: Color {
        switch stage {
        case 0: return DS.error
        case 1: return DS.accent
        default: return DS.primary
        }
    }
}
