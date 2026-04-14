import SwiftUI

// MARK: - Friend Model

struct Friend: Identifiable {
    let id: String
    let name: String
    let avatar: String
    let level: Int
    let currentStreak: Int
    let lastActive: Date
    let totalXP: Int

    var lastActiveFormatted: String {
        let interval = Date().timeIntervalSince(lastActive)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24

        if minutes < 5 { return "Active now" }
        if minutes < 60 { return "\(minutes)m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(days)d ago"
    }

    var isOnline: Bool {
        Date().timeIntervalSince(lastActive) < 300
    }
}

// MARK: - Friend Request Model

struct FriendRequest: Identifiable {
    let id: String
    let name: String
    let avatar: String
    let level: Int
    let sentAt: Date
}

// MARK: - Activity Feed Item

struct ActivityFeedItem: Identifiable {
    let id: String
    let friendName: String
    let friendAvatar: String
    let message: String
    let icon: String
    let iconColor: Color
    let timestamp: Date

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        let minutes = Int(interval) / 60
        let hours = minutes / 60

        if minutes < 60 { return "\(max(1, minutes))m ago" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Friends List View

struct FriendsListView: View {
    @State private var friends: [Friend] = []
    @State private var friendRequests: [FriendRequest] = []
    @State private var activityFeed: [ActivityFeedItem] = []
    @State private var searchText = ""
    @State private var showAddFriend = false
    @State private var addFriendUsername = ""
    @State private var showShareSheet = false
    @State private var showRequestsSection = true
    @State private var animateIn = false

    var filteredFriends: [Friend] {
        if searchText.isEmpty { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.padding) {
                headerSection
                searchBar
                if !friendRequests.isEmpty {
                    requestsSection
                }
                friendsSection
                activitySection
            }
            .padding(.horizontal, DS.padding)
            .padding(.bottom, 100)
        }
        .background(DS.heroBackground.ignoresSafeArea())
        .onAppear {
            loadSimulatedData()
            withAnimation(DS.transitionAnim.delay(0.1)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showAddFriend) {
            addFriendSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Friends")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                Text("\(friends.count) friends")
                    .font(DS.captionFont)
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            Button(action: {
                Haptics.light()
                SoundCue.tap()
                showAddFriend = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add")
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DS.textTertiary)
                .font(.system(size: 16))

            TextField("Search friends...", text: $searchText)
                .font(DS.bodyFont)
                .foregroundColor(DS.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DS.textTertiary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 8, y: 4)
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
    }

    // MARK: - Friend Requests

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(DS.feedbackAnim) {
                    showRequestsSection.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundColor(DS.accent)
                        Text("Friend Requests")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.textPrimary)
                    }

                    Spacer()

                    Text("\(friendRequests.count)")
                        .font(DS.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(DS.accent)
                        )

                    Image(systemName: showRequestsSection ? "chevron.up" : "chevron.down")
                        .foregroundColor(DS.textTertiary)
                        .font(.system(size: 12, weight: .semibold))
                }
            }

            if showRequestsSection {
                ForEach(friendRequests) { request in
                    requestRow(request)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
        }
        .padding(DS.padding)
        .background(
            RoundedRectangle(cornerRadius: DS.cardCorner)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 12, y: 6)
        )
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 15)
    }

    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            Text(request.avatar)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text(request.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.textPrimary)

