import SwiftUI
import SceneKit

// MARK: - Circuit Builder View
struct CircuitBuilderView: View {
    @StateObject private var viewModel = CircuitBuilderViewModel()
    @EnvironmentObject var progress: ProgressManager
    @State private var showComponentTray = true
    @State private var selectedComponent: SimulatedComponent?
    @State private var showSimulation = false
    @State private var showResults = false

    var body: some View {
        ZStack {
            // 3D Scene
            CircuitBuilder3DView(viewModel: viewModel, selectedComponent: $selectedComponent)
                .ignoresSafeArea()

            VStack {
                // Top Bar
                HStack {
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .disabled(viewModel.undoStack.isEmpty)

                    Button(action: { viewModel.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .disabled(viewModel.redoStack.isEmpty)

                    Spacer()

                    // Component count
                    Text("\(viewModel.placedComponents.count) components")
                        .font(DS.captionFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.ultraThinMaterial))

                    Spacer()

                    Button(action: { viewModel.clearAll() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(DS.error)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.top, 8)

                Spacer()

                // Simulation info overlay
                if showSimulation, let result = viewModel.simulationResult {
                    SimulationResultsOverlay(result: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Component Tray
                if showComponentTray {
                    ComponentTrayView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Bottom Action Bar
                HStack(spacing: 16) {
                    SecondaryButton("Components", icon: showComponentTray ? "chevron.down" : "chevron.up") {
                        withAnimation(.spring(response: 0.3)) {
                            showComponentTray.toggle()
                        }
                    }

                    PrimaryButton("Simulate", icon: "bolt.fill") {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.runSimulation()
                            showSimulation = true
                        }
                        Haptics.medium()
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, 16)
            }

            // Selected component info
            if let component = selectedComponent {
                VStack {
                    Spacer()
                    ComponentInfoPanel(component: component, onRotate: {
                        viewModel.rotateComponent(component.id)
                    }, onDelete: {
                        viewModel.removeComponent(component.id)
                        selectedComponent = nil
                    }, onValueChange: { newValue in
                        viewModel.updateComponentValue(component.id, value: newValue)
                    })
                    .padding(.bottom, 200)
                }
                .transition(.opacity)
            }
        }
        .background(Color.black)
    }
}

// MARK: - Circuit Builder 3D SceneKit View
struct CircuitBuilder3DView: UIViewRepresentable {
    @ObservedObject var viewModel: CircuitBuilderViewModel
    @Binding var selectedComponent: SimulatedComponent?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = viewModel.scene
        scnView.backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = viewModel.scene
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: CircuitBuilder3DView

        init(_ parent: CircuitBuilder3DView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])

            if let hit = hitResults.first, let name = hit.node.name ?? hit.node.parent?.name {
                if let component = parent.viewModel.placedComponents.first(where: { $0.id == name }) {
                    parent.selectedComponent = component
                    Haptics.light()
                }
            } else {
                parent.selectedComponent = nil
            }
        }
    }
}

// MARK: - Component Tray
struct ComponentTrayView: View {
    @ObservedObject var viewModel: CircuitBuilderViewModel

    let componentTypes: [SimulatedComponent.ComponentType] = [
        .battery, .resistor, .led, .capacitor, .wire,
        .switchToggle, .buzzer, .potentiometer, .diode, .fuse, .motor
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(componentTypes, id: \.rawValue) { type in
                    ComponentTrayItem(type: type) {
                        viewModel.addComponent(type: type)
                        Haptics.light()
                    }
                }
            }
            .padding(.horizontal, DS.padding)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardCorner))
        .padding(.horizontal, 8)
    }
}

struct ComponentTrayItem: View {
    let type: SimulatedComponent.ComponentType
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: type.color))
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: type.color).opacity(0.15))
                    )

                Text(type.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .scaleEffect(pressed ? 0.9 : 1.0)
        .animation(DS.tapAnim, value: pressed)
    }
}

// MARK: - Component Info Panel
struct ComponentInfoPanel: View {
    let component: SimulatedComponent
    let onRotate: () -> Void
    let onDelete: () -> Void
    let onValueChange: (Double) -> Void

    @State private var sliderValue: Double = 0

