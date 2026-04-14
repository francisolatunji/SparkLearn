import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - User Model
struct AppUser: Codable, Equatable {
    let id: String
    var email: String
    var displayName: String
    var authProvider: AuthProvider
    var learnerStage: LearnerStage
    var learningGoal: LearningGoal
    var focusArea: String
    var profileCompleted: Bool
    var createdAt: Date
    var lastLoginAt: Date

    enum AuthProvider: String, Codable {
        case apple
        case email
    }

    init(
        id: String,
        email: String,
        displayName: String,
        authProvider: AuthProvider,
        learnerStage: LearnerStage = .beginner,
        learningGoal: LearningGoal = .understandBasics,
        focusArea: String = "Circuits",
        profileCompleted: Bool = false,
        createdAt: Date,
        lastLoginAt: Date
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.authProvider = authProvider
        self.learnerStage = learnerStage
        self.learningGoal = learningGoal
        self.focusArea = focusArea
        self.profileCompleted = profileCompleted
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case authProvider
        case learnerStage
        case learningGoal
        case focusArea
        case profileCompleted
        case createdAt
        case lastLoginAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        authProvider = try container.decode(AuthProvider.self, forKey: .authProvider)
        learnerStage = try container.decodeIfPresent(LearnerStage.self, forKey: .learnerStage) ?? .beginner
        learningGoal = try container.decodeIfPresent(LearningGoal.self, forKey: .learningGoal) ?? .understandBasics
        focusArea = try container.decodeIfPresent(String.self, forKey: .focusArea) ?? "Circuits"
        profileCompleted = try container.decodeIfPresent(Bool.self, forKey: .profileCompleted) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLoginAt = try container.decode(Date.self, forKey: .lastLoginAt)
    }
}

// MARK: - Auth Manager
@MainActor
class AuthManager: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showOnboarding = false
    @Published var pendingProfileName = ""

    private let keychain = KeychainHelper.shared
    private let userKey = "current_user"
    private let tokenKey = "auth_token"
    private let hasSeenOnboardingKey = "has_seen_onboarding"

    init() {
        loadSavedSession()
    }

    // MARK: - Session Management
    private func loadSavedSession() {
        if let user = keychain.read(AppUser.self, for: userKey) {
            currentUser = user
            isAuthenticated = true
        }
        showOnboarding = !UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
        showOnboarding = false
    }

    var needsProfileSetup: Bool {
        isAuthenticated && (currentUser?.profileCompleted == false)
    }

    // MARK: - Sign in with Apple
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential"
                isLoading = false
                return
            }

            let userId = credential.user
            let email = credential.email ?? "\(userId.prefix(8))@privaterelay.appleid.com"
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            // Store the identity token securely
            if let tokenData = credential.identityToken {
                keychain.save(tokenData, for: tokenKey)
            }

            let user = AppUser(
                id: userId,
                email: email,
                displayName: name.isEmpty ? "Learner" : name,
                authProvider: .apple,
                learnerStage: .beginner,
                learningGoal: .understandBasics,
                focusArea: "Circuits",
                profileCompleted: !name.isEmpty,
                createdAt: Date(),
                lastLoginAt: Date()
            )

            signIn(user: user)

        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                // User cancelled — not an error
            } else {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // MARK: - Email Auth (local secure implementation)
    func signUpWithEmail(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            isLoading = false
            return
        }

        // Hash the password (never store plaintext)
        let passwordHash = hashPassword(password, salt: email)

        // Check if account already exists
        if let _ = keychain.read(Data.self, for: "pwd_\(email)") {
            errorMessage = "An account with this email already exists."
            isLoading = false
            return
        }

        // Store password hash
        keychain.save(passwordHash, for: "pwd_\(email)")

        let user = AppUser(
            id: UUID().uuidString,
            email: email,
            displayName: name.isEmpty ? "Learner" : name,
            authProvider: .email,
            learnerStage: .beginner,
            learningGoal: .understandBasics,
            focusArea: "Circuits",
            profileCompleted: !name.isEmpty,
            createdAt: Date(),
            lastLoginAt: Date()
        )

        signIn(user: user)
    }

    func signInWithEmail(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }

        let passwordHash = hashPassword(password, salt: email)

        guard let storedHash = keychain.read(Data.self, for: "pwd_\(email)"),
              storedHash == passwordHash else {
            errorMessage = "Incorrect email or password."
            isLoading = false
            return
        }

        // Retrieve or create user
        let user: AppUser
        if let existing = keychain.read(AppUser.self, for: "user_\(email)") {
            user = AppUser(
                id: existing.id,
                email: existing.email,
                displayName: existing.displayName,
                authProvider: .email,
                learnerStage: existing.learnerStage,
                learningGoal: existing.learningGoal,
                focusArea: existing.focusArea,
                profileCompleted: existing.profileCompleted,
                createdAt: existing.createdAt,
                lastLoginAt: Date()
            )
        } else {
            user = AppUser(
                id: UUID().uuidString,
                email: email,
                displayName: "Learner",
                authProvider: .email,
                learnerStage: .beginner,
                learningGoal: .understandBasics,
                focusArea: "Circuits",
                profileCompleted: false,
                createdAt: Date(),
                lastLoginAt: Date()
            )
        }

        signIn(user: user)
    }

    // MARK: - Core Sign In / Out
    private func signIn(user: AppUser) {
        currentUser = user
        isAuthenticated = true
        isLoading = false
        pendingProfileName = user.displayName

        // Persist session
        keychain.save(user, for: userKey)
        if user.authProvider == .email {
            keychain.save(user, for: "user_\(user.email)")
        }

        // Sync with backend
        BackendService.shared.syncUser(user)
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        pendingProfileName = ""
        keychain.delete(for: userKey)
        keychain.delete(for: tokenKey)
    }

    func deleteAccount() {
        if let user = currentUser {
            if user.authProvider == .email {
                keychain.delete(for: "pwd_\(user.email)")
                keychain.delete(for: "user_\(user.email)")
            }
            BackendService.shared.deleteUserData(userId: user.id)
        }
        signOut()
    }

    func updateDisplayName(_ name: String) {
        guard var user = currentUser else { return }
        user.displayName = name
        currentUser = user
        persist(user: user)
    }

    func completeProfile(name: String, learnerStage: LearnerStage, learningGoal: LearningGoal, focusArea: String) {
        guard var user = currentUser else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFocus = focusArea.trimmingCharacters(in: .whitespacesAndNewlines)

        user.displayName = trimmedName.isEmpty ? user.displayName : trimmedName
        user.learnerStage = learnerStage
        user.learningGoal = learningGoal
        user.focusArea = trimmedFocus.isEmpty ? "Circuits" : trimmedFocus
        user.profileCompleted = true
        currentUser = user
        pendingProfileName = user.displayName
        persist(user: user)
    }

    private func persist(user: AppUser) {
        keychain.save(user, for: userKey)
        if user.authProvider == .email {
            keychain.save(user, for: "user_\(user.email)")
        }
        BackendService.shared.syncUser(user)
    }

    // MARK: - Helpers
    private func hashPassword(_ password: String, salt: String) -> Data {
        let input = "\(salt):\(password)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return Data(hash)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: regex) != nil
    }
}
