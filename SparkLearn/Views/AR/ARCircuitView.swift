import SwiftUI
import SceneKit

#if canImport(ARKit)
import ARKit
#endif

// MARK: - AR Circuit View

struct ARCircuitView: View {
    @StateObject private var sessionManager = ARSessionManager()
    @State private var showComponentPicker = true
    @State private var selectedInfo: ARPlacedComponent?
    @State private var showScreenshotFlash = false
    @State private var savedScreenshot: UIImage?
    @State private var showSavedAlert = false
    @State private var coachingVisible = true

    var body: some View {
        ZStack {
            if sessionManager.isARSupported {
                arContentView
            } else {
                arUnsupportedFallback
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - AR Content

    private var arContentView: some View {
        ZStack {
            // AR SceneKit view
            ARSceneViewContainer(
                sessionManager: sessionManager,
                onComponentTapped: { component in
                    Haptics.light()
                    withAnimation(DS.feedbackAnim) {
                        selectedInfo = component
                    }
                },
                onSurfaceDetected: {
                    withAnimation(DS.transitionAnim) {
                        coachingVisible = false
                    }
                }
            )
            .ignoresSafeArea()

            // Screenshot flash
            if showScreenshotFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            // Coaching overlay
            if coachingVisible {
                coachingOverlay
                    .transition(.opacity)
            }

            // HUD layer
            VStack(spacing: 0) {
                topBar
                Spacer()
                if let info = selectedInfo {
                    componentInfoOverlay(info)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }
                if showComponentPicker {
                    componentPicker
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                bottomControls
            }
        }
        .alert("Screenshot Saved", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The AR screenshot has been saved to your photo library.")
        }
    }

    // MARK: - Coaching Overlay

    private var coachingOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.point.up.left.and.text")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DS.electricBlue, DS.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .floating(amplitude: 8, duration: 1.5)

            Text("Move your phone to scan a surface")
                .font(DS.headlineFont)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(sessionManager.sessionState.statusMessage)
                .font(DS.captionFont)
                .foregroundColor(.white.opacity(0.7))

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.55))
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .pulseGlow(color: statusColor, radius: 6)

                Text(sessionManager.sessionState.statusMessage)
                    .font(DS.captionFont)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )

            Spacer()

            // Placed count badge
            if sessionManager.placedComponentsCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(sessionManager.placedComponentsCount)")
                        .font(DS.captionFont)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(DS.deepPurple.opacity(0.8))
                )
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.top, 60)
    }

    // MARK: - Component Picker

    private var componentPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pickerComponents, id: \.self) { type in
                    componentPickerItem(type)
                }
            }
            .padding(.horizontal, DS.padding)
            .padding(.vertical, 8)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    private var pickerComponents: [SceneType] {
        [.resistor, .capacitor, .led, .diode, .battery, .lightBulb,
         .switchToggle, .atom, .multimeter, .breadboard, .arduino, .fuseBox]
    }

    private func componentPickerItem(_ type: SceneType) -> some View {
        let isSelected = sessionManager.selectedComponentType == type
        let displayName = componentDisplayName(for: type)
        let iconName = componentIconName(for: type)

        return Button {
            Haptics.light()
            withAnimation(DS.feedbackAnim) {
                sessionManager.selectedComponentType = type
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? DS.primary : Color.white.opacity(0.15))
                    )

                Text(displayName)
                    .font(DS.smallFont)
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.vertical, 4)
        }
    }

    // MARK: - Component Info Overlay

    private func componentInfoOverlay(_ component: ARPlacedComponent) -> some View {
        DSGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: component.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DS.electricBlue)

                    Text(component.displayName)
                        .font(DS.headlineFont)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        Haptics.light()
                        withAnimation(DS.feedbackAnim) {
                            selectedInfo = nil
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Text(component.specs)
                    .font(DS.bodyFont)
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 16) {
                    Label(
                        "Scale: \(String(format: "%.1fx", component.scale))",
                        systemImage: "arrow.up.left.and.arrow.down.right"
                    )
                    .font(DS.captionFont)
                    .foregroundColor(.white.opacity(0.5))

                    Label(
                        String(format: "(%.2f, %.2f, %.2f)",
                               component.position.x,
                               component.position.y,
                               component.position.z),
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(DS.captionFont)
                    .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, DS.padding)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 16) {
            // Toggle picker
            Button {
                Haptics.light()
                withAnimation(DS.feedbackAnim) {
                    showComponentPicker.toggle()
                }
            } label: {
                Image(systemName: showComponentPicker ? "chevron.down.circle.fill" : "cube.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(.ultraThinMaterial))
            }

            // Screenshot
            Button {
                takeScreenshot()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Screenshot")
                        .font(DS.captionFont)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(DS.primary.opacity(0.85))
                )
            }

            Spacer()

            // Reset
            Button {
                Haptics.medium()
                withAnimation(DS.feedbackAnim) {
                    coachingVisible = true
                    selectedInfo = nil
                }
                // Reset is called from the container via notification
                NotificationCenter.default.post(name: .arSessionReset, object: nil)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(DS.error.opacity(0.7)))
            }
        }
        .padding(.horizontal, DS.padding)
        .padding(.bottom, 40)
    }

    // MARK: - Fallback for Unsupported Devices

    private var arUnsupportedFallback: some View {
        ZStack {
            DS.heroBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "arkit")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DS.electricBlue, DS.deepPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .floating(amplitude: 6, duration: 2.0)

                Text("AR Not Available")
                    .font(DS.heroTitleFont)
                    .foregroundColor(DS.textPrimary)

                Text("This device does not support ARKit world tracking. Please use a device with an A9 chip or later to experience AR components.")
                    .font(DS.bodyFont)
                    .foregroundColor(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                DSGlassCard {
                    VStack(spacing: 12) {
                        Label("Tip", systemImage: "lightbulb.fill")
                            .font(DS.headlineFont)
                            .foregroundColor(DS.warning)

                        Text("You can still explore 3D component models in the interactive 3D viewer -- AR is optional!")
                            .font(DS.bodyFont)
                            .foregroundColor(DS.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, DS.padding)
            }
            .padding(DS.padding)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch sessionManager.sessionState {
        case .tracking, .surfaceDetected: return DS.success
        case .scanning, .initializing:    return DS.warning
        case .limitedTracking:            return DS.accent
        case .failed:                     return DS.error
        case .notStarted, .paused:        return DS.textTertiary
        }
    }

    private func takeScreenshot() {
        Haptics.success()
        NotificationCenter.default.post(name: .arTakeScreenshot, object: nil)
        withAnimation(.easeInOut(duration: 0.15)) {
            showScreenshotFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showScreenshotFlash = false
            }
        }
    }

    private func componentDisplayName(for type: SceneType) -> String {
        switch type {
        case .atom:            return "Atom"
        case .battery:         return "Battery"
        case .lightBulb:       return "Bulb"
        case .circuit:         return "Circuit"
        case .resistor:        return "Resistor"
        case .led:             return "LED"
        case .capacitor:       return "Capacitor"
        case .diode:           return "Diode"
        case .switchToggle:    return "Switch"
        case .lightning:       return "Lightning"
        case .seriesCircuit:   return "Series"
        case .parallelCircuit: return "Parallel"
        case .multimeter:      return "Multimeter"
        case .breadboard:      return "Breadboard"
        case .arduino:         return "Arduino"
        case .fuseBox:         return "Fuse"
        }
    }

    private func componentIconName(for type: SceneType) -> String {
        switch type {
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

// MARK: - Notification Names

extension Notification.Name {
    static let arSessionReset = Notification.Name("arSessionReset")
    static let arTakeScreenshot = Notification.Name("arTakeScreenshot")
}

// MARK: - ARSCNView Container (UIViewRepresentable)

struct ARSceneViewContainer: UIViewRepresentable {
    let sessionManager: ARSessionManager
    var onComponentTapped: ((ARPlacedComponent) -> Void)?
    var onSurfaceDetected: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(sessionManager: sessionManager,
                    onComponentTapped: onComponentTapped,
                    onSurfaceDetected: onSurfaceDetected)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.autoenablesDefaultLighting = true
        arView.automaticallyUpdatesLighting = true
        arView.showsStatistics = false

        // Store reference for screenshot and interactions
        context.coordinator.arView = arView

        // Gesture recognizers
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        let pinchGesture = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        arView.addGestureRecognizer(pinchGesture)

        let rotationGesture = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        arView.addGestureRecognizer(rotationGesture)

        let panGesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(panGesture)

        // Allow simultaneous gestures
        tapGesture.delegate = context.coordinator
        pinchGesture.delegate = context.coordinator
        rotationGesture.delegate = context.coordinator
        panGesture.delegate = context.coordinator

        // Start AR session
        sessionManager.startSession(on: arView.session)

        // Observe notifications
        context.coordinator.setupNotificationObservers()

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No-op: state is managed through the coordinator
    }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
        coordinator.removeNotificationObservers()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, ARSCNViewDelegate, UIGestureRecognizerDelegate {
        let sessionManager: ARSessionManager
        var onComponentTapped: ((ARPlacedComponent) -> Void)?
        var onSurfaceDetected: (() -> Void)?
        weak var arView: ARSCNView?

        private var draggedNode: SCNNode?
        private var surfaceNotified = false
        private var resetObserver: NSObjectProtocol?
        private var screenshotObserver: NSObjectProtocol?

        init(sessionManager: ARSessionManager,
             onComponentTapped: ((ARPlacedComponent) -> Void)?,
             onSurfaceDetected: (() -> Void)?) {
            self.sessionManager = sessionManager
            self.onComponentTapped = onComponentTapped
            self.onSurfaceDetected = onSurfaceDetected
        }

        // MARK: Notification Observers

        func setupNotificationObservers() {
            resetObserver = NotificationCenter.default.addObserver(
                forName: .arSessionReset,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.resetSession()
            }

            screenshotObserver = NotificationCenter.default.addObserver(
                forName: .arTakeScreenshot,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.captureScreenshot()
            }
        }

        func removeNotificationObservers() {
            if let observer = resetObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = screenshotObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        private func resetSession() {
            guard let arView else { return }
            // Remove all placed component nodes
            arView.scene.rootNode.childNodes
                .filter { $0.name?.hasPrefix("arComponent_") == true }
                .forEach { $0.removeFromParentNode() }
            // Remove plane visualizations
            arView.scene.rootNode.childNodes
                .filter { $0.name?.hasPrefix("planeOverlay_") == true }
                .forEach { $0.removeFromParentNode() }
            surfaceNotified = false
            sessionManager.resetSession(on: arView.session)
        }

        private func captureScreenshot() {
            guard let arView else { return }
            let _ = sessionManager.captureScreenshot(from: arView)
        }

        // MARK: Gesture Handlers

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = gesture.location(in: arView)

            // First check if tapping an existing component
            let hitResults = arView.hitTest(location, options: [
                .searchMode: SCNHitTestSearchMode.closest.rawValue,
                .boundingBoxOnly: true
            ])

            if let hit = hitResults.first,
               let componentNode = findComponentAncestor(of: hit.node) {
                // Tapped an existing component -- show info
                if let typeName = extractTypeName(from: componentNode.name ?? ""),
                   let sceneType = SceneType(rawValue: typeName) {
                    onComponentTapped?(buildDisplayComponent(type: sceneType, node: componentNode))
                }
                return
            }

            // Otherwise, place a new component on detected surface
            guard let query = arView.raycastQuery(
                from: location,
                allowing: .existingPlaneGeometry,
                alignment: .horizontal
            ) else { return }

            let results = arView.session.raycast(query)
            guard let firstResult = results.first else { return }

            Haptics.medium()
            let node = sessionManager.placeComponent(
                sessionManager.selectedComponentType,
                at: firstResult.worldTransform,
                in: arView
            )
            // Add a subtle entrance animation
            node.scale = SCNVector3(0.01, 0.01, 0.01)
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            node.scale = SCNVector3(2.0, 2.0, 2.0)
            SCNTransaction.commit()
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView else { return }

            switch gesture.state {
            case .changed:
                let location = gesture.location(in: arView)
                let hitResults = arView.hitTest(location, options: [
                    .boundingBoxOnly: true
                ])
                if let hit = hitResults.first,
                   let componentNode = findComponentAncestor(of: hit.node) {
                    let currentScale = componentNode.scale.x
                    let newScale = Float(gesture.scale) * currentScale
                    let clamped = max(0.5, min(5.0, newScale))
                    componentNode.scale = SCNVector3(clamped, clamped, clamped)
                    gesture.scale = 1.0
                }
            default:
                break
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView else { return }

            switch gesture.state {
            case .changed:
                let location = gesture.location(in: arView)
                let hitResults = arView.hitTest(location, options: [
                    .boundingBoxOnly: true
                ])
                if let hit = hitResults.first,
                   let componentNode = findComponentAncestor(of: hit.node) {
                    componentNode.eulerAngles.y -= Float(gesture.rotation)
                    gesture.rotation = 0
                }
            default:
                break
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView else { return }
            let location = gesture.location(in: arView)

            switch gesture.state {
            case .began:
                let hitResults = arView.hitTest(location, options: [
                    .boundingBoxOnly: true
                ])
                if let hit = hitResults.first,
                   let componentNode = findComponentAncestor(of: hit.node) {
                    draggedNode = componentNode
                }

            case .changed:
                guard let node = draggedNode else { return }
                guard let query = arView.raycastQuery(
                    from: location,
                    allowing: .existingPlaneGeometry,
                    alignment: .horizontal
                ) else { return }

                let results = arView.session.raycast(query)
                if let result = results.first {
                    let col = result.worldTransform.columns.3
                    node.simdPosition = SIMD3<Float>(col.x, col.y, col.z)
                }

            case .ended, .cancelled:
                draggedNode = nil

            default:
                break
            }
        }

        // MARK: UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            // Allow pinch + rotation simultaneously
            if (gestureRecognizer is UIPinchGestureRecognizer && other is UIRotationGestureRecognizer) ||
               (gestureRecognizer is UIRotationGestureRecognizer && other is UIPinchGestureRecognizer) {
                return true
            }
            return false
        }

        // MARK: ARSCNViewDelegate

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

            // Visualize detected plane with a translucent overlay
            let width = CGFloat(planeAnchor.planeExtent.width)
            let height = CGFloat(planeAnchor.planeExtent.height)
            let plane = SCNPlane(width: width, height: height)

            let material = SCNMaterial()
            material.diffuse.contents = UIColor(
                red: 0.0, green: 0.5, blue: 1.0, alpha: 0.15
            )
            material.isDoubleSided = true
            plane.materials = [material]

            let planeNode = SCNNode(geometry: plane)
            planeNode.name = "planeOverlay_\(anchor.identifier.uuidString)"
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.position = SCNVector3(
                planeAnchor.center.x,
                0,
                planeAnchor.center.z
            )
            node.addChildNode(planeNode)

            if !surfaceNotified {
                surfaceNotified = true
                DispatchQueue.main.async { [weak self] in
                    self?.onSurfaceDetected?()
                    Haptics.success()
                }
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            guard let planeNode = node.childNodes.first(where: {
                $0.name?.hasPrefix("planeOverlay_") == true
            }) else { return }

            let plane = planeNode.geometry as? SCNPlane
            plane?.width = CGFloat(planeAnchor.planeExtent.width)
            plane?.height = CGFloat(planeAnchor.planeExtent.height)
            planeNode.position = SCNVector3(
                planeAnchor.center.x,
                0,
                planeAnchor.center.z
            )
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            node.childNodes
                .filter { $0.name?.hasPrefix("planeOverlay_") == true }
                .forEach { $0.removeFromParentNode() }
        }

        // MARK: Node Helpers

        /// Walks up the node tree to find the root component node (named "arComponent_...").
        private func findComponentAncestor(of node: SCNNode) -> SCNNode? {
            var current: SCNNode? = node
            while let n = current {
                if n.name?.hasPrefix("arComponent_") == true {
                    return n
                }
                current = n.parent
            }
            return nil
        }

        /// Extracts the SceneType raw value from a component node name.
        private func extractTypeName(from name: String) -> String? {
            // Format: "arComponent_<type>_<uuid>"
            let parts = name.split(separator: "_")
            guard parts.count >= 2 else { return nil }
            return String(parts[1])
        }

        /// Builds an ARPlacedComponent for display from a node.
        private func buildDisplayComponent(type: SceneType, node: SCNNode) -> ARPlacedComponent {
            ARPlacedComponent(
                sceneType: type,
                position: node.simdPosition,
                rotation: node.simdOrientation.vector,
                scale: node.scale.x,
                placedAt: Date()
            )
        }
    }
}

// MARK: - simd_quatf vector helper

private extension simd_quatf {
    var vector: SIMD4<Float> {
        SIMD4<Float>(imag.x, imag.y, imag.z, real)
    }
}

// MARK: - Preview

#Preview {
    ARCircuitView()
}
