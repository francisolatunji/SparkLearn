import SwiftUI

// MARK: - Classroom Role

enum ClassroomRole: String, Codable {
    case teacher
    case student
}

// MARK: - Classroom Member

struct ClassroomMember: Identifiable {
    let id: String
    let name: String
    let avatar: String
    let role: ClassroomRole
    let level: Int
    let progress: Double
    let weeklyXP: Int
    let lessonsCompleted: Int
    let totalLessons: Int
}

// MARK: - Classroom Assignment

struct ClassroomAssignment: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let dueDate: Date
    let unitName: String
    var isCompleted: Bool
    let pointsValue: Int

    var isOverdue: Bool {
        !isCompleted && Date() > dueDate
    }

    var dueDateFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dueDate, relativeTo: Date())
    }
}

// MARK: - Classroom Model

struct Classroom: Identifiable {
    let id: String
    let name: String
    let code: String
    let teacherName: String
    let teacherAvatar: String
    let members: [ClassroomMember]
    let assignments: [ClassroomAssignment]
    let createdAt: Date
}

// MARK: - Classroom View

struct ClassroomView: View {
    @State private var currentRole: ClassroomRole = .student
    @State private var classroom: Classroom?
    @State private var joinCode = ""
    @State private var showJoinSheet = false
    @State private var showCreateSheet = false
    @State private var showAssignSheet = false
    @State private var showAnalytics = false
    @State private var selectedTab = 0
    @State private var animateIn = false
    @State private var joinError = false
    @State private var newClassName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: DS.padding) {
                if let classroom = classroom {
                    classroomContent(classroom)
                } else {
                    noClassroomView
                }
            }
            .padding(.horizontal, DS.padding)
            .padding(.bottom, 100)
        }
        .background(DS.heroBackground.ignoresSafeArea())
        .onAppear {
            loadSimulatedClassroom()
            withAnimation(DS.transitionAnim.delay(0.1)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            joinClassroomSheet
        }
        .sheet(isPresented: $showCreateSheet) {
            createClassroomSheet
        }
        .sheet(isPresented: $showAssignSheet) {
            assignLessonSheet
        }
        .sheet(isPresented: $showAnalytics) {
            analyticsSheet
        }
    }

    // MARK: - No Classroom

    private var noClassroomView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            MascotWithMessage(
                message: "Join a classroom to learn with your class!",
                mood: .encouraging,
                mascotSize: 100
            )

            VStack(spacing: 12) {
                PrimaryButton("Join with Code", icon: "keyboard") {
                    Haptics.light()
                    SoundCue.tap()
                    showJoinSheet = true
                }

                SecondaryButton("Create Classroom", icon: "plus.circle") {
                    Haptics.light()
                    SoundCue.tap()
                    showCreateSheet = true
                }
            }

            Text("Teachers can create classrooms.\nStudents join with a class code.")
                .font(DS.captionFont)
                .foregroundColor(DS.textTertiary)
                .multilineTextAlignment(.center)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }

    // MARK: - Classroom Content

    @ViewBuilder
    private func classroomContent(_ classroom: Classroom) -> some View {
        classroomHeader(classroom)
        classroomTabBar
        switch selectedTab {
        case 0: membersSection(classroom)
        case 1: leaderboardSection(classroom)
        case 2: assignmentsSection(classroom)
        default: EmptyView()
        }
        if currentRole == .teacher {
            teacherControls
        }
    }

    // MARK: - Classroom Header

    private func classroomHeader(_ classroom: Classroom) -> some View {
        CardView(accent: DS.primary) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(classroom.name)
                            .font(DS.titleFont)
                            .foregroundColor(DS.textPrimary)

                        HStack(spacing: 6) {
                            Text(classroom.teacherAvatar)
                                .font(.system(size: 16))
                            Text(classroom.teacherName)
                                .font(DS.captionFont)
                                .foregroundColor(DS.textSecondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(DS.primary)
                            Text("\(classroom.members.count)")
                                .font(DS.captionFont)
                                .foregroundColor(DS.textSecondary)
                        }

                        Button(action: {
                            Haptics.light()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                Text(classroom.code)
                                    .font(.system(size: 12, weight: .mono == nil ? .medium : .medium, design: .monospaced))
                            }
                            .foregroundColor(DS.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(DS.primary.opacity(0.1))
                            )
                        }
                    }
                }

                // Role badge
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: currentRole == .teacher ? "graduationcap.fill" : "person.fill")
                            .font(.system(size: 11))
                        Text(currentRole == .teacher ? "Teacher" : "Student")
                            .font(DS.smallFont)
                    }
                    .foregroundColor(currentRole == .teacher ? DS.deepPurple : DS.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill((currentRole == .teacher ? DS.deepPurple : DS.primary).opacity(0.1))
                    )

                    Spacer()

                    // Toggle for demo
                    Button(action: {
                        Haptics.light()
                        withAnimation(DS.feedbackAnim) {
                            currentRole = currentRole == .teacher ? .student : .teacher
                        }
                    }) {
                        Text("Switch to \(currentRole == .teacher ? "Student" : "Teacher")")
                            .font(DS.smallFont)
                            .foregroundColor(DS.textTertiary)
                    }
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
    }

    // MARK: - Tab Bar

    private var classroomTabBar: some View {
        let tabs = ["Members", "Leaderboard", "Assignments"]

        return HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    Haptics.light()
                    withAnimation(DS.feedbackAnim) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                            .foregroundColor(selectedTab == index ? DS.primary : DS.textSecondary)

                        Rectangle()
                            .fill(selectedTab == index ? DS.primary : Color.clear)
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
        .animation(DS.transitionAnim.delay(0.1), value: animateIn)
    }

    // MARK: - Members Section

    private func membersSection(_ classroom: Classroom) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Class Members")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            ForEach(Array(classroom.members.enumerated()), id: \.element.id) { index, member in
                memberRow(member)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 15)
                    .animation(DS.transitionAnim.delay(0.15 + Double(index) * 0.04), value: animateIn)
            }
        }
    }

    private func memberRow(_ member: ClassroomMember) -> some View {
        CardView {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Text(member.avatar)
                        .font(.system(size: 36))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(member.name)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(DS.textPrimary)

                            if member.role == .teacher {
                                Text("Teacher")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.deepPurple)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(DS.deepPurple.opacity(0.12))
                                    )
                            }
                        }

                        HStack(spacing: 10) {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(DS.gold)
                                Text("Lvl \(member.level)")
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.textSecondary)
                            }

                            Text("\(member.lessonsCompleted)/\(member.totalLessons) lessons")
                                .font(DS.smallFont)
                                .foregroundColor(DS.textTertiary)
                        }
                    }

                    Spacer()

                    if currentRole == .teacher && member.role != .teacher {
                        Menu {
                            Button(action: {
                                Haptics.light()
                                showAnalytics = true
                            }) {
                                Label("View Progress", systemImage: "chart.bar.fill")
                            }
                            Button(role: .destructive, action: {
                                Haptics.error()
                            }) {
                                Label("Remove Student", systemImage: "person.badge.minus")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(DS.textTertiary)
                                .frame(width: 32, height: 32)
                        }
                    }
                }

                ProgressBar(progress: member.progress, color: DS.primary, height: 6)
            }
        }
    }

    // MARK: - Leaderboard Section

    private func leaderboardSection(_ classroom: Classroom) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Class Leaderboard")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            let sorted = classroom.members
                .filter { $0.role == .student }
                .sorted { $0.weeklyXP > $1.weeklyXP }

            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, member in
                leaderboardRow(member, rank: index + 1)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 15)
                    .animation(DS.transitionAnim.delay(0.15 + Double(index) * 0.04), value: animateIn)
            }
        }
    }

    private func leaderboardRow(_ member: ClassroomMember, rank: Int) -> some View {
        HStack(spacing: 12) {
            // Rank medal
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor(rank).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Text(rankEmoji(rank))
                        .font(.system(size: 18))
                } else {
                    Circle()
                        .fill(DS.divider)
                        .frame(width: 36, height: 36)

                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                }
            }

            Text(member.avatar)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Text("Lvl \(member.level)")
                    .font(DS.smallFont)
                    .foregroundColor(DS.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.weeklyXP)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(rank <= 3 ? rankColor(rank) : DS.textPrimary)

                Text("XP this week")
                    .font(DS.smallFont)
                    .foregroundColor(DS.textTertiary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(rank <= 3 ? rankColor(rank).opacity(0.04) : DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                        .stroke(rank <= 3 ? rankColor(rank).opacity(0.2) : Color.clear, lineWidth: 1)
                )
                .shadow(color: DS.cardShadow, radius: 6, y: 3)
        )
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return DS.gold
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return DS.textSecondary
        }
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    // MARK: - Assignments Section

    private func assignmentsSection(_ classroom: Classroom) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assignments")
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)

                Spacer()

                if currentRole == .teacher {
                    Button(action: {
                        Haptics.light()
                        SoundCue.tap()
                        showAssignSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Assign")
                                .font(DS.smallFont)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(DS.primary)
                        )
                    }
                }
            }

            if classroom.assignments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(DS.textTertiary)
                    Text("No assignments yet")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(Array(classroom.assignments.enumerated()), id: \.element.id) { index, assignment in
                    assignmentCard(assignment)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 15)
                        .animation(DS.transitionAnim.delay(0.15 + Double(index) * 0.05), value: animateIn)
                }
            }
        }
    }

    private func assignmentCard(_ assignment: ClassroomAssignment) -> some View {
        CardView(accent: assignment.isCompleted ? DS.success : assignment.isOverdue ? DS.error : DS.primary) {
            HStack(spacing: 14) {
                Image(systemName: assignment.icon)
                    .font(.system(size: 22))
                    .foregroundColor(assignment.isCompleted ? DS.success : assignment.isOverdue ? DS.error : DS.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((assignment.isCompleted ? DS.success : assignment.isOverdue ? DS.error : DS.primary).opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)
                        .strikethrough(assignment.isCompleted)

                    Text(assignment.unitName)
                        .font(DS.smallFont)
                        .foregroundColor(DS.textSecondary)

                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(assignment.dueDateFormatted)
                                .font(DS.smallFont)
                        }
                        .foregroundColor(assignment.isOverdue ? DS.error : DS.textTertiary)

                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("+\(assignment.pointsValue) XP")
                                .font(DS.smallFont)
                        }
                        .foregroundColor(DS.gold)
                    }
                }

                Spacer()

                if assignment.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DS.success)
                } else {
                    Button(action: {
                        Haptics.medium()
                        SoundCue.tap()
                    }) {
                        Text("Start")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(DS.primary)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Teacher Controls

    private var teacherControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teacher Controls")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                teacherControlButton(
                    title: "Assign Lesson",
                    icon: "doc.badge.plus",
                    color: DS.primary
                ) {
                    showAssignSheet = true
                }

                teacherControlButton(
                    title: "View Analytics",
                    icon: "chart.bar.fill",
                    color: DS.deepPurple
                ) {
                    showAnalytics = true
                }

                teacherControlButton(
                    title: "Share Code",
                    icon: "qrcode",
                    color: DS.accent
                ) {
                    // Share action
                }

                teacherControlButton(
                    title: "Class Settings",
                    icon: "gearshape.fill",
                    color: DS.textSecondary
                ) {
                    // Settings action
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 15)
        .animation(DS.transitionAnim.delay(0.3), value: animateIn)
    }

    private func teacherControlButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.light()
            SoundCue.tap()
            action()
        }) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.12))
                    )

                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DS.cornerRadius)
                    .fill(DS.cardBg)
                    .shadow(color: DS.cardShadow, radius: 6, y: 3)
            )
        }
    }

    // MARK: - Join Classroom Sheet

    private var joinClassroomSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                MascotView(size: 80, mood: .happy)
                    .padding(.top, 24)

                Text("Join a Classroom")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                Text("Enter the class code from your teacher")
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Class Code")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)

                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(DS.textTertiary)

                        TextField("e.g. SPARK-2024", text: $joinCode)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .foregroundColor(DS.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .stroke(joinError ? DS.error : DS.border, lineWidth: 1.5)
                    )

                    if joinError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 11))
                            Text("Invalid code. Please check and try again.")
                                .font(DS.smallFont)
                        }
                        .foregroundColor(DS.error)
                    }
                }
                .padding(.horizontal, DS.padding)

                PrimaryButton("Join Classroom", icon: "door.left.hand.open") {
                    if joinCode.isEmpty {
                        Haptics.error()
                        joinError = true
                    } else {
                        Haptics.success()
                        SoundCue.success()
                        loadSimulatedClassroom()
                        showJoinSheet = false
                    }
                }
                .padding(.horizontal, DS.padding)

                Spacer()
            }
            .background(DS.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showJoinSheet = false }
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Create Classroom Sheet

    private var createClassroomSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                MascotView(size: 80, mood: .celebrating)
                    .padding(.top, 24)

                Text("Create a Classroom")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Classroom Name")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)

                    HStack {
                        Image(systemName: "building.columns")
                            .foregroundColor(DS.textTertiary)

                        TextField("e.g. Electrical 101", text: $newClassName)
                            .font(DS.bodyFont)
                            .foregroundColor(DS.textPrimary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: DS.cornerRadius)
                            .stroke(DS.border, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, DS.padding)

                PrimaryButton("Create Classroom", icon: "plus.circle.fill") {
                    Haptics.success()
                    SoundCue.success()
                    currentRole = .teacher
                    loadSimulatedClassroom()
                    showCreateSheet = false
                }
                .padding(.horizontal, DS.padding)

                Spacer()
            }
            .background(DS.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showCreateSheet = false }
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Assign Lesson Sheet

    private var assignLessonSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select a lesson to assign")
                        .font(DS.headlineFont)
                        .foregroundColor(DS.textPrimary)
                        .padding(.top, 8)

                    let lessons: [(name: String, unit: String, icon: String)] = [
                        ("Ohm's Law Basics", "Unit 1: Foundations", "function"),
                        ("Series Circuits", "Unit 2: Circuit Types", "arrow.triangle.branch"),
                        ("Parallel Circuits", "Unit 2: Circuit Types", "arrow.triangle.branch"),
                        ("Electrical Safety", "Unit 3: Safety", "shield.checkered"),
                        ("Power Calculations", "Unit 4: Power", "battery.100.bolt"),
                        ("Reading Resistor Codes", "Unit 5: Components", "rectangle.split.3x3"),
                        ("AC vs DC Current", "Unit 6: Advanced", "waveform.path"),
                        ("Multimeter Usage", "Unit 7: Tools", "gauge.with.dots.needle.33percent"),
                    ]

                    ForEach(Array(lessons.enumerated()), id: \.offset) { _, lesson in
                        Button(action: {
                            Haptics.medium()
                            SoundCue.success()
                            showAssignSheet = false
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: lesson.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(DS.primary)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(DS.primary.opacity(0.12))
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(lesson.name)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(DS.textPrimary)
                                    Text(lesson.unit)
                                        .font(DS.smallFont)
                                        .foregroundColor(DS.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle")
                                    .foregroundColor(DS.primary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: DS.cornerRadius)
                                    .fill(DS.cardBg)
                                    .shadow(color: DS.cardShadow, radius: 4, y: 2)
                            )
                        }
                    }
                }
                .padding(DS.padding)
            }
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("Assign Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAssignSheet = false }
                        .font(DS.captionFont)
                        .foregroundColor(DS.primary)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Analytics Sheet

    private var analyticsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.padding) {
                    // Summary cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        analyticsStat(title: "Avg. Score", value: "78%", icon: "chart.bar.fill", color: DS.primary)
                        analyticsStat(title: "Completion", value: "64%", icon: "checkmark.circle.fill", color: DS.success)
                        analyticsStat(title: "Active Today", value: "12", icon: "person.2.fill", color: DS.accent)
                        analyticsStat(title: "Avg. Streak", value: "5 days", icon: "flame.fill", color: DS.warning)
                    }

                    // Top performers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Performers")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)

                        let topStudents: [(name: String, avatar: String, score: Int)] = [
                            ("Sarah W.", "👩‍🎓", 95),
                            ("Mike R.", "🧑‍💻", 91),
                            ("Emily K.", "👩‍🔬", 88),
                        ]

                        ForEach(Array(topStudents.enumerated()), id: \.offset) { index, student in
                            HStack(spacing: 12) {
                                Text(rankEmoji(index + 1))
                                    .font(.system(size: 20))

                                Text(student.avatar)
                                    .font(.system(size: 28))

                                Text(student.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(DS.textPrimary)

                                Spacer()

                                Text("\(student.score)%")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.primary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(DS.cardBg)
                                    .shadow(color: DS.cardShadow, radius: 4, y: 2)
                            )
                        }
                    }

                    // Struggling topics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Needs Attention")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)

                        let topics: [(name: String, avgScore: Int, color: Color)] = [
                            ("Parallel Circuits", 52, DS.error),
                            ("Power Calculations", 61, DS.warning),
                        ]

                        ForEach(Array(topics.enumerated()), id: \.offset) { _, topic in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(topic.color)
                                    .frame(width: 8, height: 8)

                                Text(topic.name)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(DS.textPrimary)

                                Spacer()

                                Text("Avg: \(topic.avgScore)%")
                                    .font(DS.captionFont)
                                    .foregroundColor(topic.color)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(topic.color.opacity(0.06))
                            )
                        }
                    }
                }
                .padding(DS.padding)
            }
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("Class Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAnalytics = false }
                        .font(DS.captionFont)
                        .foregroundColor(DS.primary)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func analyticsStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(DS.textPrimary)

            Text(title)
                .font(DS.smallFont)
                .foregroundColor(DS.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 6, y: 3)
        )
    }

    // MARK: - Simulated Data

    private func loadSimulatedClassroom() {
        let members: [ClassroomMember] = [
            ClassroomMember(id: "t1", name: "Prof. Martinez", avatar: "👨‍🏫", role: .teacher, level: 25, progress: 1.0, weeklyXP: 0, lessonsCompleted: 40, totalLessons: 40),
            ClassroomMember(id: "s1", name: "Sarah Williams", avatar: "👩‍🎓", role: .student, level: 14, progress: 0.82, weeklyXP: 580, lessonsCompleted: 33, totalLessons: 40),
            ClassroomMember(id: "s2", name: "Mike Rodriguez", avatar: "🧑‍💻", role: .student, level: 12, progress: 0.71, weeklyXP: 445, lessonsCompleted: 28, totalLessons: 40),
            ClassroomMember(id: "s3", name: "Emily Kim", avatar: "👩‍🔬", role: .student, level: 11, progress: 0.65, weeklyXP: 390, lessonsCompleted: 26, totalLessons: 40),
            ClassroomMember(id: "s4", name: "James Chen", avatar: "🧑‍🔧", role: .student, level: 9, progress: 0.55, weeklyXP: 310, lessonsCompleted: 22, totalLessons: 40),
            ClassroomMember(id: "s5", name: "Alex Turner", avatar: "👨‍💼", role: .student, level: 7, progress: 0.40, weeklyXP: 220, lessonsCompleted: 16, totalLessons: 40),
            ClassroomMember(id: "s6", name: "Lisa Park", avatar: "👩‍🔧", role: .student, level: 5, progress: 0.28, weeklyXP: 150, lessonsCompleted: 11, totalLessons: 40),
            ClassroomMember(id: "s7", name: "You", avatar: "⚡", role: .student, level: 10, progress: 0.60, weeklyXP: 350, lessonsCompleted: 24, totalLessons: 40),
        ]

        let assignments: [ClassroomAssignment] = [
            ClassroomAssignment(id: "a1", title: "Ohm's Law Quiz", description: "Complete the Ohm's Law lesson", icon: "function", dueDate: Date().addingTimeInterval(2 * 86400), unitName: "Unit 1: Foundations", isCompleted: true, pointsValue: 30),
            ClassroomAssignment(id: "a2", title: "Series Circuit Lab", description: "Build a series circuit", icon: "arrow.triangle.branch", dueDate: Date().addingTimeInterval(5 * 86400), unitName: "Unit 2: Circuit Types", isCompleted: false, pointsValue: 50),
            ClassroomAssignment(id: "a3", title: "Safety Assessment", description: "Pass the safety quiz with 80%+", icon: "shield.checkered", dueDate: Date().addingTimeInterval(7 * 86400), unitName: "Unit 3: Safety", isCompleted: false, pointsValue: 40),
            ClassroomAssignment(id: "a4", title: "Resistor Color Codes", description: "Identify 10 resistor values", icon: "rectangle.split.3x3", dueDate: Date().addingTimeInterval(-86400), unitName: "Unit 5: Components", isCompleted: false, pointsValue: 25),
        ]

        classroom = Classroom(
            id: "class_1",
            name: "Electrical Fundamentals 101",
            code: "SPARK-2024",
            teacherName: "Prof. Martinez",
            teacherAvatar: "👨‍🏫",
            members: members,
            assignments: assignments,
            createdAt: Date().addingTimeInterval(-30 * 86400)
        )
    }
}

// MARK: - Preview

#Preview {
    ClassroomView()
}
