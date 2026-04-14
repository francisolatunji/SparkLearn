import SwiftUI

struct DuoLessonNode: View {
    enum NodeState {
        case locked, active, completed
    }

    let nodeState: NodeState
    let color: Color
    let icon: String
    let lessonTitle: String
    let crownLevel: Int
    let isCurrent: Bool
    let action: () -> Void

    @State private var bouncing = false

    private let nodeSize: CGFloat = 68

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                guard nodeState != .locked else { return }
                Haptics.light()
                action()
            }) {
                ZStack {
                    // 3D shadow circle
                    Circle()
                        .fill(shadowFill)
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: 4)

                    // Main circle
                    Circle()
                        .fill(mainFill)
                        .frame(width: nodeSize, height: nodeSize)

                    // Border for locked
                    if nodeState == .locked {
                        Circle()
                            .stroke(DS.duoBorderDark, lineWidth: 2)
                            .frame(width: nodeSize, height: nodeSize)
                    }

                    // Icon
                    Image(systemName: nodeIcon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(iconColor)

                    // Crown badge for completed
                    if nodeState == .completed && crownLevel > 0 {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(DS.duoYellow)
                                        .frame(width: 24, height: 24)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 4, y: -4)
                            }
                            Spacer()
                        }
                        .frame(width: nodeSize, height: nodeSize)
                    }
                }
            }
            .disabled(nodeState == .locked)
            .scaleEffect(bouncing ? 1.08 : 1.0)

            // "START" label for current lesson
            if isCurrent && nodeState == .active {
                DuoButton(title: "Start", variant: .green, small: true, action: action)
                    .frame(width: 100)
            }
        }
        .onAppear {
            if isCurrent && nodeState == .active {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    bouncing = true
                }
            }
        }
    }

    private var mainFill: Color {
        switch nodeState {
        case .locked: return DS.duoBorder
        case .active: return color
        case .completed: return DS.duoYellow
        }
    }

    private var shadowFill: Color {
        switch nodeState {
        case .locked: return DS.duoBorderDark
        case .active: return color.opacity(0.7)
        case .completed: return Color(hex: "E5A800")
        }
    }

    private var iconColor: Color {
        switch nodeState {
        case .locked: return DS.duoTextSecondary
        default: return .white
        }
    }

    private var nodeIcon: String {
        switch nodeState {
        case .completed: return "checkmark"
        case .locked: return "lock.fill"
        case .active: return icon
        }
    }
}
