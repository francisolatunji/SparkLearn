import SwiftUI
import UserNotifications

@main
struct SparkLearnApp: App {
    @StateObject private var auth = AuthManager()
    @StateObject private var progress = ProgressManager()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var leagueManager = LeagueManager()
    @StateObject private var questManager = QuestManager()
    @StateObject private var spacedRepetition = SpacedRepetitionEngine()
    @StateObject private var adaptiveLearning = AdaptiveLearningEngine()
    @StateObject private var aiTutor = AITutorService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(progress)
                .environmentObject(achievementManager)
                .environmentObject(leagueManager)
                .environmentObject(questManager)
                .environmentObject(spacedRepetition)
                .environmentObject(adaptiveLearning)
                .environmentObject(aiTutor)
                .preferredColorScheme(.light)
                .onAppear {
                    FirebaseConfigManager.shared.configure()
                    SyncManager.shared.startAutoSync()
                    AnalyticsService.shared.track(.appOpened)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var progress: ProgressManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLightningIntro = false
    @State private var lightningTrigger = 0

    var body: some View {
        ZStack {
            if auth.showOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else if !auth.isAuthenticated {
                AuthView()
                    .transition(.opacity)
            } else if auth.needsProfileSetup {
                ProfileSetupView()
                    .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }

            LightningWelcomeOverlay(trigger: lightningTrigger, isVisible: $showLightningIntro)
        }
        .animation(.easeInOut(duration: 0.4), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: auth.showOnboarding)
        .task {
            triggerEntranceLightning()
        }
        .onChange(of: auth.isAuthenticated) { _, newValue in
            if newValue {
                triggerEntranceLightning()
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                progress.refreshHearts()
                triggerEntranceLightning()
            }
        }
    }

    private func triggerEntranceLightning() {
        lightningTrigger += 1
        showLightningIntro = true
        Haptics.medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { Haptics.success() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                showLightningIntro = false
            }
        }
    }
}

struct ProfileSetupView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var progress: ProgressManager

    @State private var name = ""
    @State private var learnerStage: LearnerStage = .beginner
    @State private var learningGoal: LearningGoal = .understandBasics
    @State private var focusArea = "Circuits"
    @State private var notificationMessage = "Spark can remind you to protect your streak and come back when it matters."

    var body: some View {
        ZStack {
            DS.heroBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Set Up Your Profile")
                            .font(DS.heroTitleFont)
                            .foregroundStyle(DS.textPrimary)
                        Text("A few preferences will shape your curriculum recommendations and practice queue.")
                            .font(DS.bodyFont)
                            .foregroundStyle(DS.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)

                    DSGlassCard {
                        VStack(spacing: 18) {
                            AuthTextField(
                                icon: "person.fill",
                                placeholder: "Name",
                                text: $name
                            )

                            preferenceSection(
                                title: "Your level",
                                items: LearnerStage.allCases,
                                selection: $learnerStage
                            ) { stage in
                                stage.title
                            }

                            preferenceSection(
                                title: "Primary goal",
                                items: LearningGoal.allCases,
                                selection: $learningGoal
                            ) { goal in
                                goal.title
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Current focus")
                                    .font(DS.captionFont)
                                    .foregroundStyle(DS.textSecondary)
                                AuthTextField(
                                    icon: "scope",
                                    placeholder: "Examples: Arduino, power basics, safety",
                                    text: $focusArea
                                )
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Learning habits")
                                    .font(DS.captionFont)
                                    .foregroundStyle(DS.textSecondary)

                                Toggle("Immersive learning mode", isOn: Binding(
                                    get: { progress.immersiveLearningEnabled },
                                    set: { progress.updateImmersiveLearningEnabled($0) }
                                ))

                                VStack(alignment: .leading, spacing: 10) {
                                    MascotWithMessage(
                                        message: notificationMessage,
                                        mood: .encouraging,
                                        mascotSize: 70
                                    )

                                    Button(progress.notificationsEnabled ? "Notifications Enabled" : "Enable Streak Notifications") {
                                        Task {
                                            let granted = await NotificationCoordinator.requestAuthorization()
                                            progress.updateNotificationsEnabled(granted)
                                            progress.updateDailyReminderEnabled(granted)
                                            notificationMessage = granted
                                                ? "Perfect. I'll nudge you before your streak cools off."
                                                : "No problem. You can still turn reminders on later in Profile."
                                        }
                                    }
                                    .font(DS.captionFont)
                                    .foregroundStyle(progress.notificationsEnabled ? DS.success : DS.primary)
                                    .disabled(progress.notificationsEnabled)
                                }
                            }
                        }
                    }

                    PrimaryButton("Continue", icon: "arrow.right") {
                        auth.completeProfile(
                            name: name,
                            learnerStage: learnerStage,
                            learningGoal: learningGoal,
                            focusArea: focusArea
                        )
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            name = auth.currentUser?.displayName ?? auth.pendingProfileName
            learnerStage = auth.currentUser?.learnerStage ?? .beginner
            learningGoal = auth.currentUser?.learningGoal ?? .understandBasics
            focusArea = auth.currentUser?.focusArea ?? "Circuits"
        }
    }

    private func preferenceSection<Value: Hashable>(
        title: String,
        items: [Value],
        selection: Binding<Value>,
        label: @escaping (Value) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DS.captionFont)
                .foregroundStyle(DS.textSecondary)

            FlowLayout(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Button {
                        selection.wrappedValue = item
                    } label: {
                        Text(label(item))
                            .font(DS.captionFont)
                            .foregroundStyle(selection.wrappedValue == item ? .white : DS.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selection.wrappedValue == item ? DS.primary : DS.cardBg)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(DS.border, lineWidth: selection.wrappedValue == item ? 0 : 1)
                            )
                    }
                }
            }
        }
    }
}
struct LightningWelcomeOverlay: View {
    let trigger: Int
    @Binding var isVisible: Bool

