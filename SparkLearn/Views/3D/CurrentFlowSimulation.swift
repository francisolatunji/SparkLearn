import SwiftUI
import SceneKit

// MARK: - Current Flow Simulation View
/// Animated particle-based visualization of electric current flowing through a circuit.
/// Electron particles travel along wire paths at speeds proportional to current magnitude.
struct CurrentFlowSimulation: View {
    let voltage: Double
    let resistance: Double
    let isActive: Bool

    // Derived
    private var current: Double {
        guard resistance > 0 else { return 0 }
        return voltage / resistance
    }

    private var isShortCircuit: Bool {
        resistance < 1.0 && resistance > 0
    }

    @State private var scene: SCNScene = SCNScene()
    @State private var sceneBuilt = false

    var body: some View {
        ZStack {
            // 3D Scene
            CurrentFlowSceneView(
                scene: scene,
                voltage: voltage,
                resistance: resistance,
                current: current,
                isActive: isActive,
                isShortCircuit: isShortCircuit
            )
            .ignoresSafeArea()

            // Readout overlay
            VStack {
                Spacer()

                DSGlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(DS.electricBlue)
                            Text("Ohm's Law: I = V / R")
                                .font(DS.captionFont)
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            if isShortCircuit {
                                Label("SHORT CIRCUIT", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(DS.error)
                            }
                        }

                        HStack(spacing: 20) {
                            ReadoutValue(
                                label: "Voltage",
                                value: String(format: "%.1fV", voltage),
                                color: DS.success
                            )
                            ReadoutValue(
                                label: "Current",
                                value: formatCurrent(current),
                                color: DS.electricBlue
                            )
                            ReadoutValue(
                                label: "Resistance",
                                value: formatResistance(resistance),
                                color: DS.deepPurple
                            )
                        }

                        // Power dissipation
                        let power = current * current * resistance
                        HStack {
                            Text("Power: \(String(format: "%.2fW", power))")
                                .font(DS.captionFont)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Circle()
                                .fill(isActive ? DS.success : DS.textTertiary)
                                .frame(width: 8, height: 8)
                            Text(isActive ? "Active" : "Inactive")
                                .font(DS.captionFont)
                                .foregroundColor(isActive ? DS.success : DS.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, DS.padding)
            }
        }
        .background(Color.black)
    }

    // MARK: - Formatters

    private func formatCurrent(_ amps: Double) -> String {
        if amps.isInfinite || amps.isNaN { return "--" }
        if amps < 0.001 { return String(format: "%.1f\u{00B5}A", amps * 1_000_000) }
        if amps < 1.0 { return String(format: "%.1fmA", amps * 1_000) }
        return String(format: "%.2fA", amps)
    }

    private func formatResistance(_ ohms: Double) -> String {
        if ohms >= 1_000_000 { return String(format: "%.1fM\u{2126}", ohms / 1_000_000) }
        if ohms >= 1_000 { return String(format: "%.1fk\u{2126}", ohms / 1_000) }
        return String(format: "%.0f\u{2126}", ohms)
    }
}

// MARK: - Readout Value

private struct ReadoutValue: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - SceneKit Representable

private struct CurrentFlowSceneView: UIViewRepresentable {
    let scene: SCNScene
    let voltage: Double
    let resistance: Double
    let current: Double
    let isActive: Bool
    let isShortCircuit: Bool

    class Coordinator {
        var hasBuilt = false
        var particleNodes: [SCNNode] = []
        var sparkNode: SCNNode?
        var wirePathPoints: [[SCNVector3]] = []
        var voltageGradientNodes: [SCNNode] = []
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.03, green: 0.05, blue: 0.10, alpha: 1)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isTemporalAntialiasingEnabled = true

        let builtScene = buildScene(coordinator: context.coordinator)
        scnView.scene = builtScene

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let coord = context.coordinator

        // Update particle speed based on current
        let speed = isActive ? min(max(Float(current * 2.0), 0.3), 8.0) : 0.0

