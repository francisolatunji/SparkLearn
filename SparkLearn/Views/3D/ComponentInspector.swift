import SwiftUI
import SceneKit

// MARK: - Component Inspector View
/// Exploded-view 3D inspector for circuit components.
/// Animates internal parts apart with floating labels and leader lines,
/// plus a glassmorphic info panel with specs, safety notes, and common uses.
struct ComponentInspector: View {
    let sceneType: SceneType

    @State private var isExploded = false
    @State private var isCrossSection = false
    @State private var currentZoom: CGFloat = 1.0
    @State private var sceneController = InspectorSceneController()

    var body: some View {
        ZStack {
            // 3D Scene
            InspectorSceneView(
                sceneType: sceneType,
                isExploded: isExploded,
                isCrossSection: isCrossSection,
                controller: sceneController
            )
            .ignoresSafeArea()
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let zoom = Float(value.magnification)
                        sceneController.setCameraZoom(zoom)
                    }
                    .onEnded { value in
                        sceneController.commitZoom()
                    }
            )

            VStack {
                // Top controls
                HStack(spacing: 12) {
                    Spacer()

                    // Cross-section toggle
                    Button {
                        withAnimation(DS.feedbackAnim) {
                            isCrossSection.toggle()
                        }
                        Haptics.light()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isCrossSection ? "cube.transparent" : "square.split.diagonal.2x2")
                                .font(.system(size: 14, weight: .semibold))
                            Text(isCrossSection ? "Solid" : "Cross-Section")
                                .font(DS.captionFont)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.top, 12)

                Spacer()

                // Explode / Reassemble button
                HStack(spacing: 12) {
                    PrimaryButton(
                        isExploded ? "Reassemble" : "Explode View",
                        icon: isExploded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                    ) {
                        withAnimation(DS.transitionAnim) {
                            isExploded.toggle()
                        }
                        Haptics.medium()
                    }
                }
                .padding(.horizontal, DS.padding)
                .padding(.bottom, 8)

                // Info panel
                ComponentInfoDetailPanel(sceneType: sceneType)
                    .padding(.horizontal, DS.padding)
                    .padding(.bottom, DS.padding)
            }
        }
        .background(Color.black)
    }
}

// MARK: - Info Detail Panel

private struct ComponentInfoDetailPanel: View {
    let sceneType: SceneType

    private var info: ComponentSpec {
        ComponentSpec.specs(for: sceneType)
    }

