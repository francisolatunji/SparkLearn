import Foundation
import Combine
import SceneKit
import UIKit

#if canImport(ARKit)
import ARKit
#endif

// MARK: - Placed AR Component Model

struct ARPlacedComponent: Identifiable {
    let id = UUID()
    let sceneType: SceneType
    var position: SIMD3<Float>
    var rotation: SIMD4<Float>
    var scale: Float
    let placedAt: Date

    var displayName: String {
        switch sceneType {
        case .atom:            return "Atom"
        case .battery:         return "Battery"
        case .lightBulb:       return "Light Bulb"
        case .circuit:         return "Circuit"
        case .resistor:        return "Resistor"
        case .led:             return "LED"
        case .capacitor:       return "Capacitor"
        case .diode:           return "Diode"
        case .switchToggle:    return "Switch"
        case .lightning:       return "Lightning"
        case .seriesCircuit:   return "Series Circuit"
        case .parallelCircuit: return "Parallel Circuit"
        case .multimeter:      return "Multimeter"
        case .breadboard:      return "Breadboard"
        case .arduino:         return "Arduino"
        case .fuseBox:         return "Fuse Box"
        }
    }

    var specs: String {
        switch sceneType {
        case .atom:            return "Bohr model -- protons, neutrons, electrons"
        case .battery:         return "9V alkaline -- 500mAh capacity"
        case .lightBulb:       return "Incandescent -- 60W, 120V"
        case .circuit:         return "Basic closed loop circuit"
        case .resistor:        return "Carbon film -- 1k ohm, 1/4W"
        case .led:             return "5mm red LED -- 2V forward, 20mA"
        case .capacitor:       return "Electrolytic -- 100uF, 25V"
        case .diode:           return "1N4007 -- 1A, 1000V PIV"
        case .switchToggle:    return "SPST toggle -- 5A, 125VAC"
        case .lightning:       return "Electrostatic discharge visualization"
        case .seriesCircuit:   return "Components in series -- same current"
        case .parallelCircuit: return "Components in parallel -- same voltage"
        case .multimeter:      return "Digital -- V, A, ohm measurement"
        case .breadboard:      return "830 tie-point solderless breadboard"
        case .arduino:         return "Uno R3 -- ATmega328P, 14 digital I/O"
        case .fuseBox:         return "Automotive blade fuse -- 15A rated"
        }
    }

    var iconName: String {
        switch sceneType {
        case .atom:            return "atom"
        case .battery:         return "battery.100"
        case .lightBulb:       return "lightbulb.fill"
        case .circuit:         return "point.3.connected.trianglepath.dotted"
        case .resistor:        return "wave.3.right"
        case .led:             return "light.max"
        case .capacitor:       return "battery.25"
        case .diode:           return "arrow.right.to.line"
        case .switchToggle:    return "switch.2"
        case .lightning:       return "bolt.fill"
        case .seriesCircuit:   return "arrow.right"
        case .parallelCircuit: return "arrow.triangle.branch"
        case .multimeter:      return "gauge.medium"
        case .breadboard:      return "rectangle.split.3x3"
        case .arduino:         return "cpu"
        case .fuseBox:         return "shield.fill"
        }
    }
}

// MARK: - AR Session State

enum ARSessionState: Equatable {
    case notStarted
    case initializing
    case scanning
    case surfaceDetected
    case tracking
    case limitedTracking(reason: String)
    case paused
    case failed(error: String)

    var statusMessage: String {
        switch self {
        case .notStarted:                return "Tap Start to begin AR"
        case .initializing:              return "Initializing AR session..."
        case .scanning:                  return "Move your phone to scan a surface"
        case .surfaceDetected:           return "Surface found! Tap to place a component"
        case .tracking:                  return "Tracking active"
        case .limitedTracking(let reason): return "Limited tracking: \(reason)"
        case .paused:                    return "AR session paused"
        case .failed(let error):         return "AR failed: \(error)"
        }
    }
}

// MARK: - AR Session Manager

final class ARSessionManager: NSObject, ObservableObject {

    // MARK: Published Properties

    @Published var isARSupported: Bool = false
    @Published var sessionState: ARSessionState = .notStarted
    @Published var placedComponents: [ARPlacedComponent] = []
    @Published var detectedSurfacesCount: Int = 0
    @Published var selectedComponentType: SceneType = .resistor
    @Published var lastScreenshot: UIImage?

    var placedComponentsCount: Int { placedComponents.count }

    // MARK: - Lifecycle

    override init() {
        super.init()
        isARSupported = ARSessionManager.checkARAvailability()
    }

