import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progress: ProgressManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tag(0)

            PracticeView()
                .tag(1)

            CircuitBuilderView()
                .tag(2)

            ProfileView()
                .tag(3)
        }
        .tabViewStyle(.automatic)
        .overlay(alignment: .bottom) {
            CustomTabBar(selected: $selectedTab)
        }
    }
}

// MARK: - Custom Tab Bar (floating pill design)
struct CustomTabBar: View {
    @Binding var selected: Int
    @Namespace private var tabAnimation

    private let tabs: [(icon: String, filledIcon: String, label: String)] = [
        ("bolt", "bolt.fill", "Learn"),
        ("target", "target", "Practice"),
        ("hammer", "hammer.fill", "Build"),
        ("person", "person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                Button(action: {
                    Haptics.light()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = i
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selected == i {
                                Circle()
                                    .fill(DS.primary.opacity(0.12))
                                    .frame(width: 42, height: 42)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
                            }

                            Image(systemName: selected == i ? tabs[i].filledIcon : tabs[i].icon)
                                .font(.system(size: 20, weight: selected == i ? .semibold : .regular))
                                .foregroundColor(selected == i ? DS.primary : DS.textTertiary)
                                .scaleEffect(selected == i ? 1.1 : 1.0)
                        }
                        .frame(height: 42)

                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: selected == i ? .semibold : .medium, design: .rounded))
                            .foregroundColor(selected == i ? DS.primary : DS.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
        )
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
    }
}

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject var progress: ProgressManager
    @EnvironmentObject var auth: AuthManager
    @State private var appeared = false
    @State private var headerOffset: CGFloat = 0
    @State private var selectedLessonSheet: LessonSheetItem?
    @State private var selectedUnitSheet: CourseUnit?
    @State private var activeDashboardSheet: DashboardSheet?

    private var collapseProgress: Double {
        let progress = min(1, max(0, -headerOffset / 72))
        return progress
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.heroBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: DashboardScrollOffsetKey.self,
                                    value: geo.frame(in: .named("dashboardScroll")).minY
                                )
                        }
                        .frame(height: 0)

                        // Top bar
                        topBar
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : -10)

                        // Stats strip
                        statsStrip
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        topQuickActions
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        // Continue learning (primary CTA)
                        if let nextLesson = findNextLesson() {
                            continueLearningCard(nextLesson.lesson, unit: nextLesson.unit)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)
                        }

                        if allUnitsComplete {
                            graduationCard
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 15)
                        }

                        // League Widget
                        leagueWidget
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 16)

                        // Daily Quests Widget
                        dailyQuestsWidget
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 17)

                        focusJourneySection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)

                        unitTreeSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, DS.padding)
                }
                .coordinateSpace(name: "dashboardScroll")
                .onPreferenceChange(DashboardScrollOffsetKey.self) { newValue in
                    headerOffset = newValue
                }

                compactHeader
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            }
            .sheet(item: $selectedLessonSheet) { sheetItem in
                LessonQuickSheet(lesson: sheetItem.lesson, unit: sheetItem.unit)
            }
            .sheet(item: $selectedUnitSheet) { unit in
                UnitTreeSheet(unit: unit)
                    .environmentObject(progress)
            }
            .sheet(item: $activeDashboardSheet) { sheet in
                switch sheet {
                case .curriculum:
                    CurriculumOverviewSheet()
                        .environmentObject(auth)
                case .dailyGoal:
                    DailyGoalSheet()
                        .environmentObject(progress)
                }
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome back")
                    .font(.system(size: 28 - (8 * collapseProgress), weight: .bold, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Text(auth.currentUser?.displayName ?? "Learner")
                    .font(.system(size: 20 - (4 * collapseProgress), weight: .semibold, design: .rounded))
                    .foregroundColor(DS.primary)
                Text(auth.currentUser?.learningGoal.subtitle ?? "Tiny wins, every day")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
                    .opacity(1 - collapseProgress)
            }

            Spacer()

            MascotView(size: 44, mood: progress.currentStreak > 0 ? .happy : .encouraging, animate: false)
        }
        .padding(.top, 8)
        .animation(DS.transitionAnim, value: collapseProgress)
    }

    private var compactHeader: some View {
        VStack {
            HStack {
                Text(auth.currentUser?.displayName ?? "SparkLearn")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                HStack(spacing: 8) {
                    Label("\(progress.currentStreak)", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(DS.captionFont)
                    Label("\(progress.totalXP)", systemImage: "bolt.fill")
                        .foregroundStyle(DS.primary)
                        .font(DS.captionFont)
                }
            }
            .padding(.horizontal, DS.padding)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
            .opacity(collapseProgress)
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
        .animation(DS.transitionAnim, value: collapseProgress)
    }

    // MARK: - Stats Strip
    private var statsStrip: some View {
        HStack(spacing: 0) {
            statPill(icon: "flame.fill", value: "\(progress.currentStreak)", color: .orange, label: "streak")
            Spacer()
            statPill(icon: "bolt.fill", value: "\(progress.totalXP)", color: DS.primary, label: "XP")
            Spacer()
            statPill(icon: "heart.fill", value: "\(progress.hearts)", color: .red, label: "hearts")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.cardCorner)
                .fill(DS.cardBg)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    private var allUnitsComplete: Bool {
        CourseData.units.flatMap(\.lessons).allSatisfy { progress.isLessonCompleted($0.id) }
    }

    private var topQuickActions: some View {
        HStack(spacing: 12) {
            dashboardActionButton(
                title: "Curriculum Map",
                subtitle: "See the full path",
                icon: "map.fill"
            ) {
                activeDashboardSheet = .curriculum
            }

            dashboardActionButton(
                title: "Daily Goal",
                subtitle: "\(progress.dailyXP)/\(progress.dailyXPGoal) XP",
                icon: "target"
            ) {
                activeDashboardSheet = .dailyGoal
            }
        }
        .padding(.horizontal, DS.padding)
    }

    // MARK: - League Widget
    private var leagueWidget: some View {
        NavigationLink {
            LeagueView()
                .environmentObject(progress)
        } label: {
            CardView(accent: DS.deepPurple) {
                HStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(DS.gold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("League")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)
                        Text("Compete with other learners")
                            .font(DS.captionFont)
                            .foregroundColor(DS.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(DS.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Quests Widget
    private var dailyQuestsWidget: some View {
        NavigationLink {
            DailyQuestView()
        } label: {
            CardView(accent: DS.accent) {
                HStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(DS.accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Quests")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)
                        Text("Complete quests for rewards")
                            .font(DS.captionFont)
                            .foregroundColor(DS.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(DS.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var focusJourneySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Path")
                .font(DS.headlineFont)
                .foregroundStyle(DS.textPrimary)
                .padding(.horizontal, DS.padding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(CourseData.units.prefix(4), id: \.id) { unit in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: unit.tier.icon)
                                    .foregroundStyle(unit.color)
                                Text(unit.tier.title)
                                    .font(DS.smallFont)
                                    .foregroundStyle(unit.color)
                            }

                            Text(unit.title)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(DS.textPrimary)

                            Text(unit.subtitle)
                                .font(DS.captionFont)
                                .foregroundStyle(DS.textSecondary)

                            Text("\(unit.estimatedMinutes) min")
                                .font(DS.smallFont)
                                .foregroundStyle(DS.textTertiary)
                        }
                        .frame(width: 190, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: DS.cardCorner)
                                .fill(.white.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.cardCorner)
                                        .stroke(unit.color.opacity(0.16), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, DS.padding)
            }
        }
    }

    private var unitTreeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Unit Tree")
                .font(DS.headlineFont)
                .foregroundStyle(DS.textPrimary)
                .padding(.horizontal, DS.padding)

            VStack(spacing: 0) {
                ForEach(Array(CourseData.units.enumerated()), id: \.element.id) { index, unit in
                    LightningTreeNode(
                        unit: unit,
                        completedCount: unit.lessons.filter { progress.isLessonCompleted($0.id) }.count,
                        isLeading: index.isMultiple(of: 2)
                    ) {
                        selectedUnitSheet = unit
                    }

                    if index < CourseData.units.count - 1 {
                        Rectangle()
                            .fill(DS.primary.opacity(0.18))
                            .frame(width: 4, height: 34)
                            .clipShape(Capsule())
                            .frame(maxWidth: .infinity, alignment: index.isMultiple(of: 2) ? .leading : .trailing)
                            .padding(.horizontal, 64)
                    }
                }
            }
            .padding(.horizontal, DS.padding)
        }
    }

    private var graduationCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sparky's Final Chapter")
                    .font(DS.headlineFont)
                    .foregroundStyle(DS.textPrimary)

                Text("Sparky started reckless and unsure. You helped him finish the journey with discipline, safer habits, and real electronics knowledge.")
                    .font(DS.bodyFont)
                    .foregroundStyle(DS.textSecondary)

                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(LinearGradient(colors: [DS.primaryLight, DS.accentSoft], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 150)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("SparkLearn Certificate")
                                .font(DS.headlineFont)
                                .foregroundStyle(DS.textPrimary)
                            Text("Electronics and Hardware")
                                .font(DS.bodyFont)
                                .foregroundStyle(DS.textSecondary)
                            Text(auth.currentUser?.displayName ?? "Learner")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(DS.primary)
                        }
                    }
            }
        }
        .padding(.horizontal, DS.padding)
    }

    private func statPill(icon: String, value: String, color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .contentTransition(.numericText())
        }
    }

    private func dashboardActionButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DS.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(DS.primaryLight))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DS.captionFont)
                        .foregroundStyle(DS.textPrimary)
                    Text(subtitle)
                        .font(DS.smallFont)
                        .foregroundStyle(DS.textSecondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(.white.opacity(0.88))
            )
        }
    }

    // MARK: - Continue Learning Card
    private func continueLearningCard(_ lesson: Lesson, unit: CourseUnit) -> some View {
        NavigationLink(destination: ExerciseSessionView(lesson: lesson, unitColor: unit.color)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Continue Learning")
                        .font(DS.captionFont)
                        .foregroundColor(unit.color)
                        .textCase(.uppercase)
                        .tracking(1)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(unit.color)
                }

                Text(lesson.title)
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)

                Text(unit.title + " · " + unit.subtitle)
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)

                Text(lesson.summary)
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)

                let unitLessons = unit.lessons
                let completedCount = unitLessons.filter { progress.isLessonCompleted($0.id) }.count
                ProgressBar(progress: Double(completedCount) / Double(max(1, unitLessons.count)), color: unit.color)
            }
            .padding(DS.padding)
            .background(
                RoundedRectangle(cornerRadius: DS.cardCorner)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardCorner)
                            .stroke(unit.color.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: unit.color.opacity(0.12), radius: 12, y: 4)
            )
        }
        .contextMenu {
            Button("Start Lesson", systemImage: "play.fill") {
                Haptics.light()
            }
            Button("Preview Lesson", systemImage: "doc.text.magnifyingglass") {
                selectedLessonSheet = LessonSheetItem(lesson: lesson, unit: unit)
            }
        }
    }

    // MARK: - Unit Card
    private func unitCard(_ unit: CourseUnit) -> some View {
        let unitLessons = unit.lessons
        let completedCount = unitLessons.filter { progress.isLessonCompleted($0.id) }.count
        let allDone = completedCount == unitLessons.count

        return VStack(alignment: .leading, spacing: 16) {
            // Unit header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(allDone ? DS.success.opacity(0.1) : DS.primary.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: allDone ? "checkmark" : unit.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(allDone ? DS.success : DS.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unit \(unit.number)")
                        .font(DS.smallFont)
                        .foregroundColor(DS.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(unit.title)
                        .font(DS.headlineFont)
                        .foregroundColor(DS.textPrimary)
                }

                Spacer()

                Text("\(completedCount)/\(unitLessons.count)")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textTertiary)
            }

            // Lessons list
            VStack(spacing: 0) {
                ForEach(Array(unitLessons.enumerated()), id: \.element.id) { idx, lesson in
                    let completed = progress.isLessonCompleted(lesson.id)

                    NavigationLink(destination: ExerciseSessionView(lesson: lesson, unitColor: unit.color)) {
                        HStack(spacing: 14) {
                            // Status circle
                            ZStack {
                                Circle()
                                    .fill(completed ? DS.success : DS.border)
                                    .frame(width: 34, height: 34)

                                if completed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(idx + 1)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(DS.textSecondary)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(lesson.title)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(DS.textPrimary)

                                Text("\(lesson.exercises.count) exercises · \(lesson.estimatedMinutes) min")
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.textTertiary)
                            }

                            Spacer()

                            // Score stars
                            if let pct = progress.scoreForLesson(lesson.id) {
                                HStack(spacing: 1) {
                                    ForEach(0..<3, id: \.self) { star in
                                        Image(systemName: pct >= [34, 67, 100][star] ? "star.fill" : "star")
                                            .font(.system(size: 10))
                                            .foregroundColor(.orange)
                                    }
                                }
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(DS.textTertiary)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .contextMenu {
                        Button("Start Lesson", systemImage: "play.fill") {
                            Haptics.light()
                        }
                        Button("Lesson Details", systemImage: "info.circle") {
                            selectedLessonSheet = LessonSheetItem(lesson: lesson, unit: unit)
                        }
                    }

                    if idx < unitLessons.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .padding(DS.padding)
        .background(
            RoundedRectangle(cornerRadius: DS.cardCorner)
                .fill(DS.cardBg)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
    }

    // Find the next incomplete lesson
    private func findNextLesson() -> (lesson: Lesson, unit: CourseUnit)? {
        if let lastOpenedLessonID = progress.lastOpenedLessonID {
            for unit in CourseData.units {
                for lesson in unit.lessons where lesson.id.uuidString == lastOpenedLessonID && !progress.isLessonCompleted(lesson.id) {
                    return (lesson, unit)
                }
            }
        }

        for unit in CourseData.units {
            for lesson in unit.lessons {
                if !progress.isLessonCompleted(lesson.id) {
                    return (lesson, unit)
                }
            }
        }
        return nil
    }
}

// MARK: - Profile View (clean, minimal)
struct ProfileView: View {
    @EnvironmentObject var progress: ProgressManager
    @EnvironmentObject var auth: AuthManager
    @State private var appeared = false
    @State private var showDeleteConfirm = false
    @State private var showSettingsSheet = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.heroBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Avatar
                        VStack(spacing: 12) {
                            MascotView(size: 80, mood: .celebrating)

                            Text(auth.currentUser?.displayName ?? "Learner")
                                .font(DS.titleFont)
                                .foregroundColor(DS.textPrimary)

                            if let email = auth.currentUser?.email {
                                Text(email)
                                    .font(DS.captionFont)
                                    .foregroundColor(DS.textTertiary)
                            }

                            Text("Level \(progress.level)")
                                .font(DS.captionFont)
                                .foregroundColor(DS.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(DS.primaryLight))
                        }
                        .padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -10)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            profileStat(icon: "bolt.fill", value: "\(progress.totalXP)", label: "Total XP", color: DS.primary)
                            profileStat(icon: "flame.fill", value: "\(progress.currentStreak)", label: "Day Streak", color: .orange)
                            profileStat(icon: "checkmark.circle.fill", value: "\(progress.completedLessons.count)", label: "Lessons Done", color: DS.success)
                            profileStat(icon: "star.fill", value: "Lv.\(progress.level)", label: "Level", color: .purple)
                        }
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)

                        // Level progress
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Level \(progress.level)")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(DS.textPrimary)
                                    Spacer()
                                    Text("\(progress.xpInCurrentLevel)/\(progress.xpPerLevel) XP")
                                        .font(DS.captionFont)
                                        .foregroundColor(DS.textSecondary)
                                }
                                ProgressBar(progress: progress.xpProgressFraction)
                            }
                        }
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)

                        CardView {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text("Learning Profile")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(DS.textPrimary)
                                    Spacer()
                                    Button("Edit") {
                                        showEditProfile = true
                                    }
                                    .font(DS.captionFont)
                                    .foregroundStyle(DS.primary)
                                }

                                profilePreferenceRow(title: "Stage", value: auth.currentUser?.learnerStage.title ?? "Beginner")
                                profilePreferenceRow(title: "Goal", value: auth.currentUser?.learningGoal.title ?? "Understand Basics")
                                profilePreferenceRow(title: "Focus", value: auth.currentUser?.focusArea ?? "Circuits")
                            }
                        }
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)

                        // Overall progress
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                let total = CourseData.units.flatMap(\.lessons).count
                                let done = progress.completedLessons.count
                                HStack {
                                    Text("Course Progress")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(DS.textPrimary)
                                    Spacer()
                                    Text("\(done)/\(total) lessons")
                                        .font(DS.captionFont)
                                        .foregroundColor(DS.textSecondary)
                                }
                                ProgressBar(progress: total > 0 ? Double(done)/Double(total) : 0, color: DS.success)
                            }
                        }
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)

                        // Account section
                        CardView {
                            VStack(spacing: 0) {
                                settingRow(icon: "bell", title: "Notifications")
                                Divider().padding(.leading, 40)
                                settingRow(icon: "slider.horizontal.3", title: "App Settings") {
                                    showSettingsSheet = true
                                }
                                Divider().padding(.leading, 40)
                                settingRow(icon: "arrow.counterclockwise", title: "Restore Purchases")
                                Divider().padding(.leading, 40)
                                settingRow(icon: "questionmark.circle", title: "Help & Feedback")
                                Divider().padding(.leading, 40)

                                // Sign Out
                                Button(action: {
                                    Haptics.medium()
                                    auth.signOut()
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(DS.error)
                                            .frame(width: 24)
                                        Text("Sign Out")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(DS.error)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                }

                                Divider().padding(.leading, 40)

                                // Delete Account
                                Button(action: { showDeleteConfirm = true }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 16, weight: .regular))
                                            .foregroundColor(DS.textTertiary)
                                            .frame(width: 24)
                                        Text("Delete Account")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundColor(DS.textTertiary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                }
                            }
                        }
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    auth.deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all progress. This cannot be undone.")
            }
            .sheet(isPresented: $showSettingsSheet) {
                AppSettingsSheet()
                    .environmentObject(progress)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showEditProfile) {
                ProfilePreferencesSheet()
                    .environmentObject(auth)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func profileStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(DS.smallFont)
                .foregroundColor(DS.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.06), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: DS.cornerRadius))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }

    private func settingRow(icon: String, title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(DS.textSecondary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.textTertiary)
            }
            .padding(.vertical, 14)
        }
    }

    private func profilePreferenceRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(DS.captionFont)
                .foregroundStyle(DS.textSecondary)
            Spacer()
            Text(value)
                .font(DS.captionFont)
                .foregroundStyle(DS.textPrimary)
        }
    }
}

