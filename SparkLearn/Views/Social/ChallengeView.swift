import SwiftUI

// MARK: - Challenge View

struct ChallengeView: View {
    @StateObject private var challengeManager = ChallengeManager()
    @State private var selectedSegment = 0
    @State private var showSendChallenge = false
    @State private var showChallengeResult: Challenge?
    @State private var animateIn = false
    @State private var resultRevealed = false

    private let segments = ["Active", "Pending", "Completed"]

    var body: some View {
        ScrollView {
            VStack(spacing: DS.padding) {
                headerSection
                weeklyChallengeBanner
                segmentPicker
                challengeList
            }
            .padding(.horizontal, DS.padding)
            .padding(.bottom, 100)
        }
        .background(DS.heroBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(DS.transitionAnim.delay(0.1)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showSendChallenge) {
            SendChallengeSheet(challengeManager: challengeManager)
        }
        .sheet(item: $showChallengeResult) { challenge in
            ChallengeResultSheet(challenge: challenge)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Challenges")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                Text("\(challengeManager.activeChallenges.count) active")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            Button(action: {
                Haptics.light()
                SoundCue.tap()
                showSendChallenge = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Challenge")
                        .font(DS.captionFont)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: DS.buttonCorner)
                        .fill(DS.primary)
                )
            }
        }
        .padding(.top, 8)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
    }

    // MARK: - Weekly Challenge Banner

    @ViewBuilder
    private var weeklyChallengeBanner: some View {
        if let weekly = challengeManager.weeklyChallenge {
            CardView(accent: DS.gold) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(DS.gold)
                            Text("Challenge of the Week")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DS.gold)
                        }

                        Spacer()

                        Text("\(weekly.participantCount) joined")
                            .font(DS.smallFont)
                            .foregroundColor(DS.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(weekly.title)
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)

                        Text(weekly.description)
                            .font(DS.captionFont)
                            .foregroundColor(DS.textSecondary)
                            .lineLimit(2)
                    }

                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: weekly.topic.icon)
                                .font(.system(size: 12))
                                .foregroundColor(weekly.topic.color)
                            Text(weekly.topic.rawValue)
                                .font(DS.smallFont)
                                .foregroundColor(DS.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(weekly.topic.color.opacity(0.12))
                        )

                        HStack(spacing: 6) {
                            Image(systemName: weekly.difficulty.icon)
                                .font(.system(size: 12))
                                .foregroundColor(weekly.difficulty.color)
                            Text(weekly.difficulty.label)
                                .font(DS.smallFont)
                                .foregroundColor(DS.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(weekly.difficulty.color.opacity(0.12))
                        )

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("+\(weekly.xpBonus) XP")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(DS.gold)
                    }

                    PrimaryButton("Join Challenge", icon: "bolt.fill") {
                        Haptics.medium()
                        SoundCue.success()
                    }
                }
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 15)
            .animation(DS.transitionAnim.delay(0.1), value: animateIn)
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments.count, id: \.self) { index in
                let count: Int = {
                    switch index {
                    case 0: return challengeManager.activeChallenges.count
                    case 1: return challengeManager.pendingChallenges.count
                    case 2: return challengeManager.completedChallenges.count
                    default: return 0
                    }
                }()

                Button(action: {
                    Haptics.light()
                    withAnimation(DS.feedbackAnim) {
                        selectedSegment = index
                    }
                }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text(segments[index])
                                .font(.system(size: 14, weight: selectedSegment == index ? .bold : .medium, design: .rounded))

                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedSegment == index ? .white : DS.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(selectedSegment == index ? DS.primary : DS.divider)
                                    )
                            }
                        }
                        .foregroundColor(selectedSegment == index ? DS.primary : DS.textSecondary)

                        Rectangle()
                            .fill(selectedSegment == index ? DS.primary : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 6, y: 3)
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
        .animation(DS.transitionAnim.delay(0.15), value: animateIn)
    }

    // MARK: - Challenge List

    @ViewBuilder
    private var challengeList: some View {
        let challenges: [Challenge] = {
            switch selectedSegment {
            case 0: return challengeManager.activeChallenges
            case 1: return challengeManager.pendingChallenges
            case 2: return challengeManager.completedChallenges
            default: return []
            }
        }()

        if challenges.isEmpty {
            emptyState
        } else {
            ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                challengeCard(challenge)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(DS.transitionAnim.delay(0.2 + Double(index) * 0.06), value: animateIn)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            MascotWithMessage(
                message: selectedSegment == 0
                    ? "No active challenges. Send one to a friend!"
                    : selectedSegment == 1
                        ? "No pending challenges right now."
                        : "Complete challenges to see your history!",
                mood: .encouraging,
                mascotSize: 80
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Challenge Card

    private func challengeCard(_ challenge: Challenge) -> some View {
        CardView(accent: challenge.topic.color) {
            VStack(spacing: 14) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: challenge.topic.icon)
                            .font(.system(size: 20))
                            .foregroundColor(challenge.topic.color)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(challenge.topic.color.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(challenge.topic.rawValue)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.textPrimary)

                            HStack(spacing: 4) {
                                Image(systemName: challenge.difficulty.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(challenge.difficulty.color)
                                Text(challenge.difficulty.label)
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.textSecondary)

                                Text("  \(challenge.questionsCount) Qs")
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.textTertiary)
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: challenge.status.icon)
                                .font(.system(size: 10))
                            Text(challenge.status.label)
                                .font(DS.smallFont)
                        }
                        .foregroundColor(challenge.status.color)

                        if challenge.status != .completed && !challenge.isExpired {
                            Text(challenge.timeRemainingFormatted)
                                .font(DS.smallFont)
                                .foregroundColor(DS.textTertiary)
                        }
                    }
                }

                Divider()
                    .foregroundColor(DS.divider)

                HStack {
                    HStack(spacing: 8) {
                        Text(challenge.senderAvatar)
                            .font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(challenge.senderName)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.textPrimary)
                            if let score = challenge.senderScore {
                                Text("\(score)%")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.primary)
                            }
                        }
                    }

                    Spacer()

                    Text("vs")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(DS.textTertiary)

                    Spacer()

                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("You")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.textPrimary)
                            if let score = challenge.recipientScore {
                                Text("\(score)%")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.accent)
                            } else {
                                Text("--")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(DS.textTertiary)
                            }
                        }
                        Text("⚡")
                            .font(.system(size: 24))
                    }
                }

                // Action buttons based on status
                switch challenge.status {
                case .pending:
                    HStack(spacing: 10) {
                        SecondaryButton("Decline", icon: "xmark") {
                            Haptics.light()
                            withAnimation(DS.feedbackAnim) {
                                challengeManager.declineChallenge(challenge.id)
                            }
                        }

                        PrimaryButton("Accept", icon: "checkmark") {
                            Haptics.medium()
                            SoundCue.success()
                            withAnimation(DS.feedbackAnim) {
                                challengeManager.acceptChallenge(challenge.id)
                            }
                        }
                    }

                case .active:
                    PrimaryButton("Start Quiz", icon: "play.fill") {
                        Haptics.medium()
                        SoundCue.tap()
                        let score = Int.random(in: 55...100)
                        withAnimation(DS.feedbackAnim) {
                            challengeManager.completeChallenge(challenge.id, yourScore: score)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let updated = challengeManager.challenges.first(where: { $0.id == challenge.id }) {
                                showChallengeResult = updated
                            }
                        }
                    }

                case .completed:
                    if let winner = challenge.winner {
                        Button(action: {
                            Haptics.light()
                            showChallengeResult = challenge
                        }) {
                            HStack {
                                Image(systemName: winner == "You" ? "trophy.fill" : winner == "Tie" ? "equal.circle.fill" : "hand.thumbsup.fill")
                                    .foregroundColor(winner == "You" ? DS.gold : winner == "Tie" ? DS.primary : DS.textSecondary)

                                Text(winner == "You" ? "You won!" : winner == "Tie" ? "It's a tie!" : "\(winner) won")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(winner == "You" ? DS.gold : DS.textSecondary)

                                Spacer()

                                Text("View Results")
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.primary)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(DS.primary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(winner == "You" ? DS.gold.opacity(0.08) : DS.divider)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Send Challenge Sheet

struct SendChallengeSheet: View {
    @ObservedObject var challengeManager: ChallengeManager
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var selectedTopic: ChallengeTopic?
    @State private var selectedDifficulty: ChallengeDifficulty?
    @State private var selectedFriend: (name: String, avatar: String)?
    @State private var animateStep = false

    private let friends: [(name: String, avatar: String)] = [
        ("Alex Chen", "🧑‍🔧"), ("Jordan Blake", "👩‍🔬"), ("Casey Park", "🧑‍💻"),
        ("Morgan Lee", "👨‍🏫"), ("Taylor Swift", "👩‍🎓"), ("Riley Davis", "🧑‍🔬"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator

                ScrollView {
                    VStack(spacing: DS.padding) {
                        switch step {
                        case 0: friendPickerStep
                        case 1: topicPickerStep
                        case 2: difficultyPickerStep
                        default: EmptyView()
                        }
                    }
                    .padding(DS.padding)
                }
            }
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("Send Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step > 0 {
                        Button(action: {
                            Haptics.light()
                            withAnimation(DS.feedbackAnim) {
                                animateStep = false
                                step -= 1
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(DS.transitionAnim) { animateStep = true }
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(DS.primary)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }
            }
            .onAppear {
                withAnimation(DS.transitionAnim) { animateStep = true }
            }
        }
        .presentationDetents([.large])
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? DS.primary : DS.divider)
                    .frame(height: 4)
                    .animation(DS.feedbackAnim, value: step)
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.top, 8)
    }

    // MARK: - Step 0: Pick Friend

    private var friendPickerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who do you want to challenge?")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            ForEach(Array(friends.enumerated()), id: \.offset) { index, friend in
                Button(action: {
                    Haptics.light()
                    SoundCue.tap()
                    selectedFriend = friend
                    advanceStep()
                }) {
                    HStack(spacing: 14) {
                        Text(friend.avatar)
                            .font(.system(size: 36))

                        Text(friend.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(DS.textPrimary)

                        Spacer()

                        if selectedFriend?.name == friend.name {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DS.primary)
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundColor(DS.textTertiary)
                                .font(.system(size: 12))
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .fill(selectedFriend?.name == friend.name ? DS.primary.opacity(0.06) : DS.cardBg)
                            .shadow(color: DS.cardShadow, radius: 6, y: 3)
                    )
                }
                .opacity(animateStep ? 1 : 0)
                .offset(y: animateStep ? 0 : 15)
                .animation(DS.transitionAnim.delay(Double(index) * 0.05), value: animateStep)
            }
        }
    }

    // MARK: - Step 1: Pick Topic

    private var topicPickerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a topic")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(ChallengeTopic.allCases.enumerated()), id: \.element) { index, topic in
                    Button(action: {
                        Haptics.light()
                        SoundCue.tap()
                        selectedTopic = topic
                        advanceStep()
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 24))
                                .foregroundColor(topic.color)
                                .frame(width: 48, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(topic.color.opacity(0.12))
                                )

                            Text(topic.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(DS.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: DS.cornerRadius)
                                .fill(selectedTopic == topic ? topic.color.opacity(0.08) : DS.cardBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                                        .stroke(selectedTopic == topic ? topic.color : Color.clear, lineWidth: 2)
                                )
                                .shadow(color: DS.cardShadow, radius: 6, y: 3)
                        )
                    }
                    .opacity(animateStep ? 1 : 0)
                    .offset(y: animateStep ? 0 : 15)
                    .animation(DS.transitionAnim.delay(Double(index) * 0.04), value: animateStep)
                }
            }
        }
    }

    // MARK: - Step 2: Pick Difficulty

    private var difficultyPickerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select difficulty")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            if let friend = selectedFriend, let topic = selectedTopic {
                HStack(spacing: 10) {
                    Text(friend.avatar)
                        .font(.system(size: 24))
                    Text(friend.name)
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(DS.textTertiary)
                    Image(systemName: topic.icon)
                        .foregroundColor(topic.color)
                    Text(topic.rawValue)
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.divider)
                )
            }

            ForEach(Array(ChallengeDifficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                Button(action: {
                    Haptics.medium()
                    SoundCue.tap()
                    selectedDifficulty = difficulty
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: difficulty.icon)
                            .font(.system(size: 22))
                            .foregroundColor(difficulty.color)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(difficulty.color.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(difficulty.label)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.textPrimary)

                            Text("\(difficulty.questionCount) questions  +\(difficulty.xpReward) XP")
                                .font(DS.smallFont)
                                .foregroundColor(DS.textSecondary)
                        }

                        Spacer()

                        if selectedDifficulty == difficulty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(difficulty.color)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .fill(selectedDifficulty == difficulty ? difficulty.color.opacity(0.06) : DS.cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .stroke(selectedDifficulty == difficulty ? difficulty.color : Color.clear, lineWidth: 2)
                            )
                            .shadow(color: DS.cardShadow, radius: 6, y: 3)
                    )
                }
                .opacity(animateStep ? 1 : 0)
                .offset(y: animateStep ? 0 : 15)
                .animation(DS.transitionAnim.delay(Double(index) * 0.08), value: animateStep)
            }

            if selectedDifficulty != nil {
                PrimaryButton("Send Challenge", icon: "paperplane.fill") {
                    guard let friend = selectedFriend,
                          let topic = selectedTopic,
                          let difficulty = selectedDifficulty else { return }
                    Haptics.success()
                    SoundCue.success()
                    challengeManager.sendChallenge(
                        to: friend.name,
                        avatar: friend.avatar,
                        topic: topic,
                        difficulty: difficulty
                    )
                    dismiss()
                }
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func advanceStep() {
        withAnimation(DS.feedbackAnim) {
            animateStep = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            step += 1
            withAnimation(DS.transitionAnim) {
                animateStep = true
            }
        }
    }
}

