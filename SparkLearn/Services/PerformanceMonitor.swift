import Foundation
import SceneKit

// MARK: - Performance Monitor
/// Tracks 3D rendering performance and adapts quality settings
@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    @Published var currentFPS: Double = 60
    @Published var averageFPS: Double = 60
    @Published var drawCalls: Int = 0
    @Published var triangleCount: Int = 0
    @Published var textureMemoryMB: Double = 0
    @Published var qualityLevel: QualityLevel = .high
    @Published var isLowPerformance: Bool = false

    private var fpsHistory: [Double] = []
    private let historySize = 30
    private var monitorTimer: Timer?

    enum QualityLevel: String {
        case low, medium, high

        var antialiasingMode: SCNAntialiasingMode {
            switch self {
            case .low: return .none
            case .medium: return .multisampling2X
            case .high: return .multisampling4X
            }
        }

        var particleCount: Int {
            switch self {
            case .low: return 50
            case .medium: return 200
            case .high: return 500
            }
        }

        var shadowsEnabled: Bool {
            switch self {
            case .low: return false
            case .medium, .high: return true
            }
        }

        var maxTextureSize: Int {
            switch self {
            case .low: return 512
            case .medium: return 1024
            case .high: return 2048
            }
        }
    }

    private init() {}

    // MARK: - Monitoring

    func startMonitoring(scnView: SCNView) {
        scnView.showsStatistics = false // Don't show debug overlay

        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStats(from: scnView)
            }
        }
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func updateStats(from scnView: SCNView) {
        // Estimate FPS from render loop timing
        let fps = 1.0 / max(0.001, scnView.sceneTime.truncatingRemainder(dividingBy: 1.0))
        let clampedFPS = min(120, max(1, fps))

        fpsHistory.append(clampedFPS)
        if fpsHistory.count > historySize {
            fpsHistory.removeFirst()
        }

        currentFPS = clampedFPS
        averageFPS = fpsHistory.reduce(0, +) / Double(fpsHistory.count)

        // Get render info
        let info = scnView.renderingAPI == .metal ? "Metal" : "OpenGL"
        _ = info

        // Auto-adjust quality
        adaptQuality()
    }

    // MARK: - Adaptive Quality

    func adaptQuality() {
        if averageFPS < 25 && qualityLevel != .low {
            qualityLevel = .low
            isLowPerformance = true
        } else if averageFPS < 40 && qualityLevel == .high {
            qualityLevel = .medium
            isLowPerformance = false
        } else if averageFPS > 55 && qualityLevel != .high {
            qualityLevel = .high
            isLowPerformance = false
        }
    }

    func applyQualitySettings(to scnView: SCNView) {
        scnView.antialiasingMode = qualityLevel.antialiasingMode

        // Adjust rendering
        switch qualityLevel {
        case .low:
            scnView.preferredFramesPerSecond = 30
            scnView.isJitteringEnabled = false
        case .medium:
            scnView.preferredFramesPerSecond = 60
            scnView.isJitteringEnabled = false
        case .high:
            scnView.preferredFramesPerSecond = 60
            scnView.isJitteringEnabled = true
        }
    }

    // MARK: - Device Capability Check

    static var deviceTier: DeviceTier {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryGB = Double(totalMemory) / (1024 * 1024 * 1024)

        if memoryGB >= 6 { return .high }
        if memoryGB >= 4 { return .medium }
        return .low
    }

    enum DeviceTier {
        case low, medium, high

        var recommendedQuality: QualityLevel {
            switch self {
            case .low: return .low
            case .medium: return .medium
            case .high: return .high
            }
        }

        var maxParticles: Int {
            switch self {
            case .low: return 100
            case .medium: return 300
            case .high: return 1000
            }
        }

        var textureMemoryBudgetMB: Int {
            switch self {
            case .low: return 128
            case .medium: return 256
            case .high: return 512
            }
        }
    }

    // MARK: - Scene Optimization Helpers

    /// Configure a SCNView for optimal performance
    static func configureForPerformance(_ scnView: SCNView) {
        let tier = deviceTier

        scnView.antialiasingMode = tier.recommendedQuality.antialiasingMode
        scnView.preferredFramesPerSecond = tier == .low ? 30 : 60
        scnView.isJitteringEnabled = tier == .high

        // Rendering optimization
        scnView.rendersContinuously = false // Only render when needed
    }

    /// Enable continuous rendering (for animations)
    static func enableContinuousRendering(_ scnView: SCNView) {
        scnView.rendersContinuously = true
    }

    /// Disable continuous rendering (saves battery)
    static func disableContinuousRendering(_ scnView: SCNView) {
        scnView.rendersContinuously = false
        scnView.setNeedsDisplay() // Render one last frame
    }
}
