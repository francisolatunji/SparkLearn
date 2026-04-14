import SwiftUI

// MARK: - Code Completion Exercise
/// Fill in Arduino code snippets with syntax highlighting
struct CodeCompletionView: View {
    let prompt: String
    let codeTemplate: String // uses ___BLANK___ as placeholder
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let onComplete: (Bool) -> Void

    @State private var selectedOption: String?
    @State private var answered = false
    @State private var showExplanation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 28))
                        .foregroundColor(DS.deepPurple)

                    Text(prompt)
                        .font(DS.headlineFont)
                        .foregroundColor(DS.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.padding)
                }

                // Code block
                codeBlock

                // Options
                VStack(spacing: 10) {
                    Text("Fill in the blank:")
                        .font(DS.captionFont)
                        .foregroundColor(DS.textSecondary)

                    ForEach(options, id: \.self) { option in
                        CodeOptionButton(
                            code: option,
                            isSelected: selectedOption == option,
                            isCorrect: answered && option == correctAnswer,
                            isWrong: answered && selectedOption == option && option != correctAnswer
                        ) {
                            guard !answered else { return }
                            selectedOption = option
                            answered = true

                            let correct = option == correctAnswer
                            if correct {
                                Haptics.success()
                                SoundCue.success()
                            } else {
                                Haptics.error()
                                SoundCue.error()
                            }

                            withAnimation(.easeInOut(duration: 0.3).delay(0.5)) {
                                showExplanation = true
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                onComplete(correct)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.padding)

                // Explanation
                if showExplanation {
                    CardView(accent: selectedOption == correctAnswer ? DS.success : DS.error) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: selectedOption == correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(selectedOption == correctAnswer ? DS.success : DS.error)
                                Text(selectedOption == correctAnswer ? "Correct!" : "Not quite")
                                    .font(DS.headlineFont)
                                    .foregroundColor(DS.textPrimary)
                            }

                            Text(explanation)
                                .font(DS.bodyFont)
                                .foregroundColor(DS.textSecondary)
                        }
                    }
                    .padding(.horizontal, DS.padding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Code Block
    private var codeBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File tab
            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textTertiary)
                Text("sketch.ino")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(DS.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "1E293B"))

            // Code content
            VStack(alignment: .leading, spacing: 0) {
                let lines = displayCode.components(separatedBy: "\n")
                ForEach(lines.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "475569"))
                            .frame(width: 20, alignment: .trailing)

                        syntaxHighlightedLine(lines[i])
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(12)
            .background(Color(hex: "0F172A"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "334155"), lineWidth: 1)
        )
        .padding(.horizontal, DS.padding)
    }

    private var displayCode: String {
        if let selected = selectedOption {
            return codeTemplate.replacingOccurrences(of: "___BLANK___", with: selected)
        }
        return codeTemplate.replacingOccurrences(of: "___BLANK___", with: "________")
    }

    private func syntaxHighlightedLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let indent = String(repeating: " ", count: line.count - trimmed.count)

        return HStack(spacing: 0) {
            Text(indent)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.clear)

            if trimmed.hasPrefix("//") {
                Text(trimmed)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "6B7280"))
            } else if trimmed.contains("________") {
                highlightBlank(trimmed)
            } else {
                colorizedCode(trimmed)
            }

            Spacer()
        }
    }

    private func highlightBlank(_ text: String) -> some View {
        let parts = text.components(separatedBy: "________")
        return HStack(spacing: 0) {
            ForEach(parts.indices, id: \.self) { i in
                colorizedCode(parts[i])
                if i < parts.count - 1 {
                    Text("________")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(DS.accent)
                        .background(DS.accent.opacity(0.15))
                }
            }
        }
    }

    private func colorizedCode(_ text: String) -> Text {
        let keywords = ["void", "int", "float", "bool", "for", "if", "else", "while", "return", "const", "true", "false"]
        let functions = ["setup", "loop", "pinMode", "digitalWrite", "digitalRead", "analogWrite", "analogRead", "delay", "Serial", "begin", "println", "HIGH", "LOW", "OUTPUT", "INPUT"]

        var result = Text("")
        let words = text.components(separatedBy: .whitespaces)

        for word in words {
            let cleaned = word.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if keywords.contains(cleaned) {
                result = result + Text(word + " ").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: "C084FC"))
            } else if functions.contains(cleaned) {
                result = result + Text(word + " ").font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: "60A5FA"))
            } else if word.contains("\"") {
                result = result + Text(word + " ").font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: "34D399"))
            } else if Int(cleaned) != nil {
                result = result + Text(word + " ").font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: "F59E0B"))
            } else {
                result = result + Text(word + " ").font(.system(size: 13, design: .monospaced)).foregroundColor(Color(hex: "E2E8F0"))
            }
        }

        return result
    }
}

// MARK: - Code Option Button
struct CodeOptionButton: View {
    let code: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(code)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)

                Spacer()

                if isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(DS.success)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill").foregroundColor(DS.error)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.error }
        return DS.textPrimary
    }

    private var bgColor: Color {
        if isCorrect { return DS.success.opacity(0.08) }
        if isWrong { return DS.error.opacity(0.08) }
        return DS.cardBg
    }

    private var borderColor: Color {
        if isCorrect { return DS.success }
        if isWrong { return DS.error }
        if isSelected { return DS.deepPurple }
        return DS.border
    }
}