// MARK: - Challenge Result Sheet

struct ChallengeResultSheet: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    @State private var senderRevealed = false
    @State private var recipientRevealed = false
    @State private var winnerRevealed = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Challenge Results")
                .font(DS.titleFont)
                .foregroundColor(DS.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: challenge.topic.icon)
                    .foregroundColor(challenge.topic.color)
                Text(challenge.topic.rawValue)
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(challenge.topic.color.opacity(0.12))
            )

            HStack(spacing: 20) {
                // Sender score
                VStack(spacing: 10) {
                    Text(challenge.senderAvatar)
                        .font(.system(size: 48))

                    Text(challenge.senderName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)

                    Text(senderRevealed ? "\(challenge.senderScore ?? 0)%" : "?")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(DS.primary)
                        .scaleEffect(senderRevealed ? 1.0 : 0.5)
                        .opacity(senderRevealed ? 1 : 0.3)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("VS")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(DS.textTertiary)
                }

                // Recipient score
                VStack(spacing: 10) {
                    Text("⚡")
                        .font(.system(size: 48))

                    Text("You")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)

                    Text(recipientRevealed ? "\(challenge.recipientScore ?? 0)%" : "?")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(DS.accent)
                        .scaleEffect(recipientRevealed ? 1.0 : 0.5)
                        .opacity(recipientRevealed ? 1 : 0.3)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DS.padding)

            // Winner banner
            if winnerRevealed, let winner = challenge.winner {
                VStack(spacing: 8) {
                    Image(systemName: winner == "You" ? "trophy.fill" : winner == "Tie" ? "equal.circle.fill" : "hand.thumbsup.fill")
                        .font(.system(size: 40))
                        .foregroundColor(winner == "You" ? DS.gold : DS.primary)

                    Text(winner == "You" ? "You Win!" : winner == "Tie" ? "It's a Tie!" : "\(winner) Wins!")
                        .font(DS.headlineFont)
                        .foregroundColor(DS.textPrimary)

                    if winner == "You" {
                        Text("+\(challenge.difficulty.xpReward) XP earned!")
                            .font(DS.captionFont)
                            .foregroundColor(DS.gold)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            PrimaryButton("Done", icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal, DS.padding)
            .padding(.bottom, 32)
        }
        .background(DS.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(DS.transitionAnim.delay(0.3)) {
                senderRevealed = true
            }
            withAnimation(DS.transitionAnim.delay(0.8)) {
                recipientRevealed = true
            }
            withAnimation(DS.feedbackAnim.delay(1.4)) {
                winnerRevealed = true
                Haptics.success()
                SoundCue.success()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChallengeView()
}
