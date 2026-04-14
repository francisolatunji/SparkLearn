import SwiftUI

struct PathItem: Identifiable {
    let id: UUID
    let lesson: Lesson
    let unit: CourseUnit
    let state: DuoLessonNode.NodeState
    let crownLevel: Int
    let isFirst: Bool // first lesson in a new unit
}

struct LessonPathView: View {
    let items: [PathItem]
    let currentLessonID: UUID?
    let onSelectLesson: (Lesson, CourseUnit) -> Void

    private let nodeSpacing: CGFloat = 110
    private let amplitude: CGFloat = 90

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    // Section banner when unit changes
                    if item.isFirst {
                        let unitLessons = items.filter { $0.unit.id == item.unit.id }
                        let completedCount = unitLessons.filter { $0.state == .completed }.count

                        DuoSectionBanner(
                            title: item.unit.title,
                            subtitle: item.unit.subtitle,
                            icon: item.unit.icon,
                            color: item.unit.color,
                            lessonCount: unitLessons.count,
                            completedCount: completedCount
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, index == 0 ? 0 : 16)
                        .padding(.bottom, 20)
                    }

                    // Connector line to next node
                    ZStack {
                        if index < items.count - 1 {
                            PathConnectorLine(
                                fromOffset: xOffset(for: index),
                                toOffset: xOffset(for: index + 1),
                                height: nodeSpacing,
                                isCompleted: item.state == .completed,
                                color: item.unit.color
                            )
                        }

                        DuoLessonNode(
                            nodeState: item.state,
                            color: item.unit.color,
                            icon: item.lesson.icon,
                            lessonTitle: item.lesson.title,
                            crownLevel: item.crownLevel,
                            isCurrent: item.id == currentLessonID,
                            action: { onSelectLesson(item.lesson, item.unit) }
                        )
                        .offset(x: xOffset(for: index))
                        .id(item.id)
                    }
                    .frame(height: item.id == currentLessonID ? nodeSpacing + 40 : nodeSpacing)
                }
            }
            .padding(.vertical, 20)
            .onAppear {
                if let currentID = currentLessonID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(currentID, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func xOffset(for index: Int) -> CGFloat {
        let angle = (Double(index) / 2.0) * .pi
        return sin(angle) * amplitude
    }
}

// MARK: - Path Connector Line
struct PathConnectorLine: View {
    let fromOffset: CGFloat
    let toOffset: CGFloat
    let height: CGFloat
    let isCompleted: Bool
    let color: Color

    var body: some View {
        Canvas { context, size in
            let midX = size.width / 2
            let startX = midX + fromOffset
            let endX = midX + toOffset
            let startY: CGFloat = 0
            let endY = height

            var path = Path()
            path.move(to: CGPoint(x: startX, y: startY))
            path.addQuadCurve(
                to: CGPoint(x: endX, y: endY),
                control: CGPoint(x: (startX + endX) / 2, y: height / 2)
            )

            if isCompleted {
                context.stroke(
                    path,
                    with: .color(color.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
            } else {
                context.stroke(
                    path,
                    with: .color(DS.duoBorder),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 8])
                )
            }
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