    @State private var flash = false
    @State private var boltScale: CGFloat = 0.3
    @State private var boltOpacity: Double = 0
    @State private var nameOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var boltOffset: CGFloat = -300
    @State private var showLightningArcs = false
    @State private var showEmbers = false
    @State private var xpPopTrigger = 0

    var body: some View {
        ZStack {
            if isVisible {
                // Living mesh gradient background
                AnimatedMeshBackground(darkMode: true)
                    .transition(.opacity)

                // Real-time lightning arcs behind the bolt
                if showLightningArcs {
                    ElectricArcView(
                        color: Color(hex: "3B82F6"),
                        branchColor: Color(hex: "00D4FF"),
                        arcCount: 2,
                        intensity: 0.8
                    )
                    .frame(height: 400)
                    .offset(y: -50)
                    .transition(.opacity)
                }

                // Rising ember particles
                if showEmbers {
                    EmberParticleView(
                        particleCount: 40,
                        baseColor: Color(hex: "FBBF24"),
                        secondaryColor: Color(hex: "3B82F6"),
                        speed: 3.0
                    )
                    .opacity(0.5)
                    .transition(.opacity)
                }

                // White screen flash on strike
                Color.white
                    .opacity(flash ? 0.6 : 0)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Thunderbolt with layered glow
                    ZStack {
                        // Outer glow halo
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 90, weight: .black))
                            .foregroundStyle(.yellow.opacity(0.2))
                            .blur(radius: 30)
                            .scaleEffect(boltScale * 1.3)

                        // Mid glow
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 90, weight: .black))
                            .foregroundStyle(.orange.opacity(0.3))
                            .blur(radius: 12)
                            .scaleEffect(boltScale * 1.1)

                        // Main bolt
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 90, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "FDE68A"),
                                        Color(hex: "FBBF24"),
                                        Color(hex: "F97316")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .yellow.opacity(0.8), radius: 20)
                    }
                    .scaleEffect(boltScale)
                    .opacity(boltOpacity)
                    .offset(y: boltOffset)

                    // App name with letter spacing
                    Text("SparkLearn")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(hex: "93C5FD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(hex: "3B82F6").opacity(0.5), radius: 20)
                        .opacity(nameOpacity)

                    // Tagline
                    Text("Power your knowledge")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "94A3B8"))
                        .tracking(3)
                        .textCase(.uppercase)
                        .opacity(taglineOpacity)

                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            guard isVisible else { return }
            resetState()
            runAnimation()
        }
    }

    private func resetState() {
        flash = false
        boltScale = 0.3
        boltOpacity = 0
        nameOpacity = 0
        taglineOpacity = 0
        glowOpacity = 0
        boltOffset = -300
        showLightningArcs = false
        showEmbers = false
    }

    private func runAnimation() {
        // Electric shock haptic
        SparkHaptics.shared.playElectricShock()

        // Step 1: Bolt strikes down with flash
        withAnimation(.easeOut(duration: 0.16)) {
            boltOpacity = 1
            boltOffset = 0
            boltScale = 1.25
            flash = true
            glowOpacity = 1
        }

        // Step 2: Bolt bounces, arcs + embers appear
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.16)) {
            boltScale = 1.0
            showLightningArcs = true
        }

        // Step 3: Flash fades, name + tagline + embers
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            flash = false
            nameOpacity = 1
            showEmbers = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.35)) {
            taglineOpacity = 1
        }

        // Step 4: Everything fades out
        withAnimation(.easeIn(duration: 0.4).delay(1.1)) {
            boltOpacity = 0
            nameOpacity = 0
            taglineOpacity = 0
            glowOpacity = 0
            showLightningArcs = false
            showEmbers = false
        }
    }
}

enum NotificationCoordinator {
    private static let reminderIdentifier = "sparklearn.daily.reminder"

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleDailyReminder(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Sparky needs you"
        content.body = "Your streak is waiting. Come back and power through one more lesson."
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func clearDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }
}
