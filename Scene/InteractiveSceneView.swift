import SwiftUI
import SceneKit

struct InteractiveSceneView: UIViewRepresentable {
    var step: Int
    var topicTitle: String
    @ObservedObject var interactionState: LessonInteractionState
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = UIColor.themeDarkBlue
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        view.scene = SceneFactory.getScene(for: step, topicTitle: topicTitle)
        context.coordinator.currentStep = step
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if context.coordinator.currentStep != step {
            uiView.scene = SceneFactory.getScene(for: step, topicTitle: topicTitle)
            context.coordinator.currentStep = step
        }
        if topicTitle == "How Learning Works" && step == 6 && interactionState.isMyelinAttached {
            if let root = uiView.scene?.rootNode {
                if let myelin = root.childNode(withName: "myelin_sheath", recursively: true) { myelin.isHidden = false }
                if let signal = root.childNode(withName: "signal", recursively: true) {
                    signal.removeAction(forKey: "signal_move")
                    let fastMove = SCNAction.sequence([
                        SCNAction.move(to: SCNVector3(2.5, 0, 0), duration: 0.3), SCNAction.hide(),
                        SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()
                    ])
                    signal.runAction(SCNAction.repeatForever(fastMove), forKey: "signal_move")
                }
            }
        }
        if ((topicTitle == "What is Burnout?" && step == 6) || (topicTitle == "What is Procrastination?" && step == 5)) && interactionState.itemsToClear == 0 {
            if let root = uiView.scene?.rootNode {
                root.enumerateChildNodes { (node, _) in
                    if node.name == "stress" || node.name == "distraction" {
                        node.runAction(.sequence([.fadeOut(duration: 0.5), .removeFromParentNode()]))
                    }
                }
                if let signal = root.childNode(withName: "signal", recursively: true) {
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
    
    @MainActor
    class Coordinator: NSObject {
        var parent: InteractiveSceneView
        var currentStep: Int = -1
        init(_ parent: InteractiveSceneView) { self.parent = parent }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: nil)
            if let hit = hits.first {
                let node = hit.node
                if node.name == "stress" || node.name == "distraction" {
                    node.name = "cleared"
                    node.runAction(.sequence([.scale(to: 1.5, duration: 0.1), .fadeOut(duration: 0.2), .removeFromParentNode()]))
                    if self.parent.interactionState.itemsToClear > 0 {
                        self.parent.interactionState.itemsToClear -= 1
                    }
                }
            }
        }
    }
}
