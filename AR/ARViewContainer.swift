import SwiftUI
import ARKit
import SceneKit
import Vision

struct ARViewContainer: UIViewRepresentable {
    @Binding var currentStep: Int
    var topicTitle: String
    @ObservedObject var interactionState: LessonInteractionState
    @Binding var resetPosition: Bool
    var totalSteps: Int
    var onAdvance: () -> Void
    
    @AppStorage("arHighQuality") private var arHighQuality = true
    @AppStorage("arGesturesRotate") private var arGesturesRotate = true
    @AppStorage("arGesturesNext") private var arGesturesNext = true
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.isLightEstimationEnabled = arHighQuality
        config.environmentTexturing = arHighQuality ? .automatic : .none
        arView.session.run(config)
        arView.autoenablesDefaultLighting = true
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleARTap(_:)))
        arView.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        arView.addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        pinch.delegate = context.coordinator
        arView.addGestureRecognizer(pinch)
        let rotate = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))
        rotate.delegate = context.coordinator
        arView.addGestureRecognizer(rotate)
        
        context.coordinator.arView = arView
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        arView.scene = SCNScene()
        context.coordinator.currentStep = -1
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        let stepChanged = context.coordinator.currentStep != currentStep
        context.coordinator.arGesturesRotate = arGesturesRotate
        context.coordinator.arGesturesNext = arGesturesNext
        
        if stepChanged {
            let savedTransform = context.coordinator.containerNode?.simdTransform
            uiView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode() }
            
            let scene = SceneFactory.getScene(for: currentStep, topicTitle: topicTitle)
            let container = SCNNode()
            for child in scene.rootNode.childNodes {
                if child.light == nil { container.addChildNode(child.clone()) }
            }
            container.scale = SCNVector3(0.055, 0.055, 0.055)
            if let saved = savedTransform, context.coordinator.hasInitialPosition {
                container.simdTransform = saved
            }
            context.coordinator.containerNode = container
            uiView.scene.rootNode.addChildNode(container)
            context.coordinator.currentStep = currentStep
        }
        
        if resetPosition {
            context.coordinator.repositionTarget(in: uiView)
            context.coordinator.containerNode?.scale = SCNVector3(0.055, 0.055, 0.055)
            DispatchQueue.main.async { resetPosition = false }
        }
        
        if topicTitle == "How Learning Works" && currentStep == 6 && interactionState.isMyelinAttached {
            if let container = context.coordinator.containerNode {
                if let myelin = container.childNode(withName: "myelin_sheath", recursively: true) {
                    myelin.isHidden = false
                }
                if let signal = container.childNode(withName: "signal", recursively: true) {
                    signal.removeAction(forKey: "signal_move")
                    let fastMove = SCNAction.sequence([
                        SCNAction.move(to: SCNVector3(2.5, 0, 0), duration: 0.3), SCNAction.hide(),
                        SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()
                    ])
                    signal.runAction(SCNAction.repeatForever(fastMove), forKey: "signal_move")
                }
            }
        }
        
        if ((topicTitle == "What is Burnout?" && currentStep == 6) ||
            (topicTitle == "What is Procrastination?" && currentStep == 5)) &&
            interactionState.itemsToClear == 0 {
            if let container = context.coordinator.containerNode {
                container.enumerateChildNodes { (node, _) in
                    if node.name == "stress" || node.name == "distraction" {
                        node.runAction(.sequence([.fadeOut(duration: 0.5), .removeFromParentNode()]))
                    }
                }
                if let signal = container.childNode(withName: "signal", recursively: true) {
                    if signal.action(forKey: "blocked") != nil {
                        signal.removeAction(forKey: "blocked")
                        let move = SCNAction.sequence([
                            SCNAction.move(to: SCNVector3(2.5, 0, 0), duration: 0.8), SCNAction.hide(),
                            SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()
                        ])
                        signal.runAction(SCNAction.repeatForever(move))
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    // Coordinator
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
        var parent: ARViewContainer
        var containerNode: SCNNode?
        var currentStep: Int = -1
        var hasInitialPosition = false
        weak var arView: ARSCNView?
        
        var isProcessingFrame = false
        var arGesturesRotate = true
        var arGesturesNext = true
        var lastSmoothedCenter: CGPoint? = nil
        var nextStepPinchStartTime: Date? = nil
        var isNextStepCooldown = false
        
        init(_ parent: ARViewContainer) { self.parent = parent }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
        
        // Screen Touch Gestures
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let node = containerNode, let view = arView else { return }
            let translation = gesture.translation(in: view)
            let panSensitivity: Float = 0.0005
            SCNTransaction.begin(); SCNTransaction.animationDuration = 0.1
            node.position.x += Float(translation.x) * panSensitivity
            node.position.y -= Float(translation.y) * panSensitivity
            SCNTransaction.commit()
            gesture.setTranslation(.zero, in: view)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let node = containerNode else { return }
            if gesture.state == .changed {
                let scale = Float(gesture.scale)
                SCNTransaction.begin(); SCNTransaction.animationDuration = 0.1
                node.scale = SCNVector3(node.scale.x * scale, node.scale.y * scale, node.scale.z * scale)
                SCNTransaction.commit()
                gesture.scale = 1.0
            }
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let node = containerNode else { return }
            if gesture.state == .changed {
                SCNTransaction.begin(); SCNTransaction.animationDuration = 0.1
                node.eulerAngles.y -= Float(gesture.rotation)
                SCNTransaction.commit()
                gesture.rotation = 0.0
            }
        }
        
        @objc func handleARTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? ARSCNView, let container = containerNode else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [SCNHitTestOption.rootNode: container])
            if let hit = hits.first {
                let node = hit.node
                if node.name == "stress" || node.name == "distraction" {
                    node.name = "cleared"
                    node.runAction(.sequence([.scale(to: 1.5, duration: 0.1), .fadeOut(duration: 0.2), .removeFromParentNode()]))
                    DispatchQueue.main.async {
                        if self.parent.interactionState.itemsToClear > 0 {
                            self.parent.interactionState.itemsToClear -= 1
                        }
                    }
                }
            }
        }
        
        // Placement
        
        func repositionTarget(in view: ARSCNView) {
            guard let container = containerNode, let currentFrame = view.session.currentFrame else { return }
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.6
            translation.columns.3.y = -0.1
            let newTransform = matrix_multiply(currentFrame.camera.transform, translation)
            container.simdPosition = simd_float3(newTransform.columns.3.x, newTransform.columns.3.y, newTransform.columns.3.z)
            container.simdEulerAngles = simd_float3(0, currentFrame.camera.eulerAngles.y, 0)
        }
        
        nonisolated func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            Task { @MainActor in
                guard !self.hasInitialPosition, let view = self.arView,
                      view.session.currentFrame != nil else { return }
                self.repositionTarget(in: view)
                self.hasInitialPosition = true
            }
        }
        
        // Vision Hand Tracking
        
        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Extract the buffer on the ARKit thread before any async hop
            // Using nonisolated(unsafe) to silence the Sendable warning on CVPixelBuffer
            nonisolated(unsafe) let buffer = frame.capturedImage
            
            Task { @MainActor in
                guard !self.isProcessingFrame else { return }
                self.isProcessingFrame = true
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectHumanHandPoseRequest()
                request.maximumHandCount = 1
                let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .right, options: [:])
                try? handler.perform([request])
                let results = request.results
                DispatchQueue.main.async {
                    self.processHand(results?.first)
                    self.isProcessingFrame = false
                }
            }
        }
        
        // Process Hand Pose
        
        func processHand(_ observation: VNHumanHandPoseObservation?) {
            guard
                let observation = observation,
                let thumbTip  = try? observation.recognizedPoint(.thumbTip),
                let indexTip  = try? observation.recognizedPoint(.indexTip),
                let littleTip = try? observation.recognizedPoint(.littleTip),
                thumbTip.confidence  > 0.6,
                indexTip.confidence  > 0.6,
                littleTip.confidence > 0.6,
                let node = containerNode
            else {
                lastSmoothedCenter = nil
                nextStepPinchStartTime = nil
                return
            }
            
            let pinchThreshold: CGFloat = 0.045
            let dIndex = hypot(thumbTip.location.x - indexTip.location.x,  thumbTip.location.y - indexTip.location.y)
            let dPinky = hypot(thumbTip.location.x - littleTip.location.x, thumbTip.location.y - littleTip.location.y)
            let minDist = min(dIndex, dPinky)
            
            if minDist == dPinky && dPinky < pinchThreshold {
                // Thumb + Pinky → Next Step (hold 0.4s)
                if arGesturesNext && !isNextStepCooldown {
                    if nextStepPinchStartTime == nil {
                        nextStepPinchStartTime = Date()
                    } else if Date().timeIntervalSince(nextStepPinchStartTime!) > 0.4 {
                        isNextStepCooldown = true
                        DispatchQueue.main.async {
                            self.parent.onAdvance()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.isNextStepCooldown = false
                        }
                        nextStepPinchStartTime = nil
                        lastSmoothedCenter = nil
                    }
                }
                
            } else if minDist == dIndex && dIndex < pinchThreshold {
                // Thumb + Index → Rotate
                if arGesturesRotate {
                    let center = CGPoint(
                        x: (thumbTip.location.x + indexTip.location.x) / 2,
                        y: (thumbTip.location.y + indexTip.location.y) / 2
                    )
                    let alpha: CGFloat = 0.75
                    let smoothedX = lastSmoothedCenter == nil ? center.x : lastSmoothedCenter!.x * alpha + center.x * (1 - alpha)
                    let smoothedY = lastSmoothedCenter == nil ? center.y : lastSmoothedCenter!.y * alpha + center.y * (1 - alpha)
                    let smoothedCenter = CGPoint(x: smoothedX, y: smoothedY)
                    
                    if let last = lastSmoothedCenter {
                        let dx = Float(smoothedCenter.x - last.x)
                        let dy = Float(smoothedCenter.y - last.y)
                        if abs(dx) > 0.0005 || abs(dy) > 0.0005 {
                            SCNTransaction.begin()
                            SCNTransaction.animationDuration = 0.1
                            node.eulerAngles.y -= dy * 5.0
                            node.eulerAngles.x -= dx * 5.0
                            SCNTransaction.commit()
                        }
                    }
                    lastSmoothedCenter = smoothedCenter
                    nextStepPinchStartTime = nil
                }
                
            } else {
                // Idle
                lastSmoothedCenter = nil
                nextStepPinchStartTime = nil
            }
        }
    }
}
