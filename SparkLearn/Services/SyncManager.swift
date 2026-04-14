import Foundation
import Combine

// MARK: - Sync State
enum SyncState: Equatable {
    case idle
    case syncing
    case synced
    case offline
    case error(String)

    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.synced, .synced), (.offline, .offline):
            return true
        case let (.error(a), .error(b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Sync Mutation
struct SyncMutation: Codable, Identifiable {
    let id: String
    let collection: String
    let documentId: String
    let data: [String: String]
    let timestamp: Date
    let type: MutationType

    enum MutationType: String, Codable {
        case create, update, delete
    }

    init(collection: String, documentId: String, data: [String: String], type: MutationType) {
        self.id = UUID().uuidString
        self.collection = collection
        self.documentId = documentId
        self.data = data
        self.timestamp = Date()
        self.type = type
    }
}

// MARK: - Sync Manager
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published var syncState: SyncState = .idle
    @Published var lastSyncDate: Date?
    @Published var pendingMutations: Int = 0

    private var mutationQueue: [SyncMutation] = []
    private let mutationQueueKey = "sync_mutation_queue"
    private let lastSyncKey = "last_sync_date"
    private var syncTimer: Timer?

    private init() {
        loadMutationQueue()
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        pendingMutations = mutationQueue.count
    }

    // MARK: - Queue Mutations

    func queueMutation(_ mutation: SyncMutation) {
        mutationQueue.append(mutation)
        pendingMutations = mutationQueue.count
        saveMutationQueue()
    }

    func queueProgressSync(userId: String, progress: ProgressSnapshot) {
        let data: [String: String] = [
            "totalXP": "\(progress.totalXP)",
            "currentStreak": "\(progress.currentStreak)",
            "hearts": "\(progress.hearts)",
            "level": "\(progress.level)",
            "completedLessons": progress.completedLessons.joined(separator: ","),
            "lastSyncedAt": ISO8601DateFormatter().string(from: progress.lastSyncedAt)
        ]

        let mutation = SyncMutation(
            collection: FirestoreCollections.progress,
            documentId: userId,
            data: data,
            type: .update
        )

        queueMutation(mutation)
    }

    func queueUserSync(userId: String, userData: [String: String]) {
        let mutation = SyncMutation(
            collection: FirestoreCollections.users,
            documentId: userId,
            data: userData,
            type: .update
        )
        queueMutation(mutation)
    }

    func queueAchievementSync(userId: String, achievementId: String) {
        let mutation = SyncMutation(
            collection: FirestoreCollections.achievements,
            documentId: "\(userId)_\(achievementId)",
            data: [
                "userId": userId,
                "achievementId": achievementId,
                "unlockedAt": ISO8601DateFormatter().string(from: Date())
            ],
            type: .create
        )
        queueMutation(mutation)
    }

    func queueLeagueScoreUpdate(userId: String, weeklyXP: Int, leagueTier: String) {
        let mutation = SyncMutation(
            collection: FirestoreCollections.leaderboards,
            documentId: userId,
            data: [
                "weeklyXP": "\(weeklyXP)",
                "leagueTier": leagueTier,
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ],
            type: .update
        )
        queueMutation(mutation)
    }

    // MARK: - Sync Execution

    func sync() async {
        guard !mutationQueue.isEmpty else {
            syncState = .synced
            return
        }

        syncState = .syncing

        // Process mutations in order
        var failedMutations: [SyncMutation] = []

        for mutation in mutationQueue {
            let success = await processMutation(mutation)
            if !success {
                failedMutations.append(mutation)
            }
        }

        mutationQueue = failedMutations
        pendingMutations = mutationQueue.count
        saveMutationQueue()

        if failedMutations.isEmpty {
            syncState = .synced
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        } else {
            syncState = .error("\(failedMutations.count) mutations failed")
        }
    }

    private func processMutation(_ mutation: SyncMutation) async -> Bool {
        // TODO: Implement actual Firestore writes when Firebase is added
        // switch mutation.type {
        // case .create:
        //     try? await db.collection(mutation.collection).document(mutation.documentId).setData(mutation.data)
        // case .update:
        //     try? await db.collection(mutation.collection).document(mutation.documentId).setData(mutation.data, merge: true)
        // case .delete:
        //     try? await db.collection(mutation.collection).document(mutation.documentId).delete()
        // }

        // For now, simulate successful sync
        return true
    }

    // MARK: - Auto Sync

    func startAutoSync(interval: TimeInterval = 300) {
        stopAutoSync()
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.sync()
            }
        }
    }

    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }

    // MARK: - Conflict Resolution (Last Write Wins)

    func resolveConflict(local: ProgressSnapshot, remote: ProgressSnapshot) -> ProgressSnapshot {
        // Last-write-wins based on timestamp
        if local.lastSyncedAt > remote.lastSyncedAt {
            return local
        }

        // Merge: take the higher values for cumulative fields
        return ProgressSnapshot(
            totalXP: max(local.totalXP, remote.totalXP),
            currentStreak: remote.currentStreak, // server is authoritative for streaks
            hearts: remote.hearts,
            completedLessons: Array(Set(local.completedLessons + remote.completedLessons)),
            lessonScores: local.lessonScores.merging(remote.lessonScores) { max($0, $1) },
            level: max(local.level, remote.level),
            lastSyncedAt: Date()
        )
    }

    // MARK: - Persistence

    private func saveMutationQueue() {
        if let data = try? JSONEncoder().encode(mutationQueue) {
            UserDefaults.standard.set(data, forKey: mutationQueueKey)
        }
    }

    private func loadMutationQueue() {
        guard let data = UserDefaults.standard.data(forKey: mutationQueueKey),
              let saved = try? JSONDecoder().decode([SyncMutation].self, from: data) else { return }
        mutationQueue = saved
    }
}