struct AppSettingsSheet: View {
    @EnvironmentObject var progress: ProgressManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    Toggle("Daily Reminder", isOn: Binding(
                        get: { progress.dailyReminderEnabled },
                        set: { progress.updateDailyReminderEnabled($0) }
                    ))

                    Toggle("Notifications Enabled", isOn: Binding(
                        get: { progress.notificationsEnabled },
                        set: { progress.updateNotificationsEnabled($0) }
                    ))

                    if progress.dailyReminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: { progress.reminderTime },
                                set: { progress.updateReminderTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section("Experience") {
                    Toggle("Immersive Learning", isOn: Binding(
                        get: { progress.immersiveLearningEnabled },
                        set: { progress.updateImmersiveLearningEnabled($0) }
                    ))
                    Toggle("Sound Effects", isOn: Binding(
                        get: { progress.soundEffectsEnabled },
                        set: { progress.updateSoundEffectsEnabled($0) }
                    ))
                    Toggle("Haptics", isOn: Binding(
                        get: { progress.hapticsEnabled },
                        set: { progress.updateHapticsEnabled($0) }
                    ))
                    Toggle("Reduced Motion", isOn: Binding(
                        get: { progress.reducedMotionEnabled },
                        set: { progress.updateReducedMotionEnabled($0) }
                    ))
                }

                Section("Learning Goal") {
                    Stepper(value: Binding(
                        get: { progress.dailyXPGoal },
                        set: { progress.updateDailyXPGoal($0) }
                    ), in: 30...300, step: 30) {
                        Text("Daily Target: \(progress.dailyXPGoal) XP")
                    }
                }
            }
            .navigationTitle("App Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct PracticeView: View {
    @EnvironmentObject var progress: ProgressManager
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                DS.heroBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Practice Hub")
                                    .font(DS.headlineFont)
                                    .foregroundStyle(DS.textPrimary)
                                Text("Review concepts, keep streaks alive, and strengthen weak areas for \(auth.currentUser?.learningGoal.title.lowercased() ?? "your goal").")
                                    .font(DS.bodyFont)
                                    .foregroundStyle(DS.textSecondary)
                                ProgressBar(progress: progress.dailyXPProgress, color: .orange)
                            }
                        }
                        .padding(.horizontal, DS.padding)

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Best Combo: x\(max(progress.bestCombo, progress.currentCombo))", systemImage: "flame.fill")
                                    .foregroundStyle(.orange)
                                Label("Today's XP: \(progress.dailyXP)", systemImage: "bolt.fill")
                                    .foregroundStyle(DS.primary)
                            }
                        }
                        .padding(.horizontal, DS.padding)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Review")
                                .font(DS.headlineFont)
                                .foregroundStyle(DS.textPrimary)
                                .padding(.horizontal, DS.padding)

                            ForEach(recommendedLessons, id: \.lesson.id) { item in
                                NavigationLink(destination: ExerciseSessionView(lesson: item.lesson, unitColor: item.unit.color)) {
                                    CardView {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text(item.unit.title)
                                                    .font(DS.smallFont)
                                                    .foregroundStyle(item.unit.color)
                                                Spacer()
                                                Text(item.lesson.stage.title)
                                                    .font(DS.smallFont)
                                                    .foregroundStyle(DS.textTertiary)
                                            }

                                            Text(item.lesson.title)
                                                .font(DS.headlineFont)
                                                .foregroundStyle(DS.textPrimary)

                                            Text(item.lesson.summary)
                                                .font(DS.captionFont)
                                                .foregroundStyle(DS.textSecondary)

                                            Text("\(item.lesson.estimatedMinutes) min · \(item.lesson.skillTags.joined(separator: " • "))")
                                                .font(DS.smallFont)
                                                .foregroundStyle(DS.textTertiary)
                                        }
                                    }
                                }
                                .padding(.horizontal, DS.padding)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
                .padding(.top, 20)
            }
            .navigationTitle("Practice")
        }
    }

    private var recommendedLessons: [(unit: CourseUnit, lesson: Lesson)] {
        let scored = CourseData.units.flatMap { unit in
            unit.lessons.map { lesson in
                (unit: unit, lesson: lesson, score: progress.scoreForLesson(lesson.id) ?? 0)
            }
        }

        let incomplete = scored.filter { !progress.isLessonCompleted($0.lesson.id) }
        let lowScore = scored.filter { ($0.score > 0 && $0.score < 70) }
        let source = incomplete.isEmpty ? lowScore : incomplete
        return Array(source.prefix(4)).map { ($0.unit, $0.lesson) }
    }
}