    // MARK: - Static Availability Check

    static func checkARAvailability() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return ARWorldTrackingConfiguration.isSupported
        #endif
    }

    // MARK: - Session Control

    /// Call from the AR view after obtaining the ARSession reference.
    func startSession(on session: ARSession) {
        guard isARSupported else {
            sessionState = .failed(error: "AR not supported on this device")
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        session.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sessionState = .initializing
    }

    func pauseSession(on session: ARSession) {
        session.pause()
        sessionState = .paused
    }

    func resetSession(on session: ARSession) {
        placedComponents.removeAll()
        detectedSurfacesCount = 0
        startSession(on: session)
    }

    // MARK: - Component Placement

    /// Places a component node at the given world transform from an AR raycast/hit-test.
    @discardableResult
    func placeComponent(
        _ type: SceneType,
        at worldTransform: simd_float4x4,
        in sceneView: SCNView
    ) -> SCNNode {
        let position = SIMD3<Float>(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )

        let componentNode = ARComponentNodeBuilder.buildNode(for: type)
        componentNode.simdPosition = position
        componentNode.name = "arComponent_\(type.rawValue)_\(UUID().uuidString)"

        sceneView.scene?.rootNode.addChildNode(componentNode)

        let placed = ARPlacedComponent(
            sceneType: type,
            position: position,
            rotation: SIMD4<Float>(0, 1, 0, 0),
            scale: 1.0,
            placedAt: Date()
        )

        placedComponents.append(placed)

        return componentNode
    }

    // MARK: - Screenshot

    func captureScreenshot(from view: UIView) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        lastScreenshot = image
        return image
    }
}

// MARK: - ARSessionDelegate

extension ARSessionManager: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let state = frame.camera.trackingState
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch state {
            case .normal:
                if self.detectedSurfacesCount > 0 {
                    self.sessionState = .surfaceDetected
                } else {
                    self.sessionState = .scanning
                }
            case .notAvailable:
                self.sessionState = .initializing
            case .limited(let reason):
                let reasonString: String
                switch reason {
                case .excessiveMotion:        reasonString = "Too much motion"
                case .insufficientFeatures:   reasonString = "Not enough detail"
                case .initializing:           reasonString = "Initializing"
                case .relocalizing:           reasonString = "Relocalizing"
                @unknown default:             reasonString = "Unknown"
                }
                self.sessionState = .limitedTracking(reason: reasonString)
            }
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let planeCount = anchors.compactMap { $0 as? ARPlaneAnchor }.count
        if planeCount > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.detectedSurfacesCount += planeCount
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .failed(error: error.localizedDescription)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .paused
        }
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .scanning
        }
    }
}

// MARK: - AR Component Node Builder

/// Builds simplified SceneKit nodes for AR placement.
/// These are lightweight versions of the full 3D models used in Scene3DView.
enum ARComponentNodeBuilder {

    static func buildNode(for type: SceneType) -> SCNNode {
        let root = SCNNode()

        switch type {
        case .resistor:
            let body = SCNCylinder(radius: 0.015, height: 0.06)
            body.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1))
            let bodyNode = SCNNode(geometry: body)
            bodyNode.eulerAngles.z = .pi / 2
            root.addChildNode(bodyNode)
            addColorBands(to: root)

