import Foundation

/// Backend service protocol — swap the implementation for Firebase, Supabase, or your own API.
/// Currently uses local storage; ready to be replaced with a real backend.
protocol BackendServiceProtocol {
    func syncUser(_ user: AppUser)
    func syncProgress(_ progress: ProgressSnapshot, userId: String)
    func fetchProgress(userId: String) -> ProgressSnapshot?
    func deleteUserData(userId: String)
}

/// Snapshot of user progress for syncing
struct ProgressSnapshot: Codable {
    var totalXP: Int
    var currentStreak: Int
    var hearts: Int
    var completedLessons: [String]
    var lessonScores: [String: Int]
    var level: Int
    var lastSyncedAt: Date
}

// MARK: - Local Backend (swap for Firebase/Supabase later)
final class BackendService: BackendServiceProtocol {
    static let shared: BackendServiceProtocol = BackendService()
    private init() {}

    private let defaults = UserDefaults.standard

    func syncUser(_ user: AppUser) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: "backend_user_\(user.id)")
        }
        // TODO: Replace with real API call
        // POST /api/users { user }
    }

    func syncProgress(_ progress: ProgressSnapshot, userId: String) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: "backend_progress_\(userId)")
        }
        // TODO: Replace with real API call
        // PUT /api/users/{userId}/progress { progress }
    }

    func fetchProgress(userId: String) -> ProgressSnapshot? {
        guard let data = defaults.data(forKey: "backend_progress_\(userId)") else { return nil }
        return try? JSONDecoder().decode(ProgressSnapshot.self, from: data)
        // TODO: Replace with real API call
        // GET /api/users/{userId}/progress
    }

    func deleteUserData(userId: String) {
        defaults.removeObject(forKey: "backend_user_\(userId)")
        defaults.removeObject(forKey: "backend_progress_\(userId)")
        // TODO: Replace with real API call
        // DELETE /api/users/{userId}
    }
}

// MARK: - Firebase Backend (uncomment when Firebase SDK is added via SPM)
/*
import FirebaseAuth
import FirebaseFirestore

final class FirebaseBackendService: BackendServiceProtocol {
    static let shared: BackendServiceProtocol = FirebaseBackendService()
    private let db = Firestore.firestore()

    func syncUser(_ user: AppUser) {
        try? db.collection("users").document(user.id).setData(from: user, merge: true)
    }

    func syncProgress(_ progress: ProgressSnapshot, userId: String) {
        try? db.collection("users").document(userId)
            .collection("progress").document("current")
            .setData(from: progress, merge: true)
    }

    func fetchProgress(userId: String) -> ProgressSnapshot? {
        // Use async version in real app
        return nil
    }

    func deleteUserData(userId: String) {
        db.collection("users").document(userId).delete()
    }
}
*/

// MARK: - Extended Backend Protocol
extension BackendServiceProtocol {
    // Default no-op implementations for optional methods
    func syncAchievements(_ achievements: [String], userId: String) {}
    func syncLeagueScore(userId: String, weeklyXP: Int, tier: String) {}
    func fetchLeaderboard(tier: String) -> [LeagueParticipant] { [] }
    func syncChallenge(_ data: [String: String]) {}
}

// MARK: - Sync Integration
extension BackendService {
    func triggerFullSync(userId: String, progress: ProgressSnapshot) {
        syncProgress(progress, userId: userId)
        SyncManager.shared.queueProgressSync(userId: userId, progress: progress)
        AnalyticsService.shared.track(.sessionEnded, properties: ["user_id": userId])
    }
}