        for particleNode in coord.particleNodes {
            particleNode.particleSystems?.forEach { system in
                system.speedFactor = CGFloat(speed)
                system.particleColor = electronColor()
                system.particleColorVariation = SCNVector4(0.05, 0.1, 0.2, 0.0)

                if isShortCircuit && isActive {
                    system.emissionDuration = 0.05
                    system.idleDuration = 0.02
                    system.particleSize = 0.08
                    system.particleBounce = 0.8
                } else {
                    system.emissionDuration = 1.0
                    system.idleDuration = 0.0
                    system.particleSize = 0.04
                    system.particleBounce = 0.0
                }

                system.birthRate = isActive ? CGFloat(20 + current * 40) : 0
            }
        }

        // Spark effect for short circuit
        if isShortCircuit && isActive {
            if coord.sparkNode == nil {
                let spark = createSparkParticleSystem()
                let sparkHolder = SCNNode()
                sparkHolder.position = SCNVector3(0, 0.2, 0)
                sparkHolder.addParticleSystem(spark)
                uiView.scene?.rootNode.addChildNode(sparkHolder)
                coord.sparkNode = sparkHolder
            }
            coord.sparkNode?.isHidden = false
        } else {
            coord.sparkNode?.isHidden = true
        }

        // Update voltage gradient overlay colors
        updateVoltageGradient(coord: coord)
    }

    // MARK: - Scene Construction