private struct CurriculumTierRow: View {
    let tier: CurriculumTier
    let summary: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tier.icon)
                .foregroundStyle(DS.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.title)
                    .font(DS.captionFont)
                    .foregroundStyle(DS.textPrimary)
                Text(summary)
                    .font(DS.smallFont)
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
        }
    }
}

private enum DashboardSheet: String, Identifiable {
    case curriculum
    case dailyGoal

    var id: String { rawValue }
}

private struct LightningTreeNode: View {
    let unit: CourseUnit
    let completedCount: Int
    let isLeading: Bool
    let action: () -> Void

    private var completionPct: Double {
        Double(completedCount) / Double(max(1, unit.lessons.count))
    }

    private var isComplete: Bool { completedCount == unit.lessons.count }

    var body: some View {
        HStack {
            if !isLeading { Spacer(minLength: 54) }

            Button(action: action) {
                HStack(spacing: 14) {
                    // Progress ring around bolt circle
                    ZStack {
                        Circle()
                            .fill(unit.color.opacity(0.1))
                            .frame(width: 72, height: 72)

                        // Progress ring
                        Circle()
                            .stroke(unit.color.opacity(0.1), lineWidth: 4)
                            .frame(width: 72, height: 72)

                        Circle()
                            .trim(from: 0, to: completionPct)
                            .stroke(
                                isComplete ? DS.success : unit.color,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: isComplete ? "checkmark" : "bolt.fill")
                            .font(.system(size: isComplete ? 24 : 28, weight: .bold))
                            .foregroundStyle(isComplete ? DS.success : unit.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unit \(unit.number)")
                            .font(DS.smallFont)
                            .foregroundStyle(DS.textTertiary)
                        Text(unit.title)
                            .font(DS.headlineFont)
                            .foregroundStyle(DS.textPrimary)
                        Text("\(completedCount)/\(unit.lessons.count) lessons")
                            .font(DS.captionFont)
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardCorner)
                        .fill(.white.opacity(0.92))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardCorner)
                                .stroke(unit.color.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: unit.color.opacity(0.08), radius: 8, y: 4)
                )
            }

            if isLeading { Spacer(minLength: 54) }
        }
    }
}

