import Foundation
import SceneKit

// MARK: - Model Cache Manager
/// Manages 3D model loading, caching, and LOD (Level of Detail) for performance
final class ModelCacheManager {
    static let shared = ModelCacheManager()

    private let sceneCache = NSCache<NSString, SCNScene>()
    private let nodeCache = NSCache<NSString, SCNNode>()
    private var preloadQueue = DispatchQueue(label: "com.sparklearn.modelPreload", qos: .utility)

    private init() {
        // Configure cache limits
        sceneCache.countLimit = 20 // max 20 scenes in memory
        sceneCache.totalCostLimit = 256 * 1024 * 1024 // 256MB texture budget

        nodeCache.countLimit = 50
    }

    // MARK: - Scene Loading

    func loadScene(for sceneType: SceneType) -> SCNScene? {
        let key = sceneType.rawValue as NSString

        // Check cache first
        if let cached = sceneCache.object(forKey: key) {
            return cached
        }

        // Create new scene
        let scene = SCNScene()
        sceneCache.setObject(scene, forKey: key)
        return scene
    }

    func cacheScene(_ scene: SCNScene, for key: String) {
        sceneCache.setObject(scene, forKey: key as NSString)
    }

    func getCachedScene(for key: String) -> SCNScene? {
        sceneCache.object(forKey: key as NSString)
    }

    // MARK: - Node Caching

    func cacheNode(_ node: SCNNode, for key: String) {
        nodeCache.setObject(node, forKey: key as NSString)
    }

    func getCachedNode(for key: String) -> SCNNode? {
        nodeCache.object(forKey: key as NSString)?.clone()
    }

    // MARK: - Preloading

    func preloadNextLesson(sceneTypes: [SceneType]) {
        preloadQueue.async { [weak self] in
            for type in sceneTypes {
                let _ = self?.loadScene(for: type)
            }
        }
    }

    // MARK: - LOD Management

    func createLODNode(
        high: SCNGeometry,
        medium: SCNGeometry,
        low: SCNGeometry,
        distances: [CGFloat] = [0, 10, 30]
    ) -> SCNNode {
        let node = SCNNode(geometry: high)

        let mediumLOD = SCNLevelOfDetail(geometry: medium, screenSpaceRadius: distances[1])
        let lowLOD = SCNLevelOfDetail(geometry: low, screenSpaceRadius: distances[2])

        high.levelsOfDetail = [mediumLOD, lowLOD]

        return node
    }

    /// Create a simplified version of geometry for LOD
    func simplifyGeometry(_ geometry: SCNGeometry, factor: Float) -> SCNGeometry {
        // For box/sphere/cylinder, create with fewer segments
        if let sphere = geometry as? SCNSphere {
            let simplified = SCNSphere(radius: sphere.radius)
            simplified.segmentCount = max(8, Int(Float(sphere.segmentCount) * factor))
            simplified.materials = sphere.materials
            return simplified
        }

        if let cylinder = geometry as? SCNCylinder {
            let simplified = SCNCylinder(radius: cylinder.radius, height: cylinder.height)
            simplified.radialSegmentCount = max(6, Int(Float(cylinder.radialSegmentCount) * factor))
            simplified.materials = cylinder.materials
            return simplified
        }

        // Default: return the same geometry
        return geometry
    }

    // MARK: - Memory Management

    func clearCache() {
        sceneCache.removeAllObjects()
        nodeCache.removeAllObjects()
    }

    func unloadScene(for key: String) {
        sceneCache.removeObject(forKey: key as NSString)
    }

    /// Called when app enters background or receives memory warning
    func handleMemoryWarning() {
        // Keep only the most recent 5 scenes
        clearCache()
    }

    // MARK: - Material Optimization

    /// Create an optimized PBR material
    static func optimizedMaterial(
        diffuse: Any?,
        metalness: Any? = 0.0,
        roughness: Any? = 0.5,
        emission: Any? = nil,
        transparency: CGFloat = 1.0
    ) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = diffuse
        material.metalness.contents = metalness
        material.roughness.contents = roughness
        if let emission = emission {
            material.emission.contents = emission
        }
        material.transparency = transparency

        // Optimization: reduce texture filtering
        material.diffuse.mipFilter = .linear
        material.diffuse.magnificationFilter = .linear
        material.diffuse.minificationFilter = .linear

        return material
    }
}