    var body: some View {
        DSGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 10) {
                    Image(systemName: info.icon)
                        .font(.system(size: 22))
                        .foregroundColor(info.accentColor)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(info.accentColor.opacity(0.2))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.name)
                            .font(DS.headlineFont)
                            .foregroundColor(.white)
                        Text(info.category)
                            .font(DS.captionFont)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()
                }

                Divider().background(Color.white.opacity(0.15))

                // Specifications
                VStack(alignment: .leading, spacing: 6) {
                    Text("Specifications")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DS.electricBlue)

                    ForEach(info.specifications, id: \.0) { spec in
                        HStack {
                            Text(spec.0)
                                .font(DS.captionFont)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text(spec.1)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Safety notes
                if !info.safetyNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(DS.warning)
                            Text("Safety")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(DS.warning)
                        }

                        ForEach(info.safetyNotes, id: \.self) { note in
                            Text("  \u{2022} \(note)")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }

                // Common uses
                VStack(alignment: .leading, spacing: 4) {
                    Text("Common Uses")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DS.success)

                    Text(info.commonUses.joined(separator: " \u{2022} "))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Component Spec Data

private struct ComponentSpec {
    let name: String
    let category: String
    let icon: String
    let accentColor: Color
    let specifications: [(String, String)]
    let safetyNotes: [String]
    let commonUses: [String]
    let internalParts: [InternalPart]

    struct InternalPart {
        let name: String
        let offset: SCNVector3       // exploded offset from origin
        let color: UIColor
        let geometry: SCNGeometry
    }

    static func specs(for type: SceneType) -> ComponentSpec {
        switch type {
        case .resistor:
            return ComponentSpec(
                name: "Resistor",
                category: "Passive Component",
                icon: "line.3.horizontal",
                accentColor: DS.deepPurple,
                specifications: [
                    ("Resistance Range", "1\u{2126} - 10M\u{2126}"),
                    ("Power Rating", "0.25W (typical)"),
                    ("Tolerance", "\u{00B1}5% (gold band)"),
                    ("Temperature Coeff.", "\u{00B1}200 ppm/\u{00B0}C")
                ],
                safetyNotes: [
                    "Can get hot under high power dissipation",
                    "Exceeding power rating causes burning",
                    "Check wattage before use in high-current circuits"
                ],
                commonUses: [
                    "Current limiting for LEDs",
                    "Voltage dividers",
                    "Pull-up/pull-down in digital circuits",
                    "RC timing circuits"
                ],
                internalParts: resistorParts()
            )

        case .led:
            return ComponentSpec(
                name: "LED",
                category: "Active Component (Optoelectronic)",
                icon: "lightbulb.fill",
                accentColor: DS.error,
                specifications: [
                    ("Forward Voltage", "1.8V - 3.3V"),
                    ("Forward Current", "20mA (typical)"),
                    ("Wavelength", "620-630nm (red)"),
                    ("Luminous Intensity", "200-800 mcd")
                ],
                safetyNotes: [
                    "Always use a current-limiting resistor",
                    "Observe polarity: longer leg is anode (+)",
                    "Do not look directly into high-power LEDs"
                ],
                commonUses: [
                    "Status indicators",
                    "Backlighting",
                    "Optocouplers",
                    "Seven-segment displays"
                ],
                internalParts: ledParts()
            )

        case .capacitor:
            return ComponentSpec(
                name: "Capacitor",
                category: "Passive Component",
                icon: "rectangle.split.2x1",
                accentColor: DS.primary,
                specifications: [
                    ("Capacitance", "1pF - 10,000\u{00B5}F"),
                    ("Voltage Rating", "6.3V - 450V"),
                    ("Dielectric", "Ceramic / Electrolytic"),
                    ("ESR", "< 0.1\u{2126} (ceramic)")
                ],
                safetyNotes: [
                    "Electrolytic capacitors are polarized",
                    "Can hold charge after power off",
                    "Exceeding voltage rating causes rupture",
                    "High-voltage caps can be lethal"
                ],
                commonUses: [
                    "Power supply filtering",
                    "Decoupling / bypass",
                    "Timing circuits (RC)",
                    "Energy storage"
                ],
                internalParts: capacitorParts()
            )

        case .battery:
            return ComponentSpec(
                name: "Battery",
                category: "Power Source",
                icon: "battery.100",
                accentColor: DS.success,
                specifications: [
                    ("Voltage", "1.5V (AA) / 9V (PP3)"),
                    ("Chemistry", "Alkaline / Li-ion"),
                    ("Capacity", "2000-3000 mAh"),
                    ("Internal Resistance", "0.1-0.3\u{2126}")
                ],
                safetyNotes: [
                    "Do not short-circuit terminals",
                    "Do not mix old and new batteries",
                    "Dispose of properly - do not incinerate",
                    "Li-ion: risk of thermal runaway"
                ],
                commonUses: [
                    "Portable power supply",
                    "Backup power (UPS)",
                    "Remote controls",
                    "IoT devices"
                ],
                internalParts: batteryParts()
            )

        default:
            return ComponentSpec(
                name: sceneTypeName(type),
                category: "Electronic Component",
                icon: "cpu",
                accentColor: DS.accent,
                specifications: [
                    ("Type", sceneTypeName(type)),
                    ("Category", "General")
                ],
                safetyNotes: ["Refer to component datasheet"],
                commonUses: ["Various circuit applications"],
                internalParts: genericParts()
            )
        }
    }

    private static func sceneTypeName(_ type: SceneType) -> String {
        switch type {
        case .atom: return "Atom"
        case .battery: return "Battery"
        case .lightBulb: return "Light Bulb"
        case .circuit: return "Circuit"
        case .resistor: return "Resistor"
        case .led: return "LED"
        case .capacitor: return "Capacitor"
        case .diode: return "Diode"
        case .switchToggle: return "Switch"
        case .lightning: return "Lightning"
        case .seriesCircuit: return "Series Circuit"
        case .parallelCircuit: return "Parallel Circuit"
        case .multimeter: return "Multimeter"
        case .breadboard: return "Breadboard"
        case .arduino: return "Arduino"
        case .fuseBox: return "Fuse Box"
        }
    }

    // MARK: - Resistor Internal Parts

    private static func resistorParts() -> [InternalPart] {
        // Carbon film resistor layers
        let ceramicCore = InternalPart(
            name: "Ceramic Core",
            offset: SCNVector3(0, 0, 0),
            color: UIColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 1),
            geometry: SCNCylinder(radius: 0.12, height: 0.7)
        )
        let carbonFilm = InternalPart(
            name: "Carbon Film",
            offset: SCNVector3(0, 1.2, 0),
            color: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1),
            geometry: SCNCylinder(radius: 0.14, height: 0.65)
        )
        let helicalCut = InternalPart(
            name: "Helical Cut (trim)",
            offset: SCNVector3(0, 2.2, 0),
            color: UIColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1),
            geometry: SCNTorus(ringRadius: 0.13, pipeRadius: 0.015)
        )
        let protectiveCoat = InternalPart(
            name: "Epoxy Coating",
            offset: SCNVector3(0, -1.2, 0),
            color: UIColor(red: 0.82, green: 0.72, blue: 0.55, alpha: 0.7),
            geometry: SCNCapsule(capRadius: 0.17, height: 0.8)
        )
        let leadLeft = InternalPart(
            name: "Lead (Anode)",
            offset: SCNVector3(-1.8, 0, 0),
            color: UIColor.lightGray,
            geometry: SCNCylinder(radius: 0.02, height: 0.5)
        )
        let leadRight = InternalPart(
            name: "Lead (Cathode)",
            offset: SCNVector3(1.8, 0, 0),
            color: UIColor.lightGray,
            geometry: SCNCylinder(radius: 0.02, height: 0.5)
        )
        return [ceramicCore, carbonFilm, helicalCut, protectiveCoat, leadLeft, leadRight]
    }

    // MARK: - LED Internal Parts

    private static func ledParts() -> [InternalPart] {
        let epoxyLens = InternalPart(
            name: "Epoxy Lens",
            offset: SCNVector3(0, 1.5, 0),
            color: UIColor.red.withAlphaComponent(0.3),
            geometry: SCNSphere(radius: 0.25)
        )
        let semiconductorDie = InternalPart(
            name: "Semiconductor Die",
            offset: SCNVector3(0, 0, 0),
            color: UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1),
            geometry: SCNBox(width: 0.08, height: 0.04, length: 0.08, chamferRadius: 0.005)
        )
        let reflectorCup = InternalPart(
            name: "Reflector Cup",
            offset: SCNVector3(0, -0.8, 0),
            color: UIColor.lightGray,
            geometry: SCNCone(topRadius: 0.12, bottomRadius: 0.06, height: 0.1)
        )
        let anvilPost = InternalPart(
            name: "Anvil (Cathode Post)",
            offset: SCNVector3(0.8, -1.2, 0),
            color: UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1),
            geometry: SCNBox(width: 0.04, height: 0.3, length: 0.04, chamferRadius: 0.005)
        )
        let bondWire = InternalPart(
            name: "Bond Wire",
            offset: SCNVector3(-0.8, 0.5, 0),
            color: UIColor(red: 0.85, green: 0.75, blue: 0.0, alpha: 1),
            geometry: SCNCylinder(radius: 0.008, height: 0.15)
        )
        let anodeLead = InternalPart(
            name: "Anode Lead (+)",
            offset: SCNVector3(-1.2, -1.8, 0),
            color: UIColor.lightGray,
            geometry: SCNCylinder(radius: 0.02, height: 0.6)
        )
        let cathodeLead = InternalPart(
            name: "Cathode Lead (-)",
            offset: SCNVector3(1.2, -1.8, 0),
            color: UIColor.lightGray,
            geometry: SCNCylinder(radius: 0.02, height: 0.5)
        )
        return [epoxyLens, semiconductorDie, reflectorCup, anvilPost, bondWire, anodeLead, cathodeLead]
    }

    // MARK: - Capacitor Internal Parts

    private static func capacitorParts() -> [InternalPart] {
        let outerCasing = InternalPart(
            name: "Aluminum Casing",
            offset: SCNVector3(0, -1.5, 0),
            color: UIColor(red: 0.15, green: 0.25, blue: 0.6, alpha: 0.7),
            geometry: SCNCylinder(radius: 0.28, height: 0.6)
        )
        let anodeFoil = InternalPart(
            name: "Anode Foil (+)",
            offset: SCNVector3(-0.8, 0.8, 0),
            color: UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1),
            geometry: SCNBox(width: 0.02, height: 0.5, length: 0.35, chamferRadius: 0.0)
        )
        let dielectricLayer = InternalPart(
            name: "Dielectric (Al2O3)",
            offset: SCNVector3(0, 0.8, 0),
            color: UIColor(red: 0.95, green: 0.9, blue: 0.7, alpha: 0.6),
            geometry: SCNBox(width: 0.015, height: 0.5, length: 0.35, chamferRadius: 0.0)
        )
        let cathodeFoil = InternalPart(
            name: "Cathode Foil (-)",
            offset: SCNVector3(0.8, 0.8, 0),
            color: UIColor(red: 0.55, green: 0.55, blue: 0.6, alpha: 1),
            geometry: SCNBox(width: 0.02, height: 0.5, length: 0.35, chamferRadius: 0.0)
        )
        let electrolyte = InternalPart(
            name: "Electrolyte",
            offset: SCNVector3(0, 1.8, 0),
            color: UIColor(red: 0.6, green: 0.4, blue: 0.1, alpha: 0.5),
            geometry: SCNCylinder(radius: 0.22, height: 0.45)
        )
        let sealingPlug = InternalPart(
            name: "Rubber Seal",
            offset: SCNVector3(0, -2.5, 0),
            color: UIColor.darkGray,
            geometry: SCNCylinder(radius: 0.26, height: 0.06)
        )
        return [outerCasing, anodeFoil, dielectricLayer, cathodeFoil, electrolyte, sealingPlug]
    }

    // MARK: - Battery Internal Parts

    private static func batteryParts() -> [InternalPart] {
        let outerCan = InternalPart(
            name: "Steel Casing",
            offset: SCNVector3(0, -1.8, 0),
            color: UIColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 0.6),
            geometry: SCNCylinder(radius: 0.38, height: 1.3)
        )
        let cathodeRing = InternalPart(
            name: "Cathode (MnO2)",
            offset: SCNVector3(-1.0, 0.5, 0),
            color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1),
            geometry: SCNCylinder(radius: 0.32, height: 1.1)
        )
        let separator = InternalPart(
            name: "Separator",
            offset: SCNVector3(0, 0.5, 0),
            color: UIColor.white.withAlphaComponent(0.7),
            geometry: SCNCylinder(radius: 0.20, height: 1.05)
        )
        let anodeGel = InternalPart(
            name: "Anode (Zinc Gel)",
            offset: SCNVector3(1.0, 0.5, 0),
            color: UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1),
            geometry: SCNCylinder(radius: 0.15, height: 1.0)
        )
        let electrolyte = InternalPart(
            name: "KOH Electrolyte",
            offset: SCNVector3(0, 2.0, 0),
            color: UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 0.4),
            geometry: SCNCylinder(radius: 0.18, height: 0.9)
        )
        let currentCollector = InternalPart(
            name: "Brass Current Collector",
            offset: SCNVector3(0, 3.0, 0),
            color: UIColor(red: 0.85, green: 0.65, blue: 0.15, alpha: 1),
            geometry: SCNCylinder(radius: 0.04, height: 1.1)
        )
        return [outerCan, cathodeRing, separator, anodeGel, electrolyte, currentCollector]
    }

    // MARK: - Generic

    private static func genericParts() -> [InternalPart] {
        let body = InternalPart(
            name: "Body",
            offset: SCNVector3(0, 0, 0),
            color: UIColor.gray,
            geometry: SCNBox(width: 0.4, height: 0.3, length: 0.3, chamferRadius: 0.03)
        )
        let connector = InternalPart(
            name: "Connector",
            offset: SCNVector3(0, 1.0, 0),
            color: UIColor.lightGray,
            geometry: SCNCylinder(radius: 0.03, height: 0.4)
        )
        return [body, connector]
    }
}

