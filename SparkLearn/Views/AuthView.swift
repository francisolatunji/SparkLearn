import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            DS.heroBackground.ignoresSafeArea()

            // Floating electrical icons in background
            FloatingBackgroundIcons()
                .opacity(0.06)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    hero
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -10)

                    benefitStrip
                        .padding(.horizontal, DS.padding)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)

                    SignInWithAppleButton(
                        isSignUp ? .signUp : .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            auth.handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .cornerRadius(DS.buttonCorner)
                    .padding(.horizontal, DS.padding)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                    HStack {
                        Rectangle().fill(DS.border).frame(height: 1)
                        Text("or")
                            .font(DS.captionFont)
                            .foregroundColor(DS.textTertiary)
                        Rectangle().fill(DS.border).frame(height: 1)
                    }
                    .padding(.horizontal, DS.padding)
                    .opacity(appeared ? 1 : 0)

                    DSGlassCard {
                        VStack(spacing: 14) {
                            if isSignUp {
                                AuthTextField(
                                    icon: "person",
                                    placeholder: "Display name",
                                    text: $name
                                )
                            }

                            AuthTextField(
                                icon: "envelope",
                                placeholder: "Email",
                                text: $email,
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )

                            AuthTextField(
                                icon: "lock",
                                placeholder: "Password (8+ characters)",
                                text: $password,
                                isSecure: true
                            )

                            if let error = auth.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle")
                                        .font(.system(size: 13))
                                    Text(error)
                                        .font(DS.captionFont)
                                }
                                .foregroundColor(DS.error)
                                .padding(.horizontal, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.horizontal, DS.padding)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)

                    PrimaryButton(
                        isSignUp ? "Create Account" : "Sign In",
                        icon: isSignUp ? "person.badge.plus" : "arrow.right"
                    ) {
                        if isSignUp {
                            auth.signUpWithEmail(email: email, password: password, name: name)
                        } else {
                            auth.signInWithEmail(email: email, password: password)
                        }
                    }
                    .padding(.horizontal, DS.padding)
                    .opacity(auth.isLoading ? 0.6 : 1)
                    .disabled(auth.isLoading)
                    .overlay {
                        if auth.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .opacity(appeared ? 1 : 0)

                    // Toggle sign in / sign up
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSignUp.toggle()
                            auth.errorMessage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(DS.textSecondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .foregroundColor(DS.primary)
                                .fontWeight(.semibold)
                        }
                        .font(DS.captionFont)
                    }
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 40)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }

    private var hero: some View {
        VStack(spacing: 16) {
            ZStack {
                // Soft glow behind mascot
                Circle()
                    .fill(DS.primary.opacity(0.08))
                    .frame(width: 130, height: 130)
                    .blur(radius: 20)

                MascotView(size: 90, mood: .happy)
            }

            VStack(spacing: 8) {
                Text("SparkLearn")
                    .font(DS.heroTitleFont)
                    .foregroundStyle(DS.textPrimary)

                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(DS.bodyFont)
                    .foregroundStyle(DS.textSecondary)

                Text(isSignUp ? "Track progress, build practical circuits, and shape a learning path that fits you." : "Pick up where you left off and keep your streak moving.")
                    .font(DS.captionFont)
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }

    private var benefitStrip: some View {
        HStack(spacing: 10) {
            authBenefit(icon: "square.stack.3d.up.fill", title: "Guided curriculum")
            authBenefit(icon: "target", title: "Focused practice")
            authBenefit(icon: "person.crop.circle.badge.checkmark", title: "Personal profile")
        }
    }

    private func authBenefit(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.primary)
                .floating(amplitude: 2, duration: 2.0 + Double(title.count % 3) * 0.3)
            Text(title)
                .font(DS.smallFont)
                .foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.7))
        )
    }
}

// MARK: - Floating Background Icons
struct FloatingBackgroundIcons: View {
    private let icons = ["bolt.fill", "cpu", "memorychip", "poweroutlet.type.b", "wave.3.right", "antenna.radiowaves.left.and.right", "bolt.circle", "lightbulb.fill"]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<8, id: \.self) { i in
                FloatingIcon(
                    icon: icons[i],
                    size: geo.size,
                    index: i
                )
            }
        }
    }
}

private struct FloatingIcon: View {
    let icon: String
    let size: CGSize
    let index: Int
    @State private var drifting = false

    private var startX: CGFloat { CGFloat((index * 47 + 23) % max(Int(size.width), 1)) }
    private var startY: CGFloat { CGFloat((index * 73 + 41) % max(Int(size.height), 1)) }
    private var driftAmount: CGFloat { CGFloat([30, -25, 20, -35, 28, -22, 32, -27][index]) }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: CGFloat([24, 20, 28, 22, 26, 18, 30, 21][index])))
            .foregroundStyle(DS.textPrimary)
            .position(
                x: startX + (drifting ? driftAmount : 0),
                y: startY + (drifting ? -driftAmount * 0.7 : 0)
            )
            .rotationEffect(.degrees(drifting ? Double(index * 5) : 0))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double([6, 7, 8, 5, 9, 6.5, 7.5, 8.5][index]))
                    .repeatForever(autoreverses: true)
                ) {
                    drifting = true
                }
            }
    }
}

// MARK: - Custom Text Field
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(focused ? DS.primary : DS.textTertiary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($focused)
                    .textInputAutocapitalization(autocapitalization)
            } else {
                TextField(placeholder, text: $text)
                    .focused($focused)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
            }
        }
        .font(.system(size: 16, design: .rounded))
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadius)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cornerRadius)
                        .stroke(focused ? DS.primary : DS.border, lineWidth: focused ? 2 : 1)
                )
        )
    }
}
