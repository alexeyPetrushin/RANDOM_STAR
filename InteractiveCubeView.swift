import SwiftUI
import SceneKit

struct InteractiveCubeView: UIViewRepresentable {
    func makeUIView(context: Context) -> InteractiveCubeSceneView {
        InteractiveCubeSceneView()
    }

    func updateUIView(_ view: InteractiveCubeSceneView, context: Context) {}
}

final class InteractiveCubeSceneView: UIView {
    private let sceneView = SCNView(frame: .zero)
    private let cubeNode = SCNNode()
    private var dragStartAngles = SCNVector3Zero

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .black
        setupScene()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        addGestureRecognizer(pan)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sceneView.frame = bounds
    }

    private func setupScene() {
        let scene = SCNScene()
        scene.background.contents = UIColor.black

        sceneView.scene = scene
        sceneView.backgroundColor = .black
        sceneView.antialiasingMode = .multisampling4X
        sceneView.preferredFramesPerSecond = 60
        sceneView.rendersContinuously = true
        sceneView.allowsCameraControl = false
        addSubview(sceneView)

        let box = SCNBox(
            width: 2.4,
            height: 2.4,
            length: 2.4,
            chamferRadius: 0.22
        )
        box.chamferSegmentCount = 8
        box.materials = Self.makeMaterials()
        cubeNode.geometry = box
        cubeNode.eulerAngles = SCNVector3(-0.28, 0.55, 0.08)
        scene.rootNode.addChildNode(cubeNode)

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = 42.0
        camera.position = SCNVector3(0.0, 0.0, 7.2)
        scene.rootNode.addChildNode(camera)
        sceneView.pointOfView = camera

        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1_150
        keyLight.light?.temperature = 5_800
        keyLight.position = SCNVector3(4.0, 5.0, 6.0)
        scene.rootNode.addChildNode(keyLight)

        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.intensity = 520
        fillLight.light?.color = UIColor(red: 0.39, green: 0.25, blue: 1.0, alpha: 1.0)
        fillLight.position = SCNVector3(-4.0, -2.0, 4.0)
        scene.rootNode.addChildNode(fillLight)

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 260
        ambientLight.light?.color = UIColor(white: 0.65, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            cubeNode.removeAnimation(forKey: "release")
            dragStartAngles = cubeNode.presentation.eulerAngles
            cubeNode.eulerAngles = dragStartAngles
            gesture.setTranslation(.zero, in: self)

        case .changed:
            let translation = gesture.translation(in: self)
            let radiansPerPoint: Float = 0.0125

            let yaw = dragStartAngles.y + Float(translation.x) * radiansPerPoint
            let rawPitch = Float(translation.y) * radiansPerPoint
            let pitchLimit: Float = 0.95
            let softenedPitch = rawPitch / (1.0 + abs(rawPitch) / pitchLimit)
            let pitch = Self.clamp(
                dragStartAngles.x + softenedPitch,
                minimum: -1.15,
                maximum: 1.15
            )

            cubeNode.eulerAngles = SCNVector3(pitch, yaw, 0.0)

        case .ended, .cancelled, .failed:
            releaseCube(with: gesture.velocity(in: self))

        default:
            break
        }
    }

    private func releaseCube(with velocity: CGPoint) {
        let current = cubeNode.presentation.eulerAngles
        let fullTurn = Float.pi * 2.0
        let horizontalFlick = abs(velocity.x) > 320.0

        let targetYaw: Float
        if horizontalFlick {
            let direction: Float = velocity.x >= 0.0 ? 1.0 : -1.0
            targetYaw = round(current.y / fullTurn) * fullTurn + direction * fullTurn
        } else {
            targetYaw = round(current.y / fullTurn) * fullTurn
        }

        let target = SCNVector3(0.0, targetYaw, 0.0)
        let yawDistance = max(abs(target.y - current.y), 0.001)
        let angularVelocity = abs(Float(velocity.x) * 0.0125)

        cubeNode.eulerAngles = target

        let spring = CASpringAnimation(keyPath: "eulerAngles")
        spring.fromValue = NSValue(scnVector3: current)
        spring.toValue = NSValue(scnVector3: target)
        spring.mass = 1.0
        spring.stiffness = 28.0
        spring.damping = 7.2
        spring.initialVelocity = CGFloat(min(angularVelocity / yawDistance, 8.0))
        spring.duration = spring.settlingDuration
        cubeNode.addAnimation(spring, forKey: "release")
    }

    private static func clamp(_ value: Float, minimum: Float, maximum: Float) -> Float {
        min(max(value, minimum), maximum)
    }

    private static func makeMaterials() -> [SCNMaterial] {
        let colors: [UIColor] = [
            UIColor(red: 0.39, green: 0.27, blue: 1.00, alpha: 1.0),
            UIColor(red: 0.90, green: 0.25, blue: 0.72, alpha: 1.0),
            UIColor(red: 0.18, green: 0.68, blue: 1.00, alpha: 1.0),
            UIColor(red: 0.55, green: 0.32, blue: 0.95, alpha: 1.0),
            UIColor(red: 0.98, green: 0.42, blue: 0.55, alpha: 1.0),
            UIColor(red: 0.24, green: 0.46, blue: 0.98, alpha: 1.0)
        ]

        return colors.map { color in
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = color
            material.roughness.contents = 0.28
            material.metalness.contents = 0.12
            return material
        }
    }
}