                Text("Level \(request.level)")
                    .font(DS.smallFont)
                    .foregroundColor(DS.textSecondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: {
                    Haptics.success()
                    SoundCue.success()
                    withAnimation(DS.feedbackAnim) {
                        acceptRequest(request)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(DS.success))
                }

                Button(action: {
                    Haptics.light()
                    withAnimation(DS.feedbackAnim) {
                        declineRequest(request)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DS.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(DS.divider))
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Friends List

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Friends")
                .font(DS.headlineFont)
                .foregroundColor(DS.textPrimary)

            if filteredFriends.isEmpty {
                emptyFriendsState
            } else {
                ForEach(Array(filteredFriends.enumerated()), id: \.element.id) { index, friend in
                    friendRow(friend)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                        .animation(DS.transitionAnim.delay(Double(index) * 0.05), value: animateIn)
                }
            }
        }
    }

    private var emptyFriendsState: some View {
        VStack(spacing: 16) {
            if searchText.isEmpty {
                MascotWithMessage(
                    message: "Add friends to compete and learn together!",
                    mood: .encouraging,
                    mascotSize: 80
                )
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(DS.textTertiary)

                    Text("No friends found")
                        .font(DS.bodyFont)
                        .foregroundColor(DS.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func friendRow(_ friend: Friend) -> some View {
        CardView {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Text(friend.avatar)
                        .font(.system(size: 40))

                    if friend.isOnline {
                        Circle()
                            .fill(DS.success)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(DS.cardBg, lineWidth: 2)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)

                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(DS.gold)
                            Text("Lvl \(friend.level)")
                                .font(DS.smallFont)
                                .foregroundColor(DS.textSecondary)
                        }

                        if friend.currentStreak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DS.accent)
                                Text("\(friend.currentStreak)")
                                    .font(DS.smallFont)
                                    .foregroundColor(DS.textSecondary)
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(friend.lastActiveFormatted)
                        .font(DS.smallFont)
                        .foregroundColor(friend.isOnline ? DS.success : DS.textTertiary)

                    Text("\(friend.totalXP) XP")
                        .font(DS.smallFont)
                        .foregroundColor(DS.textTertiary)
                }
            }
        }
    }

    // MARK: - Activity Feed

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(DS.primary)
                Text("Activity Feed")
                    .font(DS.headlineFont)
                    .foregroundColor(DS.textPrimary)
            }

            ForEach(activityFeed) { item in
                activityRow(item)
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .animation(DS.transitionAnim.delay(0.3), value: animateIn)
    }