    private func buildScene(coordinator: Coordinator) -> SCNScene {
        let scene = SCNScene()

        // Radial background
        let bgSize = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: bgSize)
        let bgImage = renderer.image { ctx in
            let center = CGPoint(x: bgSize.width / 2, y: bgSize.height / 2)
            let colors = [
                UIColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1).cgColor,
                UIColor(red: 0.08, green: 0.09, blue: 0.16, alpha: 1).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: bgSize.width / 2,
                    options: .drawsAfterEndLocation
                )
            }
        }
        scene.background.contents = bgImage

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 50
        cameraNode.position = SCNVector3(0, 4, 8)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // 3-point lighting
        addThreePointLighting(to: scene)

        // Build circuit path (rectangular loop)
        let wirePaths = buildCircuitWirePaths()
        coordinator.wirePathPoints = wirePaths

        for path in wirePaths {
            addWireSegment(to: scene, points: path)
        }

        // Add circuit components along the path
        addBatteryComponent(to: scene, at: SCNVector3(-3, 0, 0))
        addResistorComponent(to: scene, at: SCNVector3(3, 0, 0), coordinator: coordinator)

        // Add particle systems along wire paths
        for path in wirePaths {
            let particleNode = createParticleFlowNode(along: path)
            scene.rootNode.addChildNode(particleNode)
            coordinator.particleNodes.append(particleNode)
        }

        coordinator.hasBuilt = true
        return scene
    }

    // MARK: - 3-Point Lighting

    private func addThreePointLighting(to scene: SCNScene) {
        // Key light
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.color = UIColor(red: 1.0, green: 0.96, blue: 0.9, alpha: 1)
        keyLight.light?.castsShadow = true
        keyLight.position = SCNVector3(4, 6, 5)
        keyLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(keyLight)

        // Fill light
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.light?.color = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1)
        fillLight.position = SCNVector3(-4, 3, 5)
        fillLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fillLight)

        // Rim light
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.intensity = 200
        rimLight.position = SCNVector3(0, 4, -4)
        rimLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(rimLight)

        // Ambient
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 150
        ambientLight.light?.color = UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)
    }

    // MARK: - Wire Paths

    private func buildCircuitWirePaths() -> [[SCNVector3]] {
        // Rectangular circuit loop: battery (left) -> top wire -> resistor (right) -> bottom wire -> back to battery
        let left: Float = -3.0
        let right: Float = 3.0
        let top: Float = -2.0
        let bottom: Float = 2.0
        let y: Float = 0.0

        let topWire = [
            SCNVector3(left, y, top),
            SCNVector3(left + 1.5, y, top),
            SCNVector3(0, y, top),
            SCNVector3(right - 1.5, y, top),
            SCNVector3(right, y, top)
        ]

        let rightWire = [
            SCNVector3(right, y, top),
            SCNVector3(right, y, top + 1.0),
            SCNVector3(right, y, 0),
            SCNVector3(right, y, bottom - 1.0),
            SCNVector3(right, y, bottom)
        ]

        let bottomWire = [
            SCNVector3(right, y, bottom),
            SCNVector3(right - 1.5, y, bottom),
            SCNVector3(0, y, bottom),
            SCNVector3(left + 1.5, y, bottom),
            SCNVector3(left, y, bottom)
        ]

        let leftWire = [
            SCNVector3(left, y, bottom),
            SCNVector3(left, y, bottom - 1.0),
            SCNVector3(left, y, 0),
            SCNVector3(left, y, top + 1.0),
            SCNVector3(left, y, top)
        ]

        return [topWire, rightWire, bottomWire, leftWire]
    }

    private func addWireSegment(to scene: SCNScene, points: [SCNVector3]) {
        for i in 0..<(points.count - 1) {
            let start = points[i]
            let end = points[i + 1]

            let dx = end.x - start.x
            let dy = end.y - start.y
            let dz = end.z - start.z
            let length = sqrt(dx * dx + dy * dy + dz * dz)

            let wire = SCNCylinder(radius: 0.04, height: CGFloat(length))
            let wireMat = SCNMaterial()
            wireMat.lightingModel = .physicallyBased
            wireMat.diffuse.contents = UIColor(red: 0.7, green: 0.4, blue: 0.2, alpha: 1)
            wireMat.metalness.contents = CGFloat(0.8)
            wireMat.roughness.contents = CGFloat(0.3)
            wire.materials = [wireMat]

            let wireNode = SCNNode(geometry: wire)

            // Position at midpoint
            wireNode.position = SCNVector3(
                (start.x + end.x) / 2,
                (start.y + end.y) / 2,
                (start.z + end.z) / 2
            )

            // Orient cylinder to connect start and end
            wireNode.look(at: end, up: scene.rootNode.worldUp, localFront: SCNVector3(0, 1, 0))

            scene.rootNode.addChildNode(wireNode)
        }
    }

    // MARK: - Components

    private func addBatteryComponent(to scene: SCNScene, at position: SCNVector3) {
        let root = SCNNode()
        root.name = "battery"

        // Battery body
        let body = SCNCylinder(radius: 0.35, height: 1.2)
        let bodyMat = SCNMaterial()
        bodyMat.lightingModel = .physicallyBased
        bodyMat.diffuse.contents = UIColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1)
        bodyMat.metalness.contents = CGFloat(0.5)
        bodyMat.roughness.contents = CGFloat(0.35)
        body.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: body)
        root.addChildNode(bodyNode)

        // Positive terminal
        let terminal = SCNCylinder(radius: 0.12, height: 0.12)
        let termMat = SCNMaterial()
        termMat.lightingModel = .physicallyBased
        termMat.diffuse.contents = UIColor.lightGray
        termMat.metalness.contents = CGFloat(0.85)
        termMat.roughness.contents = CGFloat(0.15)
        terminal.materials = [termMat]
        let termNode = SCNNode(geometry: terminal)
        termNode.position = SCNVector3(0, 0.66, 0)
        root.addChildNode(termNode)

        // Plus label
        let plusText = SCNText(string: "+", extrusionDepth: 0.02)
        plusText.font = UIFont.boldSystemFont(ofSize: 0.3)
        plusText.firstMaterial?.diffuse.contents = UIColor.white
        plusText.firstMaterial?.lightingModel = .physicallyBased
        let plusNode = SCNNode(geometry: plusText)
        plusNode.position = SCNVector3(-0.07, 0.5, 0.36)
        root.addChildNode(plusNode)

        // Minus label
        let minusText = SCNText(string: "\u{2013}", extrusionDepth: 0.02)
        minusText.font = UIFont.boldSystemFont(ofSize: 0.3)
        minusText.firstMaterial?.diffuse.contents = UIColor.white
        minusText.firstMaterial?.lightingModel = .physicallyBased
        let minusNode = SCNNode(geometry: minusText)
        minusNode.position = SCNVector3(-0.07, -0.7, 0.36)
        root.addChildNode(minusNode)

        // Voltage gradient glow
        let glowLight = SCNNode()
        glowLight.light = SCNLight()
        glowLight.light?.type = .omni
        glowLight.light?.color = UIColor(red: 0.1, green: 0.9, blue: 0.3, alpha: 1)
        glowLight.light?.intensity = 80
        glowLight.light?.attenuationStartDistance = 0
        glowLight.light?.attenuationEndDistance = 2.0
        glowLight.position = SCNVector3(0, 0, 0)
        root.addChildNode(glowLight)

        root.position = position
        scene.rootNode.addChildNode(root)
    }

    private func addResistorComponent(to scene: SCNScene, at position: SCNVector3, coordinator: Coordinator) {
        let root = SCNNode()
        root.name = "resistor"

        // Resistor body
        let body = SCNCapsule(capRadius: 0.18, height: 1.0)
        let bodyMat = SCNMaterial()
        bodyMat.lightingModel = .physicallyBased
        bodyMat.diffuse.contents = UIColor(red: 0.82, green: 0.72, blue: 0.55, alpha: 1)
        bodyMat.roughness.contents = CGFloat(0.7)
        bodyMat.metalness.contents = CGFloat(0.1)
        body.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: body)
        root.addChildNode(bodyNode)

        // Color bands
        let bandColors: [UIColor] = [.red, .red, .brown, .init(red: 0.85, green: 0.65, blue: 0.0, alpha: 1)]
        for (i, color) in bandColors.enumerated() {
            let band = SCNCylinder(radius: 0.19, height: 0.04)
            let bandMat = SCNMaterial()
            bandMat.lightingModel = .physicallyBased
            bandMat.diffuse.contents = color
            bandMat.roughness.contents = CGFloat(0.5)
            band.materials = [bandMat]
            let bandNode = SCNNode(geometry: band)
            bandNode.position = SCNVector3(0, Float(i) * 0.16 - 0.24, 0)
            root.addChildNode(bandNode)
        }

        // Voltage gradient overlay node
        let gradientSphere = SCNSphere(radius: 0.6)
        let gradMat = SCNMaterial()
        gradMat.lightingModel = .physicallyBased
        gradMat.diffuse.contents = UIColor.clear
        gradMat.emission.contents = UIColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 1)
        gradMat.emission.intensity = 0.0
        gradMat.transparency = 0.3
        gradientSphere.materials = [gradMat]
        let gradNode = SCNNode(geometry: gradientSphere)
        gradNode.name = "voltageGradient"
        root.addChildNode(gradNode)
        coordinator.voltageGradientNodes.append(gradNode)

        root.position = position
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Particle Flow

    private func createParticleFlowNode(along path: [SCNVector3]) -> SCNNode {
        let holderNode = SCNNode()

        let system = SCNParticleSystem()
        system.birthRate = 25
        system.particleLifeSpan = 3.0
        system.particleSize = 0.04
        system.particleSizeVariation = 0.01
        system.particleColor = electronColor()
        system.particleColorVariation = SCNVector4(0.05, 0.1, 0.15, 0.0)
        system.speedFactor = 1.0
        system.emittingDirection = SCNVector3(1, 0, 0)
        system.spreadingAngle = 5
        system.particleVelocity = 1.5
        system.particleVelocityVariation = 0.3
        system.particleBounce = 0.0
        system.blendMode = .additive
        system.isAffectedByGravity = false
        system.isAffectedByPhysicsFields = false

        // Glow image for particle
        let glowSize = CGSize(width: 32, height: 32)
        let glowRenderer = UIGraphicsImageRenderer(size: glowSize)
        let glowImage = glowRenderer.image { ctx in
            let center = CGPoint(x: 16, y: 16)
            let colors = [
                UIColor.white.cgColor,
                UIColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.8).cgColor,
                UIColor(red: 0.0, green: 0.3, blue: 0.8, alpha: 0.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.4, 1.0]) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: 16,
                    options: .drawsAfterEndLocation
                )
            }
        }
        system.particleImage = glowImage

        // Emission geometry: create a thin tube along the path for particles to emit from
        if path.count >= 2 {
            let emitterGeometry = createTubeAlongPath(path, radius: 0.02)
            system.emitterShape = emitterGeometry
        }

        holderNode.addParticleSystem(system)

        // Position at center of path
        if let first = path.first, let last = path.last {
            holderNode.position = SCNVector3(
                (first.x + last.x) / 2,
                (first.y + last.y) / 2 + 0.05,
                (first.z + last.z) / 2
            )
        }

        return holderNode
    }

    private func createTubeAlongPath(_ path: [SCNVector3], radius: CGFloat) -> SCNGeometry {
        // Create a simple box that spans the path for the emitter shape
        guard let first = path.first, let last = path.last else {
            return SCNSphere(radius: 0.1)
        }
        let dx = last.x - first.x
        let dz = last.z - first.z
        let length = sqrt(dx * dx + dz * dz)
        return SCNBox(width: CGFloat(length), height: 0.02, length: 0.02, chamferRadius: 0)
    }

    // MARK: - Spark Effect

    private func createSparkParticleSystem() -> SCNParticleSystem {
        let spark = SCNParticleSystem()
        spark.birthRate = 200
        spark.particleLifeSpan = 0.4
        spark.particleLifeSpanVariation = 0.2
        spark.particleSize = 0.03
        spark.particleSizeVariation = 0.02
        spark.particleColor = UIColor.yellow
        spark.particleColorVariation = SCNVector4(0.1, 0.2, 0.0, 0.0)
        spark.speedFactor = 3.0
        spark.emittingDirection = SCNVector3(0, 1, 0)
        spark.spreadingAngle = 180
        spark.particleVelocity = 4.0
        spark.particleVelocityVariation = 2.0
        spark.particleBounce = 0.5
        spark.blendMode = .additive
        spark.isAffectedByGravity = true
        spark.acceleration = SCNVector3(0, -8, 0)

        // Bright spark image
        let sparkSize = CGSize(width: 16, height: 16)
        let sparkRenderer = UIGraphicsImageRenderer(size: sparkSize)
        let sparkImage = sparkRenderer.image { ctx in
            let center = CGPoint(x: 8, y: 8)
            let colors = [
                UIColor.white.cgColor,
                UIColor.yellow.cgColor,
                UIColor.orange.withAlphaComponent(0.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.3, 1.0]) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: 8,
                    options: .drawsAfterEndLocation
                )
            }
        }
        spark.particleImage = sparkImage

        // Emit from a small sphere
        spark.emitterShape = SCNSphere(radius: 0.15)

        return spark
    }

    // MARK: - Helpers

    private func electronColor() -> UIColor {
        // Color intensity based on current magnitude
        let intensity = min(max(current / 2.0, 0.3), 1.0)
        if isShortCircuit {
            return UIColor(
                red: 1.0,
                green: CGFloat(0.8 * intensity),
                blue: 0.0,
                alpha: 1.0
            )
        }
        return UIColor(
            red: CGFloat(0.1 * intensity),
            green: CGFloat(0.6 + 0.4 * intensity),
            blue: CGFloat(0.8 + 0.2 * intensity),
            alpha: 1.0
        )
    }

    private func updateVoltageGradient(coord: Coordinator) {
        let voltageDrop = current * resistance
        let normalizedDrop = min(voltageDrop / max(voltage, 1.0), 1.0)

        for gradNode in coord.voltageGradientNodes {
            if isActive {
                let emissionIntensity = CGFloat(normalizedDrop * 1.5)
                gradNode.geometry?.firstMaterial?.emission.intensity = emissionIntensity

                let r = CGFloat(0.3 + normalizedDrop * 0.7)
                let g = CGFloat(0.1)
                let b = CGFloat(0.8 - normalizedDrop * 0.5)
                gradNode.geometry?.firstMaterial?.emission.contents = UIColor(
                    red: r, green: g, blue: b, alpha: 1.0
                )
            } else {
                gradNode.geometry?.firstMaterial?.emission.intensity = 0.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CurrentFlowSimulation(voltage: 9.0, resistance: 220.0, isActive: true)
}