// MARK: - Scene Controller

class InspectorSceneController: ObservableObject {
    var cameraNode: SCNNode?
    private var baseDistance: Float = 5.0

    func setCameraZoom(_ magnification: Float) {
        guard let camera = cameraNode else { return }
        let newZ = baseDistance / magnification
        camera.position.z = max(2.0, min(15.0, newZ))
    }

    func commitZoom() {
        guard let camera = cameraNode else { return }
        baseDistance = camera.position.z
    }
}

// MARK: - SceneKit Representable

private struct InspectorSceneView: UIViewRepresentable {
    let sceneType: SceneType
    let isExploded: Bool
    let isCrossSection: Bool
    let controller: InspectorSceneController

    class Coordinator {
        var partNodes: [(node: SCNNode, assembledPos: SCNVector3, explodedPos: SCNVector3)] = []
        var labelNodes: [SCNNode] = []
        var leaderNodes: [SCNNode] = []
        var crossSectionPlane: SCNNode?
        var currentExploded = false
        var currentCrossSection = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.03, green: 0.05, blue: 0.10, alpha: 1)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isTemporalAntialiasingEnabled = true

        let scene = buildScene(context: context)
        scnView.scene = scene

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let coord = context.coordinator

        // Handle explode / reassemble
        if isExploded != coord.currentExploded {
            coord.currentExploded = isExploded
            animateExplode(explode: isExploded, coordinator: coord)
        }