private struct CurriculumOverviewSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Curriculum Map")
                        .font(DS.titleFont)
                        .foregroundStyle(DS.textPrimary)

                    Text("Built for \(auth.currentUser?.learnerStage.title ?? "Beginner") learners.")
                        .font(DS.captionFont)
                        .foregroundStyle(DS.textSecondary)

                    ForEach(CurriculumTier.allCases, id: \.self) { tier in
                        let units = CourseData.units.filter { $0.tier == tier }
                        if !units.isEmpty {
                            CardView {
                                VStack(alignment: .leading, spacing: 10) {
                                    CurriculumTierRow(
                                        tier: tier,
                                        summary: "\(units.count) units · \(units.reduce(0) { $0 + $1.lessons.count }) lessons"
                                    )
                                    ForEach(units, id: \.id) { unit in
                                        Text("• \(unit.title)")
                                            .font(DS.captionFont)
                                            .foregroundStyle(DS.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(DS.padding)
            }
            .navigationTitle("Curriculum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DailyGoalSheet: View {
    @EnvironmentObject var progress: ProgressManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Daily Goal")
                            .font(DS.headlineFont)
                            .foregroundStyle(DS.textPrimary)
                        Text("\(progress.dailyXP)/\(progress.dailyXPGoal) XP today")
                            .font(DS.bodyFont)
                            .foregroundStyle(DS.textSecondary)
                        ProgressBar(progress: progress.dailyXPProgress, color: .orange)
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Adjust target")
                            .font(DS.captionFont)
                            .foregroundStyle(DS.textSecondary)
                        Stepper("Target: \(progress.dailyXPGoal) XP", value: Binding(
                            get: { progress.dailyXPGoal },
                            set: { progress.updateDailyXPGoal($0) }
                        ), in: 30...300, step: 30)
                    }
                }

                Spacer()
            }
            .padding(DS.padding)
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct UnitTreeSheet: View {
    let unit: CourseUnit
    @EnvironmentObject var progress: ProgressManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(unit.lessons) { lesson in
                NavigationLink(destination: ExerciseSessionView(lesson: lesson, unitColor: unit.color)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                        Text("\(lesson.exercises.count) exercises · \(lesson.estimatedMinutes) min")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(DS.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(unit.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ProfilePreferencesSheet: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var learnerStage: LearnerStage = .beginner
    @State private var learningGoal: LearningGoal = .understandBasics
    @State private var focusArea = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                    TextField("Focus Area", text: $focusArea)
                }

                Section("Learning") {
                    Picker("Stage", selection: $learnerStage) {
                        ForEach(LearnerStage.allCases, id: \.self) { stage in
                            Text(stage.title).tag(stage)
                        }
                    }

                    Picker("Goal", selection: $learningGoal) {
                        ForEach(LearningGoal.allCases, id: \.self) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        auth.completeProfile(
                            name: name,
                            learnerStage: learnerStage,
                            learningGoal: learningGoal,
                            focusArea: focusArea
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = auth.currentUser?.displayName ?? ""
                learnerStage = auth.currentUser?.learnerStage ?? .beginner
                learningGoal = auth.currentUser?.learningGoal ?? .understandBasics
                focusArea = auth.currentUser?.focusArea ?? "Circuits"
            }
        }
    }
}

private struct LessonSheetItem: Identifiable {
    let id = UUID()
    let lesson: Lesson
    let unit: CourseUnit
}

private struct LessonQuickSheet: View {
    let lesson: Lesson
    let unit: CourseUnit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text(lesson.title)
                    .font(DS.titleFont)
                    .foregroundStyle(DS.textPrimary)
                Text("\(unit.title) · \(lesson.exercises.count) exercises")
                    .font(DS.bodyFont)
                    .foregroundStyle(DS.textSecondary)
                Text("This lesson focuses on quick concept checks with immediate feedback and rewards.")
                    .font(DS.captionFont)
                    .foregroundStyle(DS.textSecondary)

                Spacer()
            }
            .padding(DS.padding)
            .navigationTitle("Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct DashboardScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    HomeView()
        .environmentObject(ProgressManager())
        .environmentObject(AuthManager())
}