        case .capacitor:
            let cylinder = SCNCylinder(radius: 0.012, height: 0.04)
            cylinder.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.15, green: 0.15, blue: 0.6, alpha: 1))
            let node = SCNNode(geometry: cylinder)
            root.addChildNode(node)
            addLeads(to: root, spacing: 0.015)

        case .led:
            let dome = SCNSphere(radius: 0.012)
            dome.firstMaterial = makeMaterial(
                diffuse: UIColor.red.withAlphaComponent(0.8),
                emission: UIColor.red
            )
            let domeNode = SCNNode(geometry: dome)
            domeNode.position.y = 0.015
            root.addChildNode(domeNode)

            let base = SCNCylinder(radius: 0.01, height: 0.015)
            base.firstMaterial = makeMaterial(diffuse: UIColor.red.withAlphaComponent(0.5))
            let baseNode = SCNNode(geometry: base)
            root.addChildNode(baseNode)
            addLeads(to: root, spacing: 0.008)

        case .diode:
            let body = SCNCylinder(radius: 0.008, height: 0.03)
            body.firstMaterial = makeMaterial(diffuse: UIColor.darkGray)
            let bodyNode = SCNNode(geometry: body)
            bodyNode.eulerAngles.z = .pi / 2
            root.addChildNode(bodyNode)

            let band = SCNCylinder(radius: 0.0085, height: 0.004)
            band.firstMaterial = makeMaterial(diffuse: UIColor.white)
            let bandNode = SCNNode(geometry: band)
            bandNode.eulerAngles.z = .pi / 2
            bandNode.position.x = 0.01
            root.addChildNode(bandNode)

        case .battery:
            let body = SCNCylinder(radius: 0.015, height: 0.05)
            body.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1))
            let bodyNode = SCNNode(geometry: body)
            root.addChildNode(bodyNode)

            let terminal = SCNCylinder(radius: 0.006, height: 0.006)
            terminal.firstMaterial = makeMaterial(diffuse: UIColor.lightGray, metalness: 0.8)
            let termNode = SCNNode(geometry: terminal)
            termNode.position.y = 0.028
            root.addChildNode(termNode)

        case .lightBulb:
            let glass = SCNSphere(radius: 0.02)
            glass.firstMaterial = makeMaterial(
                diffuse: UIColor.yellow.withAlphaComponent(0.3),
                emission: UIColor.yellow
            )
            glass.firstMaterial?.transparency = 0.6
            let glassNode = SCNNode(geometry: glass)
            glassNode.position.y = 0.015
            root.addChildNode(glassNode)

            let base = SCNCylinder(radius: 0.012, height: 0.02)
            base.firstMaterial = makeMaterial(diffuse: UIColor.gray, metalness: 0.7)
            let baseNode = SCNNode(geometry: base)
            baseNode.position.y = -0.005
            root.addChildNode(baseNode)

        case .switchToggle:
            let body = SCNBox(width: 0.03, height: 0.015, length: 0.02, chamferRadius: 0.002)
            body.firstMaterial = makeMaterial(diffuse: UIColor.darkGray)
            let bodyNode = SCNNode(geometry: body)
            root.addChildNode(bodyNode)

            let toggle = SCNCylinder(radius: 0.003, height: 0.02)
            toggle.firstMaterial = makeMaterial(diffuse: UIColor.lightGray, metalness: 0.6)
            let toggleNode = SCNNode(geometry: toggle)
            toggleNode.position.y = 0.015
            toggleNode.eulerAngles.z = .pi / 6
            root.addChildNode(toggleNode)

        case .atom:
            let nucleus = SCNSphere(radius: 0.012)
            nucleus.firstMaterial = makeMaterial(diffuse: UIColor.red, emission: UIColor.red)
            let nucleusNode = SCNNode(geometry: nucleus)
            root.addChildNode(nucleusNode)

            for i in 0..<3 {
                let orbit = SCNTorus(ringRadius: 0.03 + CGFloat(i) * 0.008, pipeRadius: 0.001)
                orbit.firstMaterial = makeMaterial(
                    diffuse: UIColor.systemBlue.withAlphaComponent(0.4)
                )
                let orbitNode = SCNNode(geometry: orbit)
                orbitNode.eulerAngles.x = Float(i) * .pi / 3
                orbitNode.eulerAngles.z = Float(i) * .pi / 4
                root.addChildNode(orbitNode)

                let electron = SCNSphere(radius: 0.004)
                electron.firstMaterial = makeMaterial(diffuse: UIColor.cyan, emission: UIColor.cyan)
                let electronNode = SCNNode(geometry: electron)
                electronNode.position.x = Float(0.03 + CGFloat(i) * 0.008)
                orbitNode.addChildNode(electronNode)
            }

        case .multimeter:
            let body = SCNBox(width: 0.04, height: 0.06, length: 0.015, chamferRadius: 0.003)
            body.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 1))
            let bodyNode = SCNNode(geometry: body)
            root.addChildNode(bodyNode)

            let screen = SCNBox(width: 0.03, height: 0.02, length: 0.001, chamferRadius: 0.001)
            screen.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.7, green: 0.85, blue: 0.7, alpha: 1), emission: UIColor.green)
            let screenNode = SCNNode(geometry: screen)
            screenNode.position = SCNVector3(0, 0.012, 0.009)
            root.addChildNode(screenNode)

        case .breadboard:
            let board = SCNBox(width: 0.06, height: 0.005, length: 0.03, chamferRadius: 0.001)
            board.firstMaterial = makeMaterial(diffuse: UIColor.white)
            let boardNode = SCNNode(geometry: board)
            root.addChildNode(boardNode)

            for row in stride(from: -0.025, to: 0.025, by: 0.005) {
                for col in stride(from: -0.012, to: 0.012, by: 0.004) {
                    let hole = SCNCylinder(radius: 0.0008, height: 0.006)
                    hole.firstMaterial = makeMaterial(diffuse: UIColor.darkGray)
                    let holeNode = SCNNode(geometry: hole)
                    holeNode.position = SCNVector3(Float(row), 0.003, Float(col))
                    root.addChildNode(holeNode)
                }
            }

        case .arduino:
            let pcb = SCNBox(width: 0.05, height: 0.003, length: 0.035, chamferRadius: 0.001)
            pcb.firstMaterial = makeMaterial(diffuse: UIColor(red: 0.0, green: 0.4, blue: 0.5, alpha: 1))
            let pcbNode = SCNNode(geometry: pcb)
            root.addChildNode(pcbNode)

            let chip = SCNBox(width: 0.015, height: 0.004, length: 0.015, chamferRadius: 0.0005)
            chip.firstMaterial = makeMaterial(diffuse: UIColor.black)
            let chipNode = SCNNode(geometry: chip)
            chipNode.position.y = 0.004
            root.addChildNode(chipNode)

            let usb = SCNBox(width: 0.01, height: 0.006, length: 0.008, chamferRadius: 0.001)
            usb.firstMaterial = makeMaterial(diffuse: UIColor.lightGray, metalness: 0.7)
            let usbNode = SCNNode(geometry: usb)
            usbNode.position = SCNVector3(-0.025, 0.004, 0)
            root.addChildNode(usbNode)

        case .fuseBox:
            let body = SCNBox(width: 0.025, height: 0.03, length: 0.01, chamferRadius: 0.002)
            body.firstMaterial = makeMaterial(diffuse: UIColor.clear)
            body.firstMaterial?.transparency = 0.5
            let bodyNode = SCNNode(geometry: body)
            root.addChildNode(bodyNode)

            let element = SCNCylinder(radius: 0.002, height: 0.02)
            element.firstMaterial = makeMaterial(diffuse: UIColor.lightGray, metalness: 0.6)
            let elementNode = SCNNode(geometry: element)
            elementNode.eulerAngles.z = .pi / 2
            root.addChildNode(elementNode)

        case .circuit, .seriesCircuit, .parallelCircuit, .lightning:
            // For circuit-type scenes, create a symbolic representation
            let sphere = SCNSphere(radius: 0.02)
            sphere.firstMaterial = makeMaterial(
                diffuse: UIColor(red: 0.15, green: 0.5, blue: 0.9, alpha: 1),
                emission: UIColor(red: 0.0, green: 0.3, blue: 0.8, alpha: 1)
            )
            let sphereNode = SCNNode(geometry: sphere)
            root.addChildNode(sphereNode)

            // Orbiting ring to represent connectivity
            let ring = SCNTorus(ringRadius: 0.035, pipeRadius: 0.002)
            ring.firstMaterial = makeMaterial(
                diffuse: UIColor(red: 0.0, green: 0.83, blue: 1.0, alpha: 0.6)
            )
            let ringNode = SCNNode(geometry: ring)
            root.addChildNode(ringNode)
        }

        // Scale for AR (components should appear at a comfortable real-world size)
        root.scale = SCNVector3(2.0, 2.0, 2.0)

        return root
    }

    // MARK: - Material Helper

    private static func makeMaterial(
        diffuse: Any?,
        metalness: CGFloat = 0.1,
        roughness: CGFloat = 0.5,
        emission: Any? = nil
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = diffuse
        mat.metalness.contents = metalness
        mat.roughness.contents = roughness
        if let em = emission {
            mat.emission.contents = em
            mat.emission.intensity = 0.4
        }
        return mat
    }

    // MARK: - Resistor Helpers

    private static func addColorBands(to root: SCNNode) {
        let bandColors: [UIColor] = [.brown, .black, .red, .systemYellow]
        for (i, color) in bandColors.enumerated() {
            let band = SCNCylinder(radius: 0.0155, height: 0.003)
            band.firstMaterial = makeMaterial(diffuse: color)
            let bandNode = SCNNode(geometry: band)
            bandNode.eulerAngles.z = .pi / 2
            bandNode.position.x = -0.02 + Float(i) * 0.01
            root.addChildNode(bandNode)
        }
    }

    private static func addLeads(to root: SCNNode, spacing: Float) {
        for side in [-1.0, 1.0] as [Float] {
            let lead = SCNCylinder(radius: 0.001, height: 0.025)
            lead.firstMaterial = makeMaterial(diffuse: UIColor.lightGray, metalness: 0.7)
            let leadNode = SCNNode(geometry: lead)
            leadNode.position = SCNVector3(side * spacing, -0.02, 0)
            root.addChildNode(leadNode)
        }
    }
}