    private func activityRow(_ item: ActivityFeedItem) -> some View {
        HStack(spacing: 12) {
            Text(item.friendAvatar)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(item.friendName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(DS.textPrimary)

                    Text(item.message)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(DS.textSecondary)
                }

                Text(item.timeAgo)
                    .font(DS.smallFont)
                    .foregroundColor(DS.textTertiary)
            }

            Spacer()

            Image(systemName: item.icon)
                .font(.system(size: 16))
                .foregroundColor(item.iconColor)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .shadow(color: DS.cardShadow, radius: 6, y: 3)
        )
    }

    // MARK: - Add Friend Sheet

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                MascotView(size: 80, mood: .happy)
                    .padding(.top, 16)

                Text("Add a Friend")
                    .font(DS.titleFont)
                    .foregroundColor(DS.textPrimary)

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Username")
                            .font(DS.captionFont)
                            .foregroundColor(DS.textSecondary)

                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(DS.textTertiary)

                            TextField("username", text: $addFriendUsername)
                                .font(DS.bodyFont)
                                .foregroundColor(DS.textPrimary)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: DS.cornerRadius)
                                .stroke(DS.border, lineWidth: 1.5)
                        )
                    }

                    PrimaryButton("Send Request", icon: "person.badge.plus") {
                        Haptics.success()
                        SoundCue.success()
                        addFriendUsername = ""
                        showAddFriend = false
                    }

                    dividerRow

                    SecondaryButton("Share Invite Link", icon: "link") {
                        Haptics.light()
                        showShareSheet = true
                    }
                }
                .padding(.horizontal, DS.padding)

                Spacer()
            }
            .background(DS.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAddFriend = false
                    }
                    .font(DS.captionFont)
                    .foregroundColor(DS.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var dividerRow: some View {
        HStack {
            Rectangle()
                .fill(DS.divider)
                .frame(height: 1)
            Text("or")
                .font(DS.smallFont)
                .foregroundColor(DS.textTertiary)
            Rectangle()
                .fill(DS.divider)
                .frame(height: 1)
        }
    }

    // MARK: - Actions

    private func acceptRequest(_ request: FriendRequest) {
        friendRequests.removeAll { $0.id == request.id }
        let newFriend = Friend(
            id: request.id,
            name: request.name,
            avatar: request.avatar,
            level: request.level,
            currentStreak: Int.random(in: 0...15),
            lastActive: Date(),
            totalXP: request.level * Int.random(in: 80...120)
        )
        friends.append(newFriend)
    }

    private func declineRequest(_ request: FriendRequest) {
        friendRequests.removeAll { $0.id == request.id }
    }

    // MARK: - Simulated Data

    private func loadSimulatedData() {
        friends = [
            Friend(id: "f1", name: "Alex Chen", avatar: "🧑‍🔧", level: 12, currentStreak: 14, lastActive: Date().addingTimeInterval(-120), totalXP: 2450),
            Friend(id: "f2", name: "Jordan Blake", avatar: "👩‍🔬", level: 8, currentStreak: 7, lastActive: Date().addingTimeInterval(-3600), totalXP: 1280),
            Friend(id: "f3", name: "Casey Park", avatar: "🧑‍💻", level: 15, currentStreak: 31, lastActive: Date().addingTimeInterval(-300), totalXP: 3920),
            Friend(id: "f4", name: "Morgan Lee", avatar: "👨‍🏫", level: 6, currentStreak: 0, lastActive: Date().addingTimeInterval(-86400), totalXP: 680),
            Friend(id: "f5", name: "Taylor Swift", avatar: "👩‍🎓", level: 10, currentStreak: 5, lastActive: Date().addingTimeInterval(-7200), totalXP: 1850),
            Friend(id: "f6", name: "Riley Davis", avatar: "🧑‍🔬", level: 19, currentStreak: 45, lastActive: Date().addingTimeInterval(-60), totalXP: 5230),
            Friend(id: "f7", name: "Quinn Torres", avatar: "👨‍💼", level: 3, currentStreak: 2, lastActive: Date().addingTimeInterval(-172800), totalXP: 320),
        ]

        friendRequests = [
            FriendRequest(id: "fr1", name: "Avery Kim", avatar: "👩‍🔧", level: 7, sentAt: Date().addingTimeInterval(-3600)),
            FriendRequest(id: "fr2", name: "Parker Johnson", avatar: "🧑‍🎓", level: 11, sentAt: Date().addingTimeInterval(-7200)),
        ]

        activityFeed = [
            ActivityFeedItem(id: "a1", friendName: "Alex", friendAvatar: "🧑‍🔧", message: "completed Unit 3!", icon: "checkmark.circle.fill", iconColor: DS.success, timestamp: Date().addingTimeInterval(-1800)),
            ActivityFeedItem(id: "a2", friendName: "Jordan", friendAvatar: "👩‍🔬", message: "hit a 10-day streak!", icon: "flame.fill", iconColor: DS.accent, timestamp: Date().addingTimeInterval(-5400)),
            ActivityFeedItem(id: "a3", friendName: "Casey", friendAvatar: "🧑‍💻", message: "earned the Perfectionist badge!", icon: "star.fill", iconColor: DS.gold, timestamp: Date().addingTimeInterval(-10800)),
            ActivityFeedItem(id: "a4", friendName: "Riley", friendAvatar: "🧑‍🔬", message: "reached Diamond League!", icon: "diamond.fill", iconColor: DS.electricBlue, timestamp: Date().addingTimeInterval(-21600)),
            ActivityFeedItem(id: "a5", friendName: "Taylor", friendAvatar: "👩‍🎓", message: "scored 100% on Ohm's Law!", icon: "bolt.fill", iconColor: DS.primary, timestamp: Date().addingTimeInterval(-43200)),
        ]
    }
}

// MARK: - Preview

#Preview {
    FriendsListView()
}