        // Handle cross-section toggle
        if isCrossSection != coord.currentCrossSection {
            coord.currentCrossSection = isCrossSection
            toggleCrossSection(show: isCrossSection, coordinator: coord, scene: uiView.scene)
        }
    }

    // MARK: - Scene Construction

    private func buildScene(context: Context) -> SCNScene {
        let scene = SCNScene()
        let coord = context.coordinator

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
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 1, 5)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)
        controller.cameraNode = cameraNode

        // 3-point lighting
        addThreePointLighting(to: scene)

        // Reflective floor
        let floor = SCNFloor()
        floor.reflectivity = 0.12
        floor.reflectionFalloffEnd = 3.0
        let floorMat = SCNMaterial()
        floorMat.lightingModel = .physicallyBased
        floorMat.diffuse.contents = UIColor(red: 0.06, green: 0.07, blue: 0.1, alpha: 1)
        floorMat.roughness.contents = CGFloat(0.9)
        floor.materials = [floorMat]
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, -2.0, 0)
        scene.rootNode.addChildNode(floorNode)

        // Build the component parts
        let spec = ComponentSpec.specs(for: sceneType)
        let rootComponent = SCNNode()
        rootComponent.name = "componentRoot"
        scene.rootNode.addChildNode(rootComponent)

        for part in spec.internalParts {
            let partNode = SCNNode(geometry: part.geometry)
            let mat = SCNMaterial()
            mat.lightingModel = .physicallyBased
            mat.diffuse.contents = part.color
            mat.metalness.contents = CGFloat(0.3)
            mat.roughness.contents = CGFloat(0.5)

            // Transparent parts keep their alpha
            let alpha = part.color.cgColor.alpha
            if alpha < 1.0 {
                mat.transparency = alpha
                mat.isDoubleSided = true
            }

            part.geometry.materials = [mat]

            // In assembled position, all parts sit at origin
            partNode.position = SCNVector3Zero
            partNode.name = part.name

            rootComponent.addChildNode(partNode)

            // Create floating label node (hidden initially)
            let labelNode = createLabelNode(text: part.name)
            labelNode.position = part.offset
            labelNode.isHidden = true
            scene.rootNode.addChildNode(labelNode)
            coord.labelNodes.append(labelNode)

            // Create leader line node (hidden initially)
            let leaderNode = createLeaderLine(from: part.offset, to: SCNVector3Zero)
            leaderNode.isHidden = true
            scene.rootNode.addChildNode(leaderNode)
            coord.leaderNodes.append(leaderNode)

            coord.partNodes.append((
                node: partNode,
                assembledPos: SCNVector3Zero,
                explodedPos: part.offset
            ))
        }

        // Slow auto-rotation
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 20))
        rootComponent.runAction(spin, forKey: "autoSpin")

        return scene
    }

    // MARK: - 3-Point Lighting

    private func addThreePointLighting(to scene: SCNScene) {
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.color = UIColor(red: 1.0, green: 0.96, blue: 0.9, alpha: 1)
        keyLight.light?.castsShadow = true
        keyLight.light?.shadowRadius = 3
        keyLight.position = SCNVector3(3, 5, 4)
        keyLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(keyLight)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.intensity = 300
        fillLight.light?.color = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1)
        fillLight.position = SCNVector3(-3, 2, 4)
        fillLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fillLight)

        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .directional
        rimLight.light?.intensity = 200
        rimLight.position = SCNVector3(0, 3, -3)
        rimLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(rimLight)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 150
        ambientLight.light?.color = UIColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)
    }

    // MARK: - Explode / Reassemble Animation

    private func animateExplode(explode: Bool, coordinator: Coordinator) {
        for (i, entry) in coordinator.partNodes.enumerated() {
            let targetPos = explode ? entry.explodedPos : entry.assembledPos
            let moveAction = SCNAction.move(to: targetPos, duration: 0.6)
            moveAction.timingMode = .easeInEaseOut
            entry.node.runAction(moveAction)
        }

        // Show/hide labels and leader lines
        for labelNode in coordinator.labelNodes {
            if explode {
                labelNode.isHidden = false
                labelNode.opacity = 0
                labelNode.runAction(SCNAction.fadeIn(duration: 0.4))
            } else {
                labelNode.runAction(SCNAction.sequence([
                    SCNAction.fadeOut(duration: 0.3),
                    SCNAction.hide()
                ]))
            }
        }

        for leaderNode in coordinator.leaderNodes {
            if explode {
                leaderNode.isHidden = false
                leaderNode.opacity = 0
                leaderNode.runAction(SCNAction.fadeIn(duration: 0.4))
            } else {
                leaderNode.runAction(SCNAction.sequence([
                    SCNAction.fadeOut(duration: 0.3),
                    SCNAction.hide()
                ]))
            }
        }
    }

    // MARK: - Cross-Section

    private func toggleCrossSection(show: Bool, coordinator: Coordinator, scene: SCNScene?) {
        guard let scene = scene else { return }

        if show {
            // Create a clipping plane effect by making half the component transparent
            for entry in coordinator.partNodes {
                let mat = entry.node.geometry?.firstMaterial
                mat?.isDoubleSided = true

                // Use morpher or just hide the front half via a custom shader modifier
                let shaderModifier = """
                #pragma transparent
                #pragma body
                if (_surface.position.x > 0.0) {
                    discard_fragment();
                }
                """
                mat?.shaderModifiers = [.fragment: shaderModifier]
            }

            // Add a cutting plane visualization
            if coordinator.crossSectionPlane == nil {
                let plane = SCNPlane(width: 3, height: 3)
                let planeMat = SCNMaterial()
                planeMat.lightingModel = .physicallyBased
                planeMat.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.08)
                planeMat.isDoubleSided = true
                planeMat.transparency = 0.08
                plane.materials = [planeMat]
                let planeNode = SCNNode(geometry: plane)
                planeNode.name = "crossSectionPlane"
                planeNode.eulerAngles.y = .pi / 2
                scene.rootNode.addChildNode(planeNode)
                coordinator.crossSectionPlane = planeNode
            }
            coordinator.crossSectionPlane?.isHidden = false
        } else {
            // Remove the shader modifier to restore full rendering
            for entry in coordinator.partNodes {
                entry.node.geometry?.firstMaterial?.shaderModifiers = nil
            }
            coordinator.crossSectionPlane?.isHidden = true
        }
    }

    // MARK: - Label Nodes

    private func createLabelNode(text: String) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.02)
        textGeometry.font = UIFont.systemFont(ofSize: 0.18, weight: .semibold)
        textGeometry.flatness = 0.1
        textGeometry.chamferRadius = 0.005

        let textMat = SCNMaterial()
        textMat.lightingModel = .physicallyBased
        textMat.diffuse.contents = UIColor.white
        textMat.emission.contents = UIColor(red: 0.0, green: 0.83, blue: 1.0, alpha: 1)
        textMat.emission.intensity = 0.6
        textGeometry.materials = [textMat]

        let textNode = SCNNode(geometry: textGeometry)

        // Center the text
        let (min, max) = textNode.boundingBox
        let dx = (max.x - min.x) / 2
        let dy = (max.y - min.y) / 2
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)

        // Billboard constraint so text always faces camera
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        textNode.constraints = [billboard]

        return textNode
    }

    private func createLeaderLine(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)

        guard length > 0.01 else {
            return SCNNode()
        }

        let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(length))
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(red: 0.0, green: 0.83, blue: 1.0, alpha: 0.5)
        mat.emission.contents = UIColor(red: 0.0, green: 0.83, blue: 1.0, alpha: 1)
        mat.emission.intensity = 0.4
        cylinder.materials = [mat]

        let lineNode = SCNNode(geometry: cylinder)
        lineNode.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )

        // Orient to connect start and end
        let direction = SCNVector3(dx, dy, dz)
        let up = SCNVector3(0, 1, 0)

        // Calculate rotation from up to direction
        let cross = SCNVector3(
            up.y * direction.z - up.z * direction.y,
            up.z * direction.x - up.x * direction.z,
            up.x * direction.y - up.y * direction.x
        )
        let crossLen = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
        let dot = up.x * direction.x + up.y * direction.y + up.z * direction.z

        if crossLen > 0.0001 {
            let angle = atan2(crossLen, dot)
            lineNode.rotation = SCNVector4(
                cross.x / crossLen,
                cross.y / crossLen,
                cross.z / crossLen,
                angle
            )
        }

        return lineNode
    }
}

// MARK: - Preview

#Preview("Resistor") {
    ComponentInspector(sceneType: .resistor)
}

#Preview("LED") {
    ComponentInspector(sceneType: .led)
}

#Preview("Capacitor") {
    ComponentInspector(sceneType: .capacitor)
}

#Preview("Battery") {
    ComponentInspector(sceneType: .battery)
}
