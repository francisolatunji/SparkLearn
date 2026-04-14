import SwiftUI
import SceneKit

struct Scene3DView: UIViewRepresentable {
    let sceneType: SceneType

    // MARK: - Coordinator (caches sceneType to prevent unnecessary rebuilds)
    class Coordinator {
        var cachedSceneType: SceneType?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = buildScene(for: sceneType)
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        if let metalLayer = scnView.layer as? CAMetalLayer {
            _ = metalLayer
        }
        scnView.isTemporalAntialiasingEnabled = true
        scnView.backgroundColor = .clear
        context.coordinator.cachedSceneType = sceneType
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard context.coordinator.cachedSceneType != sceneType else { return }
        context.coordinator.cachedSceneType = sceneType
        uiView.scene = buildScene(for: sceneType)
    }

    // MARK: - Scene Builder
    private func buildScene(for type: SceneType) -> SCNScene {
        let scene = SCNScene()

        // Radial gradient background
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let bgImage = renderer.image { ctx in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(red: 0.051, green: 0.067, blue: 0.090, alpha: 1).cgColor,
                UIColor(red: 0.102, green: 0.114, blue: 0.180, alpha: 1).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1]) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: size.width / 2,
                    options: .drawsAfterEndLocation
                )
            }
        }
        scene.background.contents = bgImage

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)

        // 3-point lighting
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.light?.color = UIColor(red: 1.0, green: 0.96, blue: 0.9, alpha: 1)
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
        scene.rootNode.addChildNode(ambientLight)

        // Reflective floor for standalone component models only
        let standaloneTypes: [SceneType] = [.atom, .battery, .lightBulb, .resistor, .led, .capacitor, .diode, .multimeter, .breadboard, .arduino, .fuseBox]
        if standaloneTypes.contains(type) {
            let floor = SCNFloor()
            floor.reflectivity = 0.15
            floor.reflectionFalloffEnd = 3.0
            floor.firstMaterial?.diffuse.contents = UIColor(red: 0.06, green: 0.07, blue: 0.1, alpha: 1)
            let floorNode = SCNNode(geometry: floor)
            floorNode.position = SCNVector3(0, -2.0, 0)
            scene.rootNode.addChildNode(floorNode)
        }

        switch type {
        case .atom:            addAtom(to: scene)
        case .battery:         addBattery(to: scene)
        case .lightBulb:       addLightBulb(to: scene)
        case .circuit:         addCircuit(to: scene)
        case .resistor:        addResistor(to: scene)
        case .led:             addLED(to: scene)
        case .capacitor:       addCapacitor(to: scene)
        case .diode:           addDiode(to: scene)
        case .switchToggle:    addSwitch(to: scene)
        case .lightning:       addLightning(to: scene)
        case .seriesCircuit:   addSeriesCircuit(to: scene)
        case .parallelCircuit: addParallelCircuit(to: scene)
        case .multimeter:      addMultimeter(to: scene)
        case .breadboard:      addBreadboard(to: scene)
        case .arduino:         addArduino(to: scene)
        case .fuseBox:         addFuseBox(to: scene)
        }

        return scene
    }

    // MARK: - PBR Material Factory
    private func makePBRMaterial(
        diffuse: Any?,
        metalness: CGFloat = 0.0,
        roughness: CGFloat = 0.5,
        emission: Any? = nil,
        emissionIntensity: CGFloat = 0.0,
        transparency: CGFloat = 1.0
    ) -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = diffuse
        mat.metalness.contents = metalness
        mat.roughness.contents = roughness
        if let em = emission {
            mat.emission.contents = em
            mat.emission.intensity = emissionIntensity
        }
        mat.transparency = transparency
        return mat
    }

    // MARK: - Shared Helpers
    private func addSpin(to node: SCNNode, duration: CFTimeInterval = 8) {
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.toValue = NSValue(scnVector4: SCNVector4(0.15, 1, 0.1, Float.pi * 2))
        spin.duration = duration
        spin.repeatCount = .infinity
        node.addAnimation(spin, forKey: "spin")
    }

    private func glowPulse(on node: SCNNode, key: String = "glow") {
        let emissionAnim = CABasicAnimation(keyPath: "geometry.firstMaterial.emission.intensity")
        emissionAnim.fromValue = 0.2
        emissionAnim.toValue = 2.0
        emissionAnim.duration = 1.5
        emissionAnim.autoreverses = true
        emissionAnim.repeatCount = .infinity
        emissionAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        node.addAnimation(emissionAnim, forKey: key)

        let scaleAnim = CABasicAnimation(keyPath: "scale")
        scaleAnim.fromValue = NSValue(scnVector3: SCNVector3(1.0, 1.0, 1.0))
        scaleAnim.toValue = NSValue(scnVector3: SCNVector3(1.04, 1.04, 1.04))
        scaleAnim.duration = 1.5
        scaleAnim.autoreverses = true
        scaleAnim.repeatCount = .infinity
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        node.addAnimation(scaleAnim, forKey: "\(key)_scale")
    }

    // MARK: - Atom
    private func addAtom(to scene: SCNScene) {
        let root = SCNNode()

        // Clustered nucleus: 5 small spheres alternating red (proton) and blue (neutron)
        let nucleusOffsets: [(Float, Float, Float, UIColor)] = [
            (0, 0, 0, .systemRed),
            (0.1, 0.08, 0.05, .systemBlue),
            (-0.08, 0.1, -0.06, .systemRed),
            (0.05, -0.1, 0.08, .systemBlue),
            (-0.06, -0.05, -0.1, .systemRed)
        ]
        let nucleusRadii: [CGFloat] = [0.15, 0.13, 0.14, 0.12, 0.13]
        for (i, offset) in nucleusOffsets.enumerated() {
            let sphere = SCNSphere(radius: nucleusRadii[i])
            sphere.firstMaterial = makePBRMaterial(diffuse: offset.3, metalness: 0.3, roughness: 0.4)
            let nNode = SCNNode(geometry: sphere)
            nNode.position = SCNVector3(offset.0, offset.1, offset.2)
            root.addChildNode(nNode)
        }

        // Orbit rings and electrons
        let orbitColors: [UIColor] = [.systemCyan, .systemBlue, .systemTeal]
        let radii: [CGFloat] = [0.9, 1.3, 1.7]
        let speeds: [CFTimeInterval] = [2.5, 3.8, 5.2]

        for i in 0..<3 {
            // Visible orbit ring torus
            let ring = SCNTorus(ringRadius: radii[i], pipeRadius: 0.008)
            ring.firstMaterial = makePBRMaterial(diffuse: orbitColors[i].withAlphaComponent(0.3), metalness: 0.1, roughness: 0.2, emission: orbitColors[i], emissionIntensity: 0.8, transparency: 0.5)
            let ringNode = SCNNode(geometry: ring)
            ringNode.eulerAngles = SCNVector3(Float.pi / 2 + Float(i) * 0.5, Float(i) * 0.8, 0)
            root.addChildNode(ringNode)

            // Electron
            let electron = SCNSphere(radius: 0.12)
            electron.firstMaterial = makePBRMaterial(diffuse: orbitColors[i], metalness: 0.5, roughness: 0.2, emission: orbitColors[i], emissionIntensity: 1.5)
            let eNode = SCNNode(geometry: electron)
            eNode.position = SCNVector3(Float(radii[i]), 0, 0)

            let orbit = SCNNode()
            orbit.eulerAngles = SCNVector3(Float.pi / 2 + Float(i) * 0.5, Float(i) * 0.8, 0)
            orbit.addChildNode(eNode)
            root.addChildNode(orbit)

            let rot = CABasicAnimation(keyPath: "rotation")
            rot.toValue = NSValue(scnVector4: SCNVector4(0, 0, 1, Float.pi * 2))
            rot.duration = speeds[i]
            rot.repeatCount = .infinity
            orbit.addAnimation(rot, forKey: "orbit\(i)")
        }

        addSpin(to: root, duration: 10)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Battery
    private func addBattery(to scene: SCNScene) {
        let root = SCNNode()

        // Body
        let body = SCNCylinder(radius: 0.45, height: 1.8)
        body.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.6, roughness: 0.3)
        root.addChildNode(SCNNode(geometry: body))

        // Label band
        let band = SCNCylinder(radius: 0.47, height: 0.5)
        band.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.4, roughness: 0.35)
        let bandN = SCNNode(geometry: band)
        bandN.position = SCNVector3(0, 0.2, 0)
        root.addChildNode(bandN)

        // Bevel ring at cap junction
        let bevel = SCNCylinder(radius: 0.46, height: 0.02)
        bevel.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let bevelN = SCNNode(geometry: bevel)
        bevelN.position = SCNVector3(0, 0.9, 0)
        root.addChildNode(bevelN)

        // Cap (positive terminal)
        let cap = SCNCylinder(radius: 0.18, height: 0.15)
        cap.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let capN = SCNNode(geometry: cap)
        capN.position = SCNVector3(0, 0.98, 0)
        root.addChildNode(capN)

        // Plus sign at top
        let plusH = SCNBox(width: 0.2, height: 0.04, length: 0.04, chamferRadius: 0)
        plusH.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let pH = SCNNode(geometry: plusH)
        pH.position = SCNVector3(0, 1.1, 0.2)
        root.addChildNode(pH)
        let plusV = SCNBox(width: 0.04, height: 0.2, length: 0.04, chamferRadius: 0)
        plusV.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let pV = SCNNode(geometry: plusV)
        pV.position = SCNVector3(0, 1.1, 0.2)
        root.addChildNode(pV)

        // Minus sign at bottom
        let minusH = SCNBox(width: 0.2, height: 0.04, length: 0.04, chamferRadius: 0)
        minusH.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let mH = SCNNode(geometry: minusH)
        mH.position = SCNVector3(0, -0.95, 0.2)
        root.addChildNode(mH)

        // Inner energy pulse omni light
        let energyLight = SCNNode()
        energyLight.light = SCNLight()
        energyLight.light?.type = .omni
        energyLight.light?.color = UIColor.systemGreen
        energyLight.light?.intensity = 50
        energyLight.position = SCNVector3(0, 0, 0)
        root.addChildNode(energyLight)

        let pulse = CABasicAnimation(keyPath: "light.intensity")
        pulse.fromValue = 50
        pulse.toValue = 200
        pulse.duration = 1.5
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        energyLight.addAnimation(pulse, forKey: "energyPulse")

        addSpin(to: root)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Light Bulb
    private func addLightBulb(to scene: SCNScene) {
        let root = SCNNode()

        // Glass bulb (outer)
        let glass = SCNSphere(radius: 0.7)
        glass.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.0, roughness: 0.05, transparency: 0.25)
        let glassNode = SCNNode(geometry: glass)
        glassNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(glassNode)

        // Inner glow sphere
        let innerGlow = SCNSphere(radius: 0.68)
        innerGlow.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 1.0, green: 1.0, blue: 0.7, alpha: 0.08), metalness: 0.0, roughness: 0.1, emission: UIColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1), emissionIntensity: 0.15)
        let innerGlowNode = SCNNode(geometry: innerGlow)
        innerGlowNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(innerGlowNode)

        // Filament: 3 stacked tori connected by thin vertical cylinders
        let filamentYPositions: [Float] = [0.33, 0.40, 0.47]
        for y in filamentYPositions {
            let torus = SCNTorus(ringRadius: 0.06, pipeRadius: 0.015)
            torus.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.7, roughness: 0.3, emission: UIColor.systemYellow, emissionIntensity: 1.5)
            let tNode = SCNNode(geometry: torus)
            tNode.position = SCNVector3(0, y, 0)
            tNode.eulerAngles.x = .pi / 2
            root.addChildNode(tNode)
            glowPulse(on: tNode)
        }

        // Connecting cylinders between filament tori
        for i in 0..<(filamentYPositions.count - 1) {
            let midY = (filamentYPositions[i] + filamentYPositions[i + 1]) / 2
            let h = filamentYPositions[i + 1] - filamentYPositions[i]
            let connector = SCNCylinder(radius: 0.008, height: CGFloat(h))
            connector.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.7, roughness: 0.3, emission: UIColor.systemYellow, emissionIntensity: 1.0)
            let cNode = SCNNode(geometry: connector)
            cNode.position = SCNVector3(0, midY, 0)
            root.addChildNode(cNode)
        }

        // Filament support wires from base up to bottom torus
        let supportWire = SCNCylinder(radius: 0.008, height: 0.43)
        supportWire.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.6, roughness: 0.3)
        let sw = SCNNode(geometry: supportWire)
        sw.position = SCNVector3(0, 0.12, 0)
        root.addChildNode(sw)

        // Edison base: 4 stacked cylinders with alternating radii for thread look
        let baseRadii: [CGFloat] = [0.34, 0.36, 0.34, 0.36]
        let baseHeight: CGFloat = 0.12
        for (i, r) in baseRadii.enumerated() {
            let seg = SCNCylinder(radius: r, height: baseHeight)
            seg.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.72, green: 0.58, blue: 0.2, alpha: 1), metalness: 0.7, roughness: 0.25)
            let sNode = SCNNode(geometry: seg)
            sNode.position = SCNVector3(0, -0.33 - Float(i) * Float(baseHeight), 0)
            root.addChildNode(sNode)
        }

        // Base contact (small dark cylinder at very bottom)
        let contact = SCNCylinder(radius: 0.15, height: 0.06)
        contact.firstMaterial = makePBRMaterial(diffuse: UIColor.darkGray, metalness: 0.5, roughness: 0.5)
        let contactNode = SCNNode(geometry: contact)
        contactNode.position = SCNVector3(0, -0.85, 0)
        root.addChildNode(contactNode)

        // Warm omni light inside
        let bulbLight = SCNNode()
        bulbLight.light = SCNLight()
        bulbLight.light?.type = .omni
        bulbLight.light?.color = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1)
        bulbLight.light?.intensity = 300
        bulbLight.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(bulbLight)

        let lightPulse = CABasicAnimation(keyPath: "light.intensity")
        lightPulse.fromValue = 300
        lightPulse.toValue = 800
        lightPulse.duration = 1.5
        lightPulse.autoreverses = true
        lightPulse.repeatCount = .infinity
        lightPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        bulbLight.addAnimation(lightPulse, forKey: "bulbPulse")

        addSpin(to: root)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Circuit
    private func addCircuit(to scene: SCNScene) {
        let root = SCNNode()
        let corners: [(Float, Float)] = [(-1.3, -0.8), (1.3, -0.8), (1.3, 0.8), (-1.3, 0.8)]
        let copperColor = UIColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 1)

        // Wires
        for i in 0..<4 {
            let next = (i + 1) % 4
            let s = corners[i], e = corners[next]
            let len = sqrt(pow(e.0 - s.0, 2) + pow(e.1 - s.1, 2))
            let wire = SCNCylinder(radius: 0.05, height: CGFloat(len))
            wire.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
            let wN = SCNNode(geometry: wire)
            wN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, 0)
            if s.0 != e.0 { wN.eulerAngles.z = .pi / 2 }
            root.addChildNode(wN)
        }

        // Solder joint spheres at each corner
        for c in corners {
            let joint = SCNSphere(radius: 0.06)
            joint.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.3)
            let jN = SCNNode(geometry: joint)
            jN.position = SCNVector3(c.0, c.1, 0)
            root.addChildNode(jN)
        }

        // Battery: miniature green cylinder with cap
        let batt = SCNCylinder(radius: 0.18, height: 0.5)
        batt.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.6, roughness: 0.3)
        let battN = SCNNode(geometry: batt)
        battN.position = SCNVector3(-1.3, 0, 0)
        root.addChildNode(battN)

        let battCap = SCNCylinder(radius: 0.08, height: 0.06)
        battCap.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let battCapN = SCNNode(geometry: battCap)
        battCapN.position = SCNVector3(-1.3, 0.28, 0)
        root.addChildNode(battCapN)

        // Bulb: miniature glowing sphere
        let bulb = SCNSphere(radius: 0.25)
        bulb.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.1, roughness: 0.2, emission: UIColor.systemYellow, emissionIntensity: 1.5)
        let bulbN = SCNNode(geometry: bulb)
        bulbN.position = SCNVector3(1.3, 0, 0)
        root.addChildNode(bulbN)
        glowPulse(on: bulbN)

        // Current flow animation: 6 small blue spheres traveling along rectangular wire path
        let pathPoints: [SCNVector3] = [
            SCNVector3(-1.3, -0.8, 0),
            SCNVector3(1.3, -0.8, 0),
            SCNVector3(1.3, 0.8, 0),
            SCNVector3(-1.3, 0.8, 0),
            SCNVector3(-1.3, -0.8, 0)
        ]

        for i in 0..<6 {
            let dot = SCNSphere(radius: 0.04)
            dot.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBlue, metalness: 0.2, roughness: 0.3, emission: UIColor.systemBlue, emissionIntensity: 1.5)
            let dotNode = SCNNode(geometry: dot)
            root.addChildNode(dotNode)

            let posAnim = CAKeyframeAnimation(keyPath: "position")
            posAnim.values = pathPoints.map { NSValue(scnVector3: $0) }

            // Compute cumulative distances for keyTimes
            var totalLen: Float = 0
            var segLens: [Float] = [0]
            for j in 0..<(pathPoints.count - 1) {
                let dx = pathPoints[j + 1].x - pathPoints[j].x
                let dy = pathPoints[j + 1].y - pathPoints[j].y
                let dz = pathPoints[j + 1].z - pathPoints[j].z
                totalLen += sqrt(dx * dx + dy * dy + dz * dz)
                segLens.append(totalLen)
            }
            posAnim.keyTimes = segLens.map { NSNumber(value: $0 / totalLen) }
            posAnim.duration = 4.0
            posAnim.repeatCount = .infinity
            posAnim.timeOffset = Double(i) * (4.0 / 6.0)
            posAnim.calculationMode = .linear
            dotNode.addAnimation(posAnim, forKey: "currentFlow\(i)")
        }

        addSpin(to: root, duration: 12)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Resistor
    private func addResistor(to scene: SCNScene) {
        let root = SCNNode()

        // Body: capsule for rounded ends
        let body = SCNCapsule(capRadius: 0.3, height: 1.0)
        body.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1), metalness: 0.1, roughness: 0.6)
        let bodyN = SCNNode(geometry: body)
        bodyN.eulerAngles.z = .pi / 2
        root.addChildNode(bodyN)

        // Color bands with PBR paint sheen
        let bandColors: [UIColor] = [.systemRed, .systemPurple, .systemOrange, .systemYellow]
        let bandPos: [Float] = [-0.3, -0.1, 0.1, 0.3]
        for (i, c) in bandColors.enumerated() {
            let band = SCNCylinder(radius: 0.31, height: 0.06)
            band.firstMaterial = makePBRMaterial(diffuse: c, metalness: 0.3, roughness: 0.4)
            let bN = SCNNode(geometry: band)
            bN.position = SCNVector3(bandPos[i], 0, 0)
            bN.eulerAngles.z = .pi / 2
            root.addChildNode(bN)
        }

        // Gold tolerance band at one end
        let goldBand = SCNCylinder(radius: 0.31, height: 0.04)
        goldBand.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.83, green: 0.68, blue: 0.21, alpha: 1), metalness: 0.6, roughness: 0.25)
        let gbN = SCNNode(geometry: goldBand)
        gbN.position = SCNVector3(0.45, 0, 0)
        gbN.eulerAngles.z = .pi / 2
        root.addChildNode(gbN)

        // Wire leads: silver PBR
        for x: Float in [-1.0, 1.0] {
            let wire = SCNCylinder(radius: 0.03, height: 0.5)
            wire.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
            let wN = SCNNode(geometry: wire)
            wN.position = SCNVector3(x, 0, 0)
            wN.eulerAngles.z = .pi / 2
            root.addChildNode(wN)
        }

        addSpin(to: root, duration: 6)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - LED
    private func addLED(to scene: SCNScene) {
        let root = SCNNode()

        // Dome: translucent red PBR
        let dome = SCNSphere(radius: 0.4)
        dome.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.1, roughness: 0.15, emission: UIColor.systemRed, emissionIntensity: 1.0, transparency: 0.5)
        let dN = SCNNode(geometry: dome)
        dN.position = SCNVector3(0, 0.2, 0)
        root.addChildNode(dN)

        // Internal die: tiny bright sphere
        let die = SCNSphere(radius: 0.08)
        die.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.1, emission: UIColor.systemRed, emissionIntensity: 3.0)
        let dieNode = SCNNode(geometry: die)
        dieNode.position = SCNVector3(0, 0.15, 0)
        root.addChildNode(dieNode)

        // Omni light parented to dome that color-cycles
        let ledLight = SCNNode()
        ledLight.light = SCNLight()
        ledLight.light?.type = .omni
        ledLight.light?.color = UIColor.systemRed
        ledLight.light?.intensity = 200
        ledLight.position = SCNVector3(0, 0.2, 0)
        root.addChildNode(ledLight)

        let lightColorAnim = CAKeyframeAnimation(keyPath: "light.color")
        lightColorAnim.values = [
            UIColor.systemRed,
            UIColor.systemOrange,
            UIColor.systemYellow,
            UIColor.systemGreen,
            UIColor.systemCyan,
            UIColor.systemBlue,
            UIColor.systemPurple,
            UIColor.systemPink,
            UIColor.systemRed
        ]
        lightColorAnim.duration = 8
        lightColorAnim.repeatCount = .infinity
        ledLight.addAnimation(lightColorAnim, forKey: "lightColor")

        // Smooth 8s color cycle with more intermediate colors
        let colorAnim = CAKeyframeAnimation(keyPath: "geometry.firstMaterial.emission.contents")
        colorAnim.values = [
            UIColor.systemRed,
            UIColor.systemOrange,
            UIColor.systemYellow,
            UIColor.systemGreen,
            UIColor.systemCyan,
            UIColor.systemBlue,
            UIColor.systemPurple,
            UIColor.systemPink,
            UIColor.systemRed
        ]
        colorAnim.duration = 8
        colorAnim.repeatCount = .infinity
        dN.addAnimation(colorAnim, forKey: "color")

        // Die also cycles
        let dieColorAnim = CAKeyframeAnimation(keyPath: "geometry.firstMaterial.emission.contents")
        dieColorAnim.values = colorAnim.values
        dieColorAnim.duration = 8
        dieColorAnim.repeatCount = .infinity
        dieNode.addAnimation(dieColorAnim, forKey: "dieColor")

        // Base
        let base = SCNCylinder(radius: 0.25, height: 0.2)
        base.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray, metalness: 0.5, roughness: 0.3)
        root.addChildNode(SCNNode(geometry: base))

        // Legs: one shorter (cathode marker)
        let legA = SCNCylinder(radius: 0.025, height: 0.8) // anode (longer)
        legA.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.2)
        let lA = SCNNode(geometry: legA)
        lA.position = SCNVector3(0.12, -0.5, 0)
        root.addChildNode(lA)

        let legC = SCNCylinder(radius: 0.025, height: 0.6) // cathode (shorter)
        legC.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.2)
        let lC = SCNNode(geometry: legC)
        lC.position = SCNVector3(-0.12, -0.4, 0)
        root.addChildNode(lC)

        addSpin(to: root, duration: 6)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Capacitor
    private func addCapacitor(to scene: SCNScene) {
        let root = SCNNode()

        // Body: dark blue metallic PBR
        let body = SCNCylinder(radius: 0.35, height: 0.8)
        body.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.1, green: 0.15, blue: 0.4, alpha: 1), metalness: 0.5, roughness: 0.3)
        root.addChildNode(SCNNode(geometry: body))

        // Negative stripe: white/light gray, taller
        let stripe = SCNCylinder(radius: 0.36, height: 0.18)
        stripe.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1), metalness: 0.2, roughness: 0.5)
        let sN = SCNNode(geometry: stripe)
        sN.position = SCNVector3(0, -0.25, 0)
        root.addChildNode(sN)

        // Vent: cross pattern (two perpendicular boxes)
        let vent1 = SCNBox(width: 0.4, height: 0.02, length: 0.04, chamferRadius: 0)
        vent1.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray2, metalness: 0.3, roughness: 0.5)
        let v1N = SCNNode(geometry: vent1)
        v1N.position = SCNVector3(0, 0.41, 0)
        root.addChildNode(v1N)

        let vent2 = SCNBox(width: 0.04, height: 0.02, length: 0.4, chamferRadius: 0)
        vent2.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray2, metalness: 0.3, roughness: 0.5)
        let v2N = SCNNode(geometry: vent2)
        v2N.position = SCNVector3(0, 0.41, 0)
        root.addChildNode(v2N)

        // Legs with polarity: one longer than other
        let legLong = SCNCylinder(radius: 0.025, height: 0.6) // positive
        legLong.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.2)
        let llN = SCNNode(geometry: legLong)
        llN.position = SCNVector3(0.12, -0.7, 0)
        root.addChildNode(llN)

        let legShort = SCNCylinder(radius: 0.025, height: 0.4) // negative
        legShort.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.2)
        let lsN = SCNNode(geometry: legShort)
        lsN.position = SCNVector3(-0.12, -0.6, 0)
        root.addChildNode(lsN)

        addSpin(to: root, duration: 7)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Diode
    private func addDiode(to scene: SCNScene) {
        let root = SCNNode()

        // Body: dark gray PBR with slight metalness for epoxy look
        let body = SCNCylinder(radius: 0.25, height: 0.6)
        body.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1), metalness: 0.15, roughness: 0.4)
        let bodyN = SCNNode(geometry: body)
        bodyN.eulerAngles.z = .pi / 2
        root.addChildNode(bodyN)

        // Cone at anode end
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.12, height: 0.15)
        cone.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.2, roughness: 0.4, emission: UIColor.systemGreen, emissionIntensity: 0.5)
        let coneN = SCNNode(geometry: cone)
        coneN.position = SCNVector3(-0.35, 0, 0)
        coneN.eulerAngles.z = -.pi / 2
        root.addChildNode(coneN)

        // Cathode band: silver ring, slightly raised
        let band = SCNCylinder(radius: 0.26, height: 0.06)
        band.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let bN = SCNNode(geometry: band)
        bN.position = SCNVector3(0.2, 0, 0)
        bN.eulerAngles.z = .pi / 2
        root.addChildNode(bN)

        // Arrow: 3 small sequential triangles with staggered fade for flow direction
        for j in 0..<3 {
            let arrow = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.12)
            arrow.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.2, roughness: 0.4, emission: UIColor.systemGreen, emissionIntensity: 1.0)
            let aN = SCNNode(geometry: arrow)
            aN.position = SCNVector3(-0.15 + Float(j) * 0.2, 0.45, 0)
            root.addChildNode(aN)

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1.0
            fade.toValue = 0.2
            fade.duration = 1.0
            fade.autoreverses = true
            fade.repeatCount = .infinity
            fade.timeOffset = Double(j) * 0.33
            aN.addAnimation(fade, forKey: "fade\(j)")
        }

        // Green forward-bias glow
        let glowLight = SCNNode()
        glowLight.light = SCNLight()
        glowLight.light?.type = .omni
        glowLight.light?.color = UIColor.systemGreen
        glowLight.light?.intensity = 100
        glowLight.position = SCNVector3(0, 0, 0.3)
        root.addChildNode(glowLight)

        let glowAnim = CABasicAnimation(keyPath: "light.intensity")
        glowAnim.fromValue = 50
        glowAnim.toValue = 200
        glowAnim.duration = 1.5
        glowAnim.autoreverses = true
        glowAnim.repeatCount = .infinity
        glowLight.addAnimation(glowAnim, forKey: "forwardGlow")

        // Wires
        for x: Float in [-0.7, 0.7] {
            let wire = SCNCylinder(radius: 0.025, height: 0.4)
            wire.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.7, roughness: 0.2)
            let wN = SCNNode(geometry: wire)
            wN.position = SCNVector3(x, 0, 0)
            wN.eulerAngles.z = .pi / 2
            root.addChildNode(wN)
        }

        addSpin(to: root, duration: 6)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Switch
    private func addSwitch(to scene: SCNScene) {
        let root = SCNNode()

        // Platform: brown PBR for wood texture
        let platform = SCNBox(width: 1.8, height: 0.15, length: 0.8, chamferRadius: 0.03)
        platform.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBrown, metalness: 0.05, roughness: 0.8)
        let pN = SCNNode(geometry: platform)
        pN.position = SCNVector3(0, -0.4, 0)
        root.addChildNode(pN)

        // Contact posts with brass PBR + contact pads
        for x: Float in [-0.5, 0.5] {
            let contact = SCNCylinder(radius: 0.08, height: 0.3)
            contact.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.72, green: 0.58, blue: 0.2, alpha: 1), metalness: 0.75, roughness: 0.25)
            let cN = SCNNode(geometry: contact)
            cN.position = SCNVector3(x, -0.15, 0)
            root.addChildNode(cN)

            // Contact pad (flat cylinder on top of post)
            let pad = SCNCylinder(radius: 0.12, height: 0.03)
            pad.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.72, green: 0.58, blue: 0.2, alpha: 1), metalness: 0.75, roughness: 0.25)
            let padN = SCNNode(geometry: pad)
            padN.position = SCNVector3(x, 0.02, 0)
            root.addChildNode(padN)
        }

        // Lever: orange PBR with pivot ball
        let lever = SCNCylinder(radius: 0.05, height: 1.1)
        lever.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.4, roughness: 0.35)
        let lN = SCNNode(geometry: lever)
        lN.pivot = SCNMatrix4MakeTranslation(0, -0.55, 0)
        lN.position = SCNVector3(-0.5, 0, 0)
        root.addChildNode(lN)

        // Pivot ball at base of lever
        let pivotBall = SCNSphere(radius: 0.07)
        pivotBall.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray, metalness: 0.8, roughness: 0.2)
        let pivotN = SCNNode(geometry: pivotBall)
        pivotN.position = SCNVector3(0, -0.55, 0)
        lN.addChildNode(pivotN)

        // Top knob
        let knob = SCNSphere(radius: 0.06)
        knob.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.5, roughness: 0.3)
        let knobN = SCNNode(geometry: knob)
        knobN.position = SCNVector3(0, 0.55, 0)
        lN.addChildNode(knobN)

        // Toggle animation
        let toggle = CABasicAnimation(keyPath: "eulerAngles.z")
        toggle.fromValue = Float.pi * 0.1
        toggle.toValue = -Float.pi * 0.35
        toggle.duration = 2
        toggle.autoreverses = true
        toggle.repeatCount = .infinity
        lN.addAnimation(toggle, forKey: "toggle")

        // Green/Red omni light synchronized with toggle
        let switchLight = SCNNode()
        switchLight.light = SCNLight()
        switchLight.light?.type = .omni
        switchLight.light?.intensity = 150
        switchLight.position = SCNVector3(0, 0.3, 0.5)
        root.addChildNode(switchLight)

        let lightColor = CAKeyframeAnimation(keyPath: "light.color")
        lightColor.values = [UIColor.systemRed, UIColor.systemGreen, UIColor.systemGreen, UIColor.systemRed]
        lightColor.keyTimes = [0, 0.5, 0.5, 1.0]
        lightColor.duration = 4
        lightColor.repeatCount = .infinity
        switchLight.addAnimation(lightColor, forKey: "switchLightColor")

        addSpin(to: root, duration: 10)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Lightning
    private func addLightning(to scene: SCNScene) {
        let root = SCNNode()

        // Cloud: 3-4 overlapping spheres for cluster shape
        let cloudPositions: [(Float, Float, Float, CGFloat)] = [
            (0, 1.3, 0, 0.8),
            (-0.5, 1.4, 0.1, 0.6),
            (0.5, 1.35, -0.1, 0.65),
            (0.15, 1.5, 0.05, 0.5)
        ]
        for cp in cloudPositions {
            let cloudPart = SCNSphere(radius: cp.3)
            cloudPart.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray, metalness: 0.05, roughness: 0.9)
            let cpN = SCNNode(geometry: cloudPart)
            cpN.position = SCNVector3(cp.0, cp.1, cp.2)
            cpN.scale = SCNVector3(1.5, 0.5, 1)
            root.addChildNode(cpN)
        }

        // Main bolt segments
        let pts: [(Float, Float)] = [(0, 0.8), (0.25, 0.3), (-0.1, 0.1), (0.2, -0.3), (0, -0.8)]
        for i in 0..<(pts.count - 1) {
            let s = pts[i], e = pts[i + 1]
            let dx = e.0 - s.0, dy = e.1 - s.1, len = sqrt(dx * dx + dy * dy)

            // Main bolt segment
            let seg = SCNCylinder(radius: 0.045, height: CGFloat(len))
            seg.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.2, emission: UIColor.systemYellow, emissionIntensity: 2.0)
            let sN = SCNNode(geometry: seg)
            sN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, 0)
            sN.eulerAngles.z = -atan2(dx, dy)
            root.addChildNode(sN)

            // Glow halo bolt behind (2x radius, high transparency)
            let halo = SCNCylinder(radius: 0.09, height: CGFloat(len))
            halo.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow.withAlphaComponent(0.2), metalness: 0.0, roughness: 0.1, emission: UIColor.systemYellow, emissionIntensity: 1.5, transparency: 0.3)
            let hN = SCNNode(geometry: halo)
            hN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, -0.01)
            hN.eulerAngles.z = -atan2(dx, dy)
            root.addChildNode(hN)
        }

        // Branch bolt 1
        let branch1: [(Float, Float)] = [(0.25, 0.3), (0.5, 0.05), (0.65, -0.15)]
        for i in 0..<(branch1.count - 1) {
            let s = branch1[i], e = branch1[i + 1]
            let dx = e.0 - s.0, dy = e.1 - s.1, len = sqrt(dx * dx + dy * dy)
            let seg = SCNCylinder(radius: 0.025, height: CGFloat(len))
            seg.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.2, emission: UIColor.systemYellow, emissionIntensity: 1.5)
            let sN = SCNNode(geometry: seg)
            sN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, 0)
            sN.eulerAngles.z = -atan2(dx, dy)
            root.addChildNode(sN)
        }

        // Branch bolt 2
        let branch2: [(Float, Float)] = [(-0.1, 0.1), (-0.35, -0.1), (-0.5, -0.35)]
        for i in 0..<(branch2.count - 1) {
            let s = branch2[i], e = branch2[i + 1]
            let dx = e.0 - s.0, dy = e.1 - s.1, len = sqrt(dx * dx + dy * dy)
            let seg = SCNCylinder(radius: 0.02, height: CGFloat(len))
            seg.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.2, emission: UIColor.systemYellow, emissionIntensity: 1.2)
            let sN = SCNNode(geometry: seg)
            sN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, 0)
            sN.eulerAngles.z = -atan2(dx, dy)
            root.addChildNode(sN)
        }

        // Flash light
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.systemYellow
        light.intensity = 800
        let lN = SCNNode()
        lN.light = light
        lN.position = SCNVector3(0, 0, 1)
        root.addChildNode(lN)

        let flash = CABasicAnimation(keyPath: "light.intensity")
        flash.fromValue = 200
        flash.toValue = 3000
        flash.duration = 0.3
        flash.autoreverses = true
        flash.repeatCount = .infinity
        lN.addAnimation(flash, forKey: "flash")

        // Rain: 8-10 falling cylinders
        for i in 0..<10 {
            let rain = SCNCylinder(radius: 0.008, height: 0.3)
            rain.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBlue.withAlphaComponent(0.6), metalness: 0.1, roughness: 0.2, transparency: 0.6)
            let rN = SCNNode(geometry: rain)
            let xPos = Float.random(in: -1.2...1.2)
            let zPos = Float.random(in: -0.3...0.3)
            rN.position = SCNVector3(xPos, 1.0, zPos)
            root.addChildNode(rN)

            let fall = CABasicAnimation(keyPath: "position.y")
            fall.fromValue = 1.0
            fall.toValue = -1.5
            fall.duration = CFTimeInterval(Float.random(in: 0.8...1.5))
            fall.repeatCount = .infinity
            fall.timeOffset = CFTimeInterval(Float.random(in: 0...1.5))
            rN.addAnimation(fall, forKey: "rain\(i)")
        }

        scene.rootNode.addChildNode(root)
    }

    // MARK: - Series Circuit
    private func addSeriesCircuit(to scene: SCNScene) {
        let root = SCNNode()
        let copperColor = UIColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 1)
        let positions: [Float] = [-1.2, 0, 1.2]

        // Battery miniature (green cylinder with cap)
        let battBody = SCNCylinder(radius: 0.2, height: 0.35)
        battBody.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.6, roughness: 0.3)
        let battN = SCNNode(geometry: battBody)
        battN.position = SCNVector3(positions[0], 0, 0)
        root.addChildNode(battN)

        let battCap = SCNCylinder(radius: 0.08, height: 0.06)
        battCap.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let battCapN = SCNNode(geometry: battCap)
        battCapN.position = SCNVector3(positions[0], 0.2, 0)
        root.addChildNode(battCapN)

        // Resistor miniature (tan capsule)
        let resBody = SCNCapsule(capRadius: 0.15, height: 0.4)
        resBody.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1), metalness: 0.1, roughness: 0.6)
        let resN = SCNNode(geometry: resBody)
        resN.position = SCNVector3(positions[1], 0, 0)
        resN.eulerAngles.z = .pi / 2
        root.addChildNode(resN)

        // LED miniature (red dome)
        let ledDome = SCNSphere(radius: 0.2)
        ledDome.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.1, roughness: 0.15, emission: UIColor.systemRed, emissionIntensity: 1.5, transparency: 0.6)
        let ledN = SCNNode(geometry: ledDome)
        ledN.position = SCNVector3(positions[2], 0, 0)
        root.addChildNode(ledN)
        glowPulse(on: ledN)

        // Copper wires connecting components
        for i in 0..<(positions.count - 1) {
            let wire = SCNCylinder(radius: 0.03, height: CGFloat(positions[i + 1] - positions[i]))
            wire.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
            let wN = SCNNode(geometry: wire)
            wN.position = SCNVector3((positions[i] + positions[i + 1]) / 2, 0, 0)
            wN.eulerAngles.z = .pi / 2
            root.addChildNode(wN)
        }

        // Return wire (bottom)
        let retWire = SCNBox(width: CGFloat(positions.last! - positions.first!), height: 0.06, length: 0.06, chamferRadius: 0)
        retWire.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
        let rN = SCNNode(geometry: retWire)
        rN.position = SCNVector3(0, -0.8, 0)
        root.addChildNode(rN)

        // Vertical connectors
        for x in [positions.first!, positions.last!] {
            let vert = SCNCylinder(radius: 0.03, height: 0.8)
            vert.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
            let vN = SCNNode(geometry: vert)
            vN.position = SCNVector3(x, -0.4, 0)
            root.addChildNode(vN)
        }

        // Current flow animation (blue spheres along wire path)
        let pathPoints: [SCNVector3] = [
            SCNVector3(positions[0], 0, 0),
            SCNVector3(positions[1], 0, 0),
            SCNVector3(positions[2], 0, 0),
            SCNVector3(positions[2], -0.8, 0),
            SCNVector3(positions[0], -0.8, 0),
            SCNVector3(positions[0], 0, 0)
        ]

        for i in 0..<6 {
            let dot = SCNSphere(radius: 0.04)
            dot.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBlue, metalness: 0.2, roughness: 0.3, emission: UIColor.systemBlue, emissionIntensity: 1.5)
            let dotNode = SCNNode(geometry: dot)
            root.addChildNode(dotNode)

            let posAnim = CAKeyframeAnimation(keyPath: "position")
            posAnim.values = pathPoints.map { NSValue(scnVector3: $0) }
            var totalLen: Float = 0
            var segLens: [Float] = [0]
            for j in 0..<(pathPoints.count - 1) {
                let dx = pathPoints[j + 1].x - pathPoints[j].x
                let dy = pathPoints[j + 1].y - pathPoints[j].y
                totalLen += sqrt(dx * dx + dy * dy)
                segLens.append(totalLen)
            }
            posAnim.keyTimes = segLens.map { NSNumber(value: $0 / totalLen) }
            posAnim.duration = 4.0
            posAnim.repeatCount = .infinity
            posAnim.timeOffset = Double(i) * (4.0 / 6.0)
            posAnim.calculationMode = .linear
            dotNode.addAnimation(posAnim, forKey: "currentFlow\(i)")
        }

        addSpin(to: root, duration: 10)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Parallel Circuit
    private func addParallelCircuit(to scene: SCNScene) {
        let root = SCNNode()
        let copperColor = UIColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 1)

        // Two branches with different colored LEDs
        let branchY: [Float] = [0.5, -0.5]
        let branchColors: [UIColor] = [.systemYellow, .systemCyan]

        for (i, y) in branchY.enumerated() {
            // LED dome miniature
            let ledDome = SCNSphere(radius: 0.2)
            ledDome.firstMaterial = makePBRMaterial(diffuse: branchColors[i], metalness: 0.1, roughness: 0.15, emission: branchColors[i], emissionIntensity: 1.5, transparency: 0.6)
            let cN = SCNNode(geometry: ledDome)
            cN.position = SCNVector3(0, y, 0)
            root.addChildNode(cN)
            glowPulse(on: cN)

            // Horizontal copper wires for each branch
            for xOff: Float in [-0.6, 0.6] {
                let hw = SCNCylinder(radius: 0.03, height: 0.4)
                hw.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
                let hN = SCNNode(geometry: hw)
                hN.position = SCNVector3(xOff, y, 0)
                hN.eulerAngles.z = .pi / 2
                root.addChildNode(hN)
            }
        }

        // Metallic bus bars (vertical)
        for x: Float in [-0.8, 0.8] {
            let vb = SCNCylinder(radius: 0.04, height: 1.0)
            vb.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.85, roughness: 0.2)
            let vN = SCNNode(geometry: vb)
            vN.position = SCNVector3(x, 0, 0)
            root.addChildNode(vN)
        }

        // Battery on left (miniature green cylinder with cap)
        let batt = SCNCylinder(radius: 0.15, height: 0.4)
        batt.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.6, roughness: 0.3)
        let battN = SCNNode(geometry: batt)
        battN.position = SCNVector3(-1.2, 0, 0)
        root.addChildNode(battN)

        let battCap = SCNCylinder(radius: 0.06, height: 0.05)
        battCap.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.85, roughness: 0.15)
        let battCapN = SCNNode(geometry: battCap)
        battCapN.position = SCNVector3(-1.2, 0.22, 0)
        root.addChildNode(battCapN)

        let bWire = SCNCylinder(radius: 0.03, height: 0.4)
        bWire.firstMaterial = makePBRMaterial(diffuse: copperColor, metalness: 0.8, roughness: 0.25)
        let bwN = SCNNode(geometry: bWire)
        bwN.position = SCNVector3(-1.0, 0, 0)
        bwN.eulerAngles.z = .pi / 2
        root.addChildNode(bwN)

        // Current flow animation on both branches
        for (bi, y) in branchY.enumerated() {
            let branchPath: [SCNVector3] = [
                SCNVector3(-0.8, y, 0),
                SCNVector3(0, y, 0),
                SCNVector3(0.8, y, 0)
            ]
            for i in 0..<3 {
                let dot = SCNSphere(radius: 0.035)
                dot.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBlue, metalness: 0.2, roughness: 0.3, emission: UIColor.systemBlue, emissionIntensity: 1.5)
                let dotNode = SCNNode(geometry: dot)
                root.addChildNode(dotNode)

                let posAnim = CAKeyframeAnimation(keyPath: "position")
                posAnim.values = branchPath.map { NSValue(scnVector3: $0) }
                posAnim.keyTimes = [0, 0.5, 1.0]
                posAnim.duration = 2.0
                posAnim.repeatCount = .infinity
                posAnim.timeOffset = Double(i) * (2.0 / 3.0)
                posAnim.calculationMode = .linear
                dotNode.addAnimation(posAnim, forKey: "branchFlow\(bi)_\(i)")
            }
        }

        addSpin(to: root, duration: 10)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Multimeter
    private func addMultimeter(to scene: SCNScene) {
        let root = SCNNode()

        // Body: yellow PBR, larger chamferRadius
        let body = SCNBox(width: 1.2, height: 1.8, length: 0.3, chamferRadius: 0.12)
        body.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.4)
        root.addChildNode(SCNNode(geometry: body))

        // Screen bezel (dark frame)
        let bezel = SCNBox(width: 0.95, height: 0.55, length: 0.02, chamferRadius: 0.03)
        bezel.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1), metalness: 0.3, roughness: 0.5)
        let bezelN = SCNNode(geometry: bezel)
        bezelN.position = SCNVector3(0, 0.5, 0.16)
        root.addChildNode(bezelN)

        // Screen: emissive green-on-dark LCD look
        let screen = SCNBox(width: 0.85, height: 0.45, length: 0.02, chamferRadius: 0.02)
        screen.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.1, green: 0.15, blue: 0.1, alpha: 1), metalness: 0.1, roughness: 0.3, emission: UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1), emissionIntensity: 0.5)
        let scN = SCNNode(geometry: screen)
        scN.position = SCNVector3(0, 0.5, 0.175)
        root.addChildNode(scN)

        // Digit segments simulating "12.5"
        let digitPositions: [(Float, Float)] = [(-0.25, 0.5), (-0.05, 0.5), (0.1, 0.5), (0.25, 0.5)]
        let digitWidths: [CGFloat] = [0.08, 0.06, 0.02, 0.08]
        let digitHeights: [CGFloat] = [0.2, 0.2, 0.02, 0.2]
        for (i, dp) in digitPositions.enumerated() {
            let seg = SCNBox(width: digitWidths[i], height: digitHeights[i], length: 0.005, chamferRadius: 0)
            seg.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1), metalness: 0.0, roughness: 0.3, emission: UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1), emissionIntensity: 1.5)
            let segN = SCNNode(geometry: seg)
            segN.position = SCNVector3(dp.0, dp.1, 0.19)
            root.addChildNode(segN)
        }

        // Dial
        let dial = SCNCylinder(radius: 0.2, height: 0.05)
        dial.firstMaterial = makePBRMaterial(diffuse: UIColor.darkGray, metalness: 0.5, roughness: 0.3)
        let dN = SCNNode(geometry: dial)
        dN.position = SCNVector3(0, -0.1, 0.18)
        dN.eulerAngles.x = .pi / 2
        root.addChildNode(dN)

        // 12 radial tick cylinders around dial
        for t in 0..<12 {
            let angle = Float(t) * (Float.pi * 2 / 12)
            let tick = SCNCylinder(radius: 0.008, height: 0.06)
            tick.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.3, roughness: 0.4)
            let tN = SCNNode(geometry: tick)
            tN.position = SCNVector3(
                sin(angle) * 0.25,
                -0.1 + cos(angle) * 0.25,
                0.19
            )
            tN.eulerAngles.z = -angle
            root.addChildNode(tN)
        }

        // Cone pointer on dial
        let pointer = SCNCone(topRadius: 0, bottomRadius: 0.02, height: 0.18)
        pointer.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.3, roughness: 0.3)
        let pointerN = SCNNode(geometry: pointer)
        pointerN.position = SCNVector3(0, -0.1, 0.2)
        pointerN.eulerAngles.x = .pi / 2
        root.addChildNode(pointerN)

        // Probe ports: proper color coding
        let portConfigs: [(Float, UIColor, String)] = [(-0.3, .black, "COM"), (-0.1, .systemRed, "V"), (0.1, .systemRed, "Ohm")]
        for pc in portConfigs {
            let port = SCNCylinder(radius: 0.06, height: 0.05)
            port.firstMaterial = makePBRMaterial(diffuse: pc.1, metalness: 0.4, roughness: 0.3)
            let pN = SCNNode(geometry: port)
            pN.position = SCNVector3(pc.0, -0.75, 0.18)
            pN.eulerAngles.x = .pi / 2
            root.addChildNode(pN)
        }

        // Probe wires: red and black, series of small connected cylinders curving downward
        let probeColors: [UIColor] = [.black, .systemRed]
        let probeStartX: [Float] = [-0.3, -0.1]

        for (pi, color) in probeColors.enumerated() {
            let startX = probeStartX[pi]
            let xDir: Float = pi == 0 ? -1 : 1
            let wirePoints: [(Float, Float, Float)] = [
                (startX, -0.8, 0.18),
                (startX + xDir * 0.1, -1.0, 0.15),
                (startX + xDir * 0.15, -1.2, 0.1),
                (startX + xDir * 0.2, -1.4, 0.05),
                (startX + xDir * 0.25, -1.6, 0.0)
            ]
            for j in 0..<(wirePoints.count - 1) {
                let s = wirePoints[j], e = wirePoints[j + 1]
                let dx = e.0 - s.0, dy = e.1 - s.1, dz = e.2 - s.2
                let len = sqrt(dx * dx + dy * dy + dz * dz)
                let wireSeg = SCNCylinder(radius: 0.015, height: CGFloat(len))
                wireSeg.firstMaterial = makePBRMaterial(diffuse: color, metalness: 0.2, roughness: 0.5)
                let wN = SCNNode(geometry: wireSeg)
                wN.position = SCNVector3((s.0 + e.0) / 2, (s.1 + e.1) / 2, (s.2 + e.2) / 2)
                // Orient the cylinder along the segment direction
                let midToEnd = SCNVector3(dx, dy, dz)
                let up = SCNVector3(0, 1, 0)
                let cross = SCNVector3(
                    up.y * midToEnd.z - up.z * midToEnd.y,
                    up.z * midToEnd.x - up.x * midToEnd.z,
                    up.x * midToEnd.y - up.y * midToEnd.x
                )
                let crossLen = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
                let dot = up.x * midToEnd.x + up.y * midToEnd.y + up.z * midToEnd.z
                let angle = atan2(crossLen, dot)
                if crossLen > 0.001 {
                    wN.rotation = SCNVector4(cross.x / crossLen, cross.y / crossLen, cross.z / crossLen, angle)
                }
                root.addChildNode(wN)
            }

            // Probe tip
            let tip = SCNCone(topRadius: 0, bottomRadius: 0.02, height: 0.1)
            tip.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.8, roughness: 0.2)
            let tipN = SCNNode(geometry: tip)
            let lastPt = wirePoints.last!
            tipN.position = SCNVector3(lastPt.0, lastPt.1 - 0.05, lastPt.2)
            root.addChildNode(tipN)
        }

        addSpin(to: root)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Breadboard
    private func addBreadboard(to scene: SCNScene) {
        let root = SCNNode()

        // Board: off-white PBR, chamfered edges
        let board = SCNBox(width: 2.2, height: 0.1, length: 1.2, chamferRadius: 0.04)
        board.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1), metalness: 0.05, roughness: 0.7)
        root.addChildNode(SCNNode(geometry: board))

        // Center groove (visible divider indentation)
        let groove = SCNBox(width: 2.0, height: 0.03, length: 0.08, chamferRadius: 0)
        groove.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.75, green: 0.73, blue: 0.68, alpha: 1), metalness: 0.05, roughness: 0.8)
        let grooveN = SCNNode(geometry: groove)
        grooveN.position = SCNVector3(0, 0.055, 0)
        root.addChildNode(grooveN)

        // Rows of holes
        for row in stride(from: -0.4, through: 0.4, by: 0.15) {
            // Skip the center groove area
            if abs(Float(row)) < 0.05 { continue }
            for col in stride(from: -0.9, through: 0.9, by: 0.12) {
                let hole = SCNCylinder(radius: 0.02, height: 0.12)
                hole.firstMaterial = makePBRMaterial(diffuse: UIColor.darkGray, metalness: 0.3, roughness: 0.5)
                let hN = SCNNode(geometry: hole)
                hN.position = SCNVector3(Float(col), 0.06, Float(row))
                root.addChildNode(hN)
            }
        }

        // Power rails (red/blue stripes)
        let redRail = SCNBox(width: 2.2, height: 0.02, length: 0.06, chamferRadius: 0)
        redRail.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.1, roughness: 0.5)
        let rrN = SCNNode(geometry: redRail)
        rrN.position = SCNVector3(0, 0.06, 0.55)
        root.addChildNode(rrN)

        let blueRail = SCNBox(width: 2.2, height: 0.02, length: 0.06, chamferRadius: 0)
        blueRail.firstMaterial = makePBRMaterial(diffuse: UIColor.systemBlue, metalness: 0.1, roughness: 0.5)
        let brN = SCNNode(geometry: blueRail)
        brN.position = SCNVector3(0, 0.06, -0.55)
        root.addChildNode(brN)

        // +/- indicator shapes at ends of power rails
        // Plus at red rail end
        let plusH = SCNBox(width: 0.08, height: 0.02, length: 0.02, chamferRadius: 0)
        plusH.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let plusHN = SCNNode(geometry: plusH)
        plusHN.position = SCNVector3(-1.0, 0.08, 0.55)
        root.addChildNode(plusHN)

        let plusV = SCNBox(width: 0.02, height: 0.02, length: 0.08, chamferRadius: 0)
        plusV.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let plusVN = SCNNode(geometry: plusV)
        plusVN.position = SCNVector3(-1.0, 0.08, 0.55)
        root.addChildNode(plusVN)

        // Minus at blue rail end
        let minusH = SCNBox(width: 0.08, height: 0.02, length: 0.02, chamferRadius: 0)
        minusH.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let minusHN = SCNNode(geometry: minusH)
        minusHN.position = SCNVector3(-1.0, 0.08, -0.55)
        root.addChildNode(minusHN)

        // Pre-placed components: a resistor bridging rows
        let miniRes = SCNCapsule(capRadius: 0.04, height: 0.25)
        miniRes.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1), metalness: 0.1, roughness: 0.6)
        let miniResN = SCNNode(geometry: miniRes)
        miniResN.position = SCNVector3(0.3, 0.12, 0)
        miniResN.eulerAngles.x = .pi / 2
        root.addChildNode(miniResN)

        // Pre-placed LED in holes
        let miniLed = SCNSphere(radius: 0.04)
        miniLed.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.1, roughness: 0.2, emission: UIColor.systemRed, emissionIntensity: 1.5, transparency: 0.6)
        let miniLedN = SCNNode(geometry: miniLed)
        miniLedN.position = SCNVector3(-0.3, 0.1, 0.15)
        root.addChildNode(miniLedN)
        glowPulse(on: miniLedN)

        // Another component: a small wire jumper
        let jumper = SCNCylinder(radius: 0.01, height: 0.24)
        jumper.firstMaterial = makePBRMaterial(diffuse: UIColor.systemOrange, metalness: 0.5, roughness: 0.3)
        let jumperN = SCNNode(geometry: jumper)
        jumperN.position = SCNVector3(0.6, 0.1, 0)
        jumperN.eulerAngles.x = .pi / 2
        root.addChildNode(jumperN)

        addSpin(to: root, duration: 10)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Arduino
    private func addArduino(to scene: SCNScene) {
        let root = SCNNode()

        // PCB: proper teal PBR
        let pcb = SCNBox(width: 2.0, height: 0.1, length: 1.3, chamferRadius: 0.08)
        pcb.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0, green: 0.5, blue: 0.55, alpha: 1), metalness: 0.2, roughness: 0.5)
        root.addChildNode(SCNNode(geometry: pcb))

        // Copper trace lines on surface (thin flat boxes)
        let copperTraceColor = UIColor(red: 0.72, green: 0.45, blue: 0.2, alpha: 1)
        let traceConfigs: [(Float, Float, Float, Float)] = [
            (0.0, 0.0, 1.5, 0.02),
            (0.3, 0.2, 0.8, 0.015),
            (-0.3, -0.15, 0.6, 0.015),
            (0.5, 0.35, 0.4, 0.01),
            (-0.5, -0.3, 0.5, 0.01)
        ]
        for tc in traceConfigs {
            let trace = SCNBox(width: CGFloat(tc.2), height: 0.005, length: CGFloat(tc.3), chamferRadius: 0)
            trace.firstMaterial = makePBRMaterial(diffuse: copperTraceColor, metalness: 0.7, roughness: 0.3)
            let tN = SCNNode(geometry: trace)
            tN.position = SCNVector3(tc.0, 0.053, tc.1)
            root.addChildNode(tN)
        }

        // Main chip
        let chip = SCNBox(width: 0.6, height: 0.08, length: 0.25, chamferRadius: 0.01)
        chip.firstMaterial = makePBRMaterial(diffuse: UIColor.black, metalness: 0.15, roughness: 0.4)
        let chN = SCNNode(geometry: chip)
        chN.position = SCNVector3(0, 0.09, 0)
        root.addChildNode(chN)

        // Pin-1 dot on chip
        let pin1Dot = SCNSphere(radius: 0.02)
        pin1Dot.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.1, roughness: 0.5)
        let pin1N = SCNNode(geometry: pin1Dot)
        pin1N.position = SCNVector3(-0.25, 0.14, -0.08)
        root.addChildNode(pin1N)

        // IC text detail (small box representing text)
        let icText = SCNBox(width: 0.3, height: 0.005, length: 0.05, chamferRadius: 0)
        icText.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.1, roughness: 0.5)
        let icTextN = SCNNode(geometry: icText)
        icTextN.position = SCNVector3(0, 0.135, 0.02)
        root.addChildNode(icTextN)

        // USB port: silver metallic PBR
        let usb = SCNBox(width: 0.25, height: 0.12, length: 0.18, chamferRadius: 0.01)
        usb.firstMaterial = makePBRMaterial(diffuse: UIColor.lightGray, metalness: 0.8, roughness: 0.15)
        let uN = SCNNode(geometry: usb)
        uN.position = SCNVector3(-0.9, 0.11, 0)
        root.addChildNode(uN)

        // USB inner opening (darker inset box)
        let usbInner = SCNBox(width: 0.18, height: 0.06, length: 0.14, chamferRadius: 0)
        usbInner.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1), metalness: 0.3, roughness: 0.5)
        let usbInnerN = SCNNode(geometry: usbInner)
        usbInnerN.position = SCNVector3(-0.9, 0.13, 0)
        root.addChildNode(usbInnerN)

        // Reset button (small cylinder near USB)
        let resetBtn = SCNCylinder(radius: 0.04, height: 0.03)
        resetBtn.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGray, metalness: 0.4, roughness: 0.3)
        let resetN = SCNNode(geometry: resetBtn)
        resetN.position = SCNVector3(-0.65, 0.08, 0.3)
        root.addChildNode(resetN)

        // Pin headers: gold PBR
        let goldColor = UIColor(red: 0.83, green: 0.68, blue: 0.21, alpha: 1)
        for z: Float in [-0.5, 0.5] {
            for x in stride(from: Float(-0.6), through: 0.7, by: 0.1) {
                let pin = SCNCylinder(radius: 0.015, height: 0.15)
                pin.firstMaterial = makePBRMaterial(diffuse: goldColor, metalness: 0.75, roughness: 0.2)
                let pN = SCNNode(geometry: pin)
                pN.position = SCNVector3(x, 0.12, z)
                root.addChildNode(pN)
            }
        }

        // Main LED on board
        let led = SCNSphere(radius: 0.04)
        led.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.1, roughness: 0.2, emission: UIColor.systemGreen, emissionIntensity: 1.5)
        let lN = SCNNode(geometry: led)
        lN.position = SCNVector3(0.5, 0.1, -0.25)
        root.addChildNode(lN)
        glowPulse(on: lN)

        // TX/RX LEDs (tiny yellow/green spheres near main LED)
        let txLed = SCNSphere(radius: 0.025)
        txLed.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.1, roughness: 0.2, emission: UIColor.systemYellow, emissionIntensity: 1.0)
        let txN = SCNNode(geometry: txLed)
        txN.position = SCNVector3(0.4, 0.1, -0.25)
        root.addChildNode(txN)
        glowPulse(on: txN, key: "txGlow")

        let rxLed = SCNSphere(radius: 0.025)
        rxLed.firstMaterial = makePBRMaterial(diffuse: UIColor.systemGreen, metalness: 0.1, roughness: 0.2, emission: UIColor.systemGreen, emissionIntensity: 1.0)
        let rxN = SCNNode(geometry: rxLed)
        rxN.position = SCNVector3(0.35, 0.1, -0.25)
        root.addChildNode(rxN)
        glowPulse(on: rxN, key: "rxGlow")

        addSpin(to: root, duration: 8)
        scene.rootNode.addChildNode(root)
    }

    // MARK: - Fuse Box
    private func addFuseBox(to scene: SCNScene) {
        let root = SCNNode()

        // Frame border (slightly larger box behind)
        let frame = SCNBox(width: 1.9, height: 2.1, length: 0.38, chamferRadius: 0.04)
        frame.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.55, green: 0.55, blue: 0.5, alpha: 1), metalness: 0.3, roughness: 0.5)
        let frameN = SCNNode(geometry: frame)
        frameN.position = SCNVector3(0, 0, -0.02)
        root.addChildNode(frameN)

        // Box: beige/cream PBR
        let box = SCNBox(width: 1.8, height: 2.0, length: 0.4, chamferRadius: 0.03)
        box.firstMaterial = makePBRMaterial(diffuse: UIColor(red: 0.92, green: 0.88, blue: 0.78, alpha: 1), metalness: 0.1, roughness: 0.6)
        root.addChildNode(SCNNode(geometry: box))

        // Breaker switches with ON/OFF indicators
        for row in 0..<4 {
            for col in 0..<2 {
                let isTripped = row == 2 && col == 0

                let breaker = SCNBox(width: 0.3, height: 0.15, length: 0.08, chamferRadius: 0.02)
                breaker.firstMaterial = makePBRMaterial(diffuse: UIColor.darkGray, metalness: 0.4, roughness: 0.35)
                let bN = SCNNode(geometry: breaker)
                bN.position = SCNVector3(
                    Float(col) * 0.5 - 0.25,
                    Float(row) * 0.35 - 0.5,
                    0.22
                )
                root.addChildNode(bN)

                // ON/OFF color indicator stripe
                let indicator = SCNBox(width: 0.04, height: 0.15, length: 0.005, chamferRadius: 0)
                let indicatorColor = isTripped ? UIColor.systemRed : UIColor.systemGreen
                indicator.firstMaterial = makePBRMaterial(diffuse: indicatorColor, metalness: 0.1, roughness: 0.4, emission: indicatorColor, emissionIntensity: 0.5)
                let indN = SCNNode(geometry: indicator)
                indN.position = SCNVector3(
                    Float(col) * 0.5 - 0.25 + 0.18,
                    Float(row) * 0.35 - 0.5,
                    0.265
                )
                root.addChildNode(indN)

                // Toggle handle
                let toggle = SCNBox(width: 0.08, height: 0.06, length: 0.04, chamferRadius: 0.01)
                toggle.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.3, roughness: 0.4)
                let tN = SCNNode(geometry: toggle)
                tN.position = SCNVector3(bN.position.x, bN.position.y + 0.05, 0.27)
                root.addChildNode(tN)

                // Animated tripping breaker
                if isTripped {
                    let rock = CABasicAnimation(keyPath: "eulerAngles.x")
                    rock.fromValue = Float.pi * 0.05
                    rock.toValue = -Float.pi * 0.15
                    rock.duration = 1.0
                    rock.autoreverses = true
                    rock.repeatCount = .infinity
                    tN.addAnimation(rock, forKey: "trip")
                }
            }
        }

        // Internal wiring (thin colored cylinders: black, red, white)
        let wireColors: [UIColor] = [.black, .systemRed, .white]
        let wireXPositions: [Float] = [-0.6, -0.5, -0.4]
        for (i, color) in wireColors.enumerated() {
            let wire = SCNCylinder(radius: 0.015, height: 1.6)
            wire.firstMaterial = makePBRMaterial(diffuse: color, metalness: 0.2, roughness: 0.5)
            let wN = SCNNode(geometry: wire)
            wN.position = SCNVector3(wireXPositions[i], 0, 0.15)
            root.addChildNode(wN)
        }

        // Main switch: larger red handle with toggle
        let main = SCNBox(width: 0.8, height: 0.2, length: 0.1, chamferRadius: 0.02)
        main.firstMaterial = makePBRMaterial(diffuse: UIColor.systemRed, metalness: 0.3, roughness: 0.4)
        let mN = SCNNode(geometry: main)
        mN.position = SCNVector3(0, 0.8, 0.22)
        root.addChildNode(mN)

        // Main switch handle
        let mainHandle = SCNBox(width: 0.2, height: 0.08, length: 0.06, chamferRadius: 0.01)
        mainHandle.firstMaterial = makePBRMaterial(diffuse: UIColor.white, metalness: 0.3, roughness: 0.4)
        let mainHandleN = SCNNode(geometry: mainHandle)
        mainHandleN.position = SCNVector3(0, 0.85, 0.28)
        root.addChildNode(mainHandleN)

        // Yellow warning triangle
        // Build with 3 boxes forming a triangle outline
        let warningBase = SCNBox(width: 0.3, height: 0.025, length: 0.025, chamferRadius: 0)
        warningBase.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.3, emission: UIColor.systemYellow, emissionIntensity: 0.5)
        let wbN = SCNNode(geometry: warningBase)
        wbN.position = SCNVector3(0.55, -0.75, 0.22)
        root.addChildNode(wbN)

        let warningLeft = SCNBox(width: 0.025, height: 0.25, length: 0.025, chamferRadius: 0)
        warningLeft.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.3, emission: UIColor.systemYellow, emissionIntensity: 0.5)
        let wlN = SCNNode(geometry: warningLeft)
        wlN.position = SCNVector3(0.42, -0.63, 0.22)
        wlN.eulerAngles.z = Float.pi * 0.1
        root.addChildNode(wlN)

        let warningRight = SCNBox(width: 0.025, height: 0.25, length: 0.025, chamferRadius: 0)
        warningRight.firstMaterial = makePBRMaterial(diffuse: UIColor.systemYellow, metalness: 0.3, roughness: 0.3, emission: UIColor.systemYellow, emissionIntensity: 0.5)
        let wrN = SCNNode(geometry: warningRight)
        wrN.position = SCNVector3(0.68, -0.63, 0.22)
        wrN.eulerAngles.z = -Float.pi * 0.1
        root.addChildNode(wrN)

        // Exclamation mark inside triangle
        let excl = SCNBox(width: 0.03, height: 0.1, length: 0.025, chamferRadius: 0)
        excl.firstMaterial = makePBRMaterial(diffuse: UIColor.black, metalness: 0.1, roughness: 0.5)
        let exclN = SCNNode(geometry: excl)
        exclN.position = SCNVector3(0.55, -0.65, 0.23)
        root.addChildNode(exclN)

        let exclDot = SCNSphere(radius: 0.02)
        exclDot.firstMaterial = makePBRMaterial(diffuse: UIColor.black, metalness: 0.1, roughness: 0.5)
        let exclDotN = SCNNode(geometry: exclDot)
        exclDotN.position = SCNVector3(0.55, -0.73, 0.23)
        root.addChildNode(exclDotN)

        addSpin(to: root)
        scene.rootNode.addChildNode(root)
    }
}