    var body: some View {
        DSGlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: component.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: component.type.color))

                    Text(component.type.displayName)
                        .font(DS.headlineFont)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: onRotate) {
                        Image(systemName: "rotate.right")
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }

                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .foregroundColor(DS.error)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(DS.error.opacity(0.15)))
                    }
                }

                if component.type == .resistor || component.type == .potentiometer {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Resistance: \(formatValue(sliderValue))Ω")
                            .font(DS.captionFont)
                            .foregroundColor(.white.opacity(0.7))

                        Slider(value: $sliderValue, in: 10...100000, step: 10)
                            .tint(Color(hex: component.type.color))
                            .onChange(of: sliderValue) { _, newValue in
                                onValueChange(newValue)
                            }
                    }
                }

                if component.type == .battery {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voltage: \(String(format: "%.1f", sliderValue))V")
                            .font(DS.captionFont)
                            .foregroundColor(.white.opacity(0.7))

                        Slider(value: $sliderValue, in: 1.5...24, step: 0.5)
                            .tint(Color(hex: component.type.color))
                            .onChange(of: sliderValue) { _, newValue in
                                onValueChange(newValue)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, DS.padding)
        .onAppear {
            sliderValue = component.value
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fk", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Simulation Results Overlay
struct SimulationResultsOverlay: View {
    let result: SimulationResult

    var body: some View {
        DSGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: stateIcon)
                        .foregroundColor(stateColor)
                    Text(stateTitle)
                        .font(DS.headlineFont)
                        .foregroundColor(.white)
                }

                if result.state == .closed || result.state == .overload {
                    HStack(spacing: 20) {
                        SimStatView(label: "Voltage", value: String(format: "%.1fV", result.totalVoltage), color: DS.success)
                        SimStatView(label: "Current", value: formatCurrent(result.totalCurrent), color: DS.electricBlue)
                        SimStatView(label: "Resistance", value: formatResistance(result.totalResistance), color: DS.deepPurple)
                    }
                }

                ForEach(result.warnings, id: \.self) { warning in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DS.warning)
                            .font(.system(size: 14))
                        Text(warning)
                            .font(DS.captionFont)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                ForEach(result.failures, id: \.componentId) { failure in
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundColor(DS.error)
                            .font(.system(size: 14))
                        Text(failure.description)
                            .font(DS.captionFont)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(.horizontal, DS.padding)
    }

    private var stateIcon: String {
        switch result.state {
        case .closed: return "checkmark.circle.fill"
        case .shortCircuit: return "bolt.trianglebadge.exclamationmark.fill"
        case .overload: return "exclamationmark.triangle.fill"
        case .open: return "circle.slash"
        case .incomplete: return "questionmark.circle"
        case .reversed: return "arrow.left.arrow.right"
        }
    }

    private var stateColor: Color {
        switch result.state {
        case .closed: return DS.success
        case .shortCircuit, .overload: return DS.error
        case .open, .incomplete: return DS.warning
        case .reversed: return DS.accent
        }
    }

    private var stateTitle: String {
        switch result.state {
        case .closed: return "Circuit Active"
        case .shortCircuit: return "Short Circuit!"
        case .overload: return "Component Failure"
        case .open: return "Circuit Open"
        case .incomplete: return "Incomplete Circuit"
        case .reversed: return "Wrong Polarity"
        }
    }

    private func formatCurrent(_ amps: Double) -> String {
        if amps < 0.001 { return String(format: "%.1fµA", amps * 1_000_000) }
        if amps < 1.0 { return String(format: "%.1fmA", amps * 1_000) }
        return String(format: "%.2fA", amps)
    }

    private func formatResistance(_ ohms: Double) -> String {
        if ohms >= 1_000_000 { return String(format: "%.1fMΩ", ohms / 1_000_000) }
        if ohms >= 1_000 { return String(format: "%.1fkΩ", ohms / 1_000) }
        return String(format: "%.0fΩ", ohms)
    }
}

struct SimStatView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Circuit Builder ViewModel
class CircuitBuilderViewModel: ObservableObject {
    @Published var placedComponents: [SimulatedComponent] = []
    @Published var connections: [CircuitConnection] = []
    @Published var simulationResult: SimulationResult?
    @Published var undoStack: [[SimulatedComponent]] = []
    @Published var redoStack: [[SimulatedComponent]] = []

    let scene = SCNScene()
    private let simulator = CircuitSimulator()
    private let gridSize = 10
    private var nextRow = 0
    private var nextCol = 0

    init() {
        setupScene()
    }

    private func setupScene() {
        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = 50
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 8, 10)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Lighting
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 800
        keyLight.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(5, 10, 5)
        keyNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(keyNode)

        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.intensity = 400
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(-5, 8, -3)
        fillNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fillNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 200
        ambient.color = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        // Breadboard base
        let boardGeometry = SCNBox(width: 8, height: 0.2, length: 5, chamferRadius: 0.1)
        let boardMaterial = SCNMaterial()
        boardMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.88, blue: 0.82, alpha: 1)
        boardMaterial.roughness.contents = 0.8
        boardGeometry.materials = [boardMaterial]
        let boardNode = SCNNode(geometry: boardGeometry)
        boardNode.position = SCNVector3(0, -0.1, 0)
        boardNode.name = "breadboard"
        scene.rootNode.addChildNode(boardNode)

        // Grid holes
        for row in -4..<5 {
            for col in -7..<8 {
                let hole = SCNCylinder(radius: 0.04, height: 0.21)
                let holeMat = SCNMaterial()
                holeMat.diffuse.contents = UIColor.darkGray
                hole.materials = [holeMat]
                let holeNode = SCNNode(geometry: hole)
                holeNode.position = SCNVector3(Float(col) * 0.5, 0, Float(row) * 0.5)
                boardNode.addChildNode(holeNode)
            }
        }
    }

    // MARK: - Component Management

    func addComponent(type: SimulatedComponent.ComponentType) {
        saveUndoState()

        let position = GridPosition(row: nextRow, col: nextCol)
        let component = SimulatedComponent(type: type, position: position)
        placedComponents.append(component)

        // Create 3D node
        let node = createComponentNode(for: component)
        scene.rootNode.addChildNode(node)

        // Advance grid position
        nextCol += 2
        if nextCol >= gridSize {
            nextCol = 0
            nextRow += 2
        }
    }

    func removeComponent(_ id: String) {
        saveUndoState()
        placedComponents.removeAll { $0.id == id }
        scene.rootNode.childNode(withName: id, recursively: true)?.removeFromParentNode()
    }

    func rotateComponent(_ id: String) {
        guard let index = placedComponents.firstIndex(where: { $0.id == id }) else { return }
        placedComponents[index].rotation = (placedComponents[index].rotation + 90) % 360

        if let node = scene.rootNode.childNode(withName: id, recursively: true) {
            let action = SCNAction.rotateBy(x: 0, y: .pi / 2, z: 0, duration: 0.3)
            node.runAction(action)
        }
    }

    func updateComponentValue(_ id: String, value: Double) {
        guard let index = placedComponents.firstIndex(where: { $0.id == id }) else { return }
        placedComponents[index].value = value
    }

    func clearAll() {
        saveUndoState()
        placedComponents.removeAll()
        connections.removeAll()
        simulationResult = nil

        // Remove all component nodes
        scene.rootNode.childNodes.filter { $0.name != "breadboard" && $0.camera == nil && $0.light == nil }
            .forEach { $0.removeFromParentNode() }

        nextRow = 0
        nextCol = 0
    }

    // MARK: - Undo/Redo

    func saveUndoState() {
        undoStack.append(placedComponents)
        redoStack.removeAll()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(placedComponents)
        placedComponents = previous
        rebuildScene()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(placedComponents)
        placedComponents = next
        rebuildScene()
    }

    private func rebuildScene() {
        scene.rootNode.childNodes
            .filter { $0.name != "breadboard" && $0.camera == nil && $0.light == nil }
            .forEach { $0.removeFromParentNode() }

        for component in placedComponents {
            let node = createComponentNode(for: component)
            scene.rootNode.addChildNode(node)
        }
    }

    // MARK: - Simulation

    func runSimulation() {
        simulationResult = simulator.simulate(components: placedComponents, connections: connections)

        // Visual feedback based on results
        if let result = simulationResult {
            animateSimulationResults(result)
        }
    }

    private func animateSimulationResults(_ result: SimulationResult) {
        // Animate current flow through components
        for (componentId, current) in result.componentCurrents {
            guard let node = scene.rootNode.childNode(withName: componentId, recursively: true) else { continue }

            if current > 0 {
                // Glow effect for active components
                let material = node.geometry?.firstMaterial
                let glowAction = SCNAction.customAction(duration: 1.0) { node, elapsed in
                    let intensity = sin(elapsed * .pi * 2) * 0.3 + 0.5
                    material?.emission.contents = UIColor(
                        red: 0.2,
                        green: CGFloat(intensity),
                        blue: CGFloat(intensity),
                        alpha: CGFloat(intensity)
                    )
                }
                node.runAction(SCNAction.repeatForever(glowAction))
            }
        }

        // Failure animations
        for failure in result.failures {
            guard let node = scene.rootNode.childNode(withName: failure.componentId, recursively: true) else { continue }

            switch failure.type {
            case .burnedOut:
                // Smoke-like fade
                let fadeAction = SCNAction.sequence([
                    SCNAction.scale(to: 1.2, duration: 0.2),
                    SCNAction.fadeOut(duration: 0.5),
                    SCNAction.scale(to: 0.8, duration: 0.3)
                ])
                node.runAction(fadeAction)

            case .shortCircuit:
                // Flash effect
                let flashAction = SCNAction.sequence([
                    SCNAction.customAction(duration: 0.1) { n, _ in n.geometry?.firstMaterial?.emission.contents = UIColor.yellow },
                    SCNAction.customAction(duration: 0.1) { n, _ in n.geometry?.firstMaterial?.emission.contents = UIColor.clear },
                ])
                node.runAction(SCNAction.repeat(flashAction, count: 5))

            default:
                // Shake
                let shake = SCNAction.sequence([
                    SCNAction.moveBy(x: 0.05, y: 0, z: 0, duration: 0.05),
                    SCNAction.moveBy(x: -0.1, y: 0, z: 0, duration: 0.05),
                    SCNAction.moveBy(x: 0.05, y: 0, z: 0, duration: 0.05),
                ])
                node.runAction(SCNAction.repeat(shake, count: 3))
            }
        }
    }

    // MARK: - 3D Node Creation

    private func createComponentNode(for component: SimulatedComponent) -> SCNNode {
        let node: SCNNode

        switch component.type {
        case .battery:
            node = createBatteryNode()
        case .resistor:
            node = createResistorNode(value: component.value)
        case .led:
            node = createLEDNode()
        case .capacitor:
            node = createCapacitorNode()
        case .wire:
            node = createWireNode()
        case .switchToggle:
            node = createSwitchNode()
        case .buzzer:
            node = createBuzzerNode()
        case .motor:
            node = createMotorNode()
        default:
            node = createGenericNode(color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        }

        node.name = component.id
        node.position = SCNVector3(
            Float(component.position.col - gridSize / 2) * 0.5,
            0.3,
            Float(component.position.row - gridSize / 2) * 0.5
        )

        let rotation = Float(component.rotation) * .pi / 180
        node.eulerAngles.y = rotation

        // Entry animation
        node.scale = SCNVector3(0.01, 0.01, 0.01)
        node.runAction(SCNAction.scale(to: 1.0, duration: 0.3))

        return node
    }

    private func createBatteryNode() -> SCNNode {
        let body = SCNCylinder(radius: 0.2, height: 0.6)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1)
        mat.metalness.contents = 0.3
        mat.roughness.contents = 0.4
        body.materials = [mat]
        let node = SCNNode(geometry: body)
        node.eulerAngles.z = .pi / 2

        // Positive terminal
        let terminal = SCNCylinder(radius: 0.08, height: 0.1)
        let termMat = SCNMaterial()
        termMat.diffuse.contents = UIColor.lightGray
        termMat.metalness.contents = 0.8
        terminal.materials = [termMat]
        let termNode = SCNNode(geometry: terminal)
        termNode.position = SCNVector3(0.35, 0, 0)
        termNode.eulerAngles.z = .pi / 2
        node.addChildNode(termNode)

        return node
    }

    private func createResistorNode(value: Double) -> SCNNode {
        let body = SCNCapsule(capRadius: 0.06, height: 0.5)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1)
        mat.roughness.contents = 0.7
        body.materials = [mat]
        let node = SCNNode(geometry: body)
        node.eulerAngles.z = .pi / 2

        // Color bands
        let bands = colorBands(for: value)
        for (i, color) in bands.enumerated() {
            let band = SCNCylinder(radius: 0.065, height: 0.03)
            let bandMat = SCNMaterial()
            bandMat.diffuse.contents = color
            band.materials = [bandMat]
            let bandNode = SCNNode(geometry: band)
            bandNode.position = SCNVector3(Float(i - 2) * 0.08, 0, 0)
            bandNode.eulerAngles.z = .pi / 2
            node.addChildNode(bandNode)
        }

        return node
    }

    private func createLEDNode() -> SCNNode {
        let dome = SCNSphere(radius: 0.12)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
        mat.emission.contents = UIColor.red.withAlphaComponent(0.3)
        mat.transparency = 0.3
        dome.materials = [mat]
        let node = SCNNode(geometry: dome)
        node.position = SCNVector3(0, 0.05, 0)

        let base = SCNCylinder(radius: 0.08, height: 0.1)
        let baseMat = SCNMaterial()
        baseMat.diffuse.contents = UIColor.lightGray
        baseMat.metalness.contents = 0.6
        base.materials = [baseMat]
        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, -0.1, 0)
        node.addChildNode(baseNode)

        return node
    }

    private func createCapacitorNode() -> SCNNode {
        let body = SCNCylinder(radius: 0.15, height: 0.3)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1)
        mat.metalness.contents = 0.2
        mat.roughness.contents = 0.5
        body.materials = [mat]
        return SCNNode(geometry: body)
    }

    private func createWireNode() -> SCNNode {
        let wire = SCNCylinder(radius: 0.02, height: 0.8)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.red
        mat.metalness.contents = 0.5
        wire.materials = [mat]
        let node = SCNNode(geometry: wire)
        node.eulerAngles.z = .pi / 2
        return node
    }

    private func createSwitchNode() -> SCNNode {
        let base = SCNBox(width: 0.3, height: 0.1, length: 0.2, chamferRadius: 0.02)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.darkGray
        mat.metalness.contents = 0.6
        base.materials = [mat]
        let node = SCNNode(geometry: base)

        let lever = SCNBox(width: 0.15, height: 0.05, length: 0.05, chamferRadius: 0.01)
        let leverMat = SCNMaterial()
        leverMat.diffuse.contents = UIColor.orange
        lever.materials = [leverMat]
        let leverNode = SCNNode(geometry: lever)
        leverNode.position = SCNVector3(0, 0.08, 0)
        node.addChildNode(leverNode)

        return node
    }

    private func createBuzzerNode() -> SCNNode {
        let body = SCNCylinder(radius: 0.15, height: 0.15)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.black
        mat.metalness.contents = 0.3
        body.materials = [mat]
        let node = SCNNode(geometry: body)

        let top = SCNCylinder(radius: 0.12, height: 0.02)
        let topMat = SCNMaterial()
        topMat.diffuse.contents = UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1)
        top.materials = [topMat]
        let topNode = SCNNode(geometry: top)
        topNode.position = SCNVector3(0, 0.085, 0)
        node.addChildNode(topNode)

        return node
    }

    private func createMotorNode() -> SCNNode {
        let body = SCNCylinder(radius: 0.18, height: 0.25)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.gray
        mat.metalness.contents = 0.7
        mat.roughness.contents = 0.3
        body.materials = [mat]
        let node = SCNNode(geometry: body)

        let shaft = SCNCylinder(radius: 0.03, height: 0.15)
        let shaftMat = SCNMaterial()
        shaftMat.diffuse.contents = UIColor.lightGray
        shaftMat.metalness.contents = 0.9
        shaft.materials = [shaftMat]
        let shaftNode = SCNNode(geometry: shaft)
        shaftNode.position = SCNVector3(0, 0.2, 0)
        node.addChildNode(shaftNode)

        return node
    }

    private func createGenericNode(color: UIColor) -> SCNNode {
        let box = SCNBox(width: 0.2, height: 0.15, length: 0.15, chamferRadius: 0.02)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.metalness.contents = 0.3
        box.materials = [mat]
        return SCNNode(geometry: box)
    }

    private func colorBands(for value: Double) -> [UIColor] {
        // Simplified color band mapping
        let colors: [UIColor] = [.black, .brown, .red, .orange, .yellow, .green, .blue, .purple, .gray, .white]
        let intValue = Int(value)

        if intValue < 10 { return [colors[intValue], .black, .black, .brown] }

        let str = String(intValue)
        let d1 = Int(String(str.first!)) ?? 0
        let d2 = str.count > 1 ? (Int(String(str[str.index(after: str.startIndex)])) ?? 0) : 0
        let multiplier = max(0, min(9, str.count - 2))

        return [colors[d1], colors[d2], colors[multiplier], colors[5]] // gold tolerance placeholder as green
    }
}
