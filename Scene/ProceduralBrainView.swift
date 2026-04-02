import SwiftUI
import SceneKit

struct ProceduralBrainView: UIViewRepresentable {
    var isFrozen: Bool = false
    var onNeuronTapped: ((CGPoint) -> Void)? = nil
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = context.coordinator.generateBrainScene()
        view.allowsCameraControl = !isFrozen
        view.autoenablesDefaultLighting = true
        view.backgroundColor = UIColor.themeDarkBlue
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.allowsCameraControl = !isFrozen
        // Stop the rotation when the view is frozen (e.g. on the onboarding detail screen)
        if isFrozen {
            if let brainNode = uiView.scene?.rootNode.childNode(withName: "MainBrain", recursively: true) {
                brainNode.removeAction(forKey: "rotateAction")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    @MainActor
    class Coordinator: NSObject {
        var parent: ProceduralBrainView
        init(_ parent: ProceduralBrainView) { self.parent = parent }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !parent.isFrozen else { return }
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: nil)
            if let hit = hits.first {
                // Only respond to taps on neuron spheres, not wires or other geometry
                if hit.node.geometry is SCNSphere {
                    let pulse = SCNAction.sequence([SCNAction.scale(to: 1.8, duration: 0.1), SCNAction.scale(to: 1.0, duration: 0.3)])
                    hit.node.runAction(pulse)
                    parent.onNeuronTapped?(location)
                }
            }
        }
        
        func generateBrainScene() -> SCNScene {
            let scene = SCNScene()
            scene.background.contents = UIColor.themeDarkBlue
            let brainNode = SCNNode()
            brainNode.name = "MainBrain"
            let palette: [UIColor] = [.themeLightBlue, .themeBeige, .themeCream]
            let renderQ = UserDefaults.standard.string(forKey: "renderQuality") ?? "Medium"
            let bubbleCount = renderQ == "Low" ? 500 : (renderQ == "High" ? 2000 : 1500)
            var generatedNodes: [SCNNode] = []
            
            for _ in 0...bubbleCount {
                let size = Float.random(in: 0.03...0.08)
                let sphere = SCNSphere(radius: CGFloat(size))
                
                // Blend a random hue with one of the theme colors (60/40) so the brain
                // looks colorful but stays within the app's color palette
                let hue = CGFloat.random(in: 0...1)
                let randomColor = UIColor(hue: hue, saturation: 0.8, brightness: 1.0, alpha: 1.0)
                let tintColor = palette.randomElement() ?? .white
                var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
                randomColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
                var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
                tintColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
                let blendedEmission = UIColor(red: (r1*0.6)+(r2*0.4), green: (g1*0.6)+(g2*0.4), blue: (b1*0.6)+(b2*0.4), alpha: 1.0)
                // Diffuse is darkened to 20% so the glowing emission is what you see
                let blendedDiffuse = UIColor(red: ((r1*0.6)+(r2*0.4))*0.2, green: ((g1*0.6)+(g2*0.4))*0.2, blue: ((b1*0.6)+(b2*0.4))*0.2, alpha: 1.0)
                sphere.firstMaterial?.diffuse.contents = blendedDiffuse
                sphere.firstMaterial?.emission.contents = blendedEmission
                sphere.firstMaterial?.roughness.contents = 0.2
                sphere.firstMaterial?.lightingModel = .physicallyBased
                
                // Each node gets a random phase offset so they don't all pulse in sync
                let pulseDuration = Double.random(in: 1.5...3.0)
                let glowAnim = CABasicAnimation(keyPath: "emission.intensity")
                glowAnim.fromValue = 0.2; glowAnim.toValue = 2.5
                glowAnim.duration = pulseDuration; glowAnim.autoreverses = true
                glowAnim.repeatCount = .infinity
                glowAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                glowAnim.timeOffset = Double.random(in: 0...pulseDuration)
                sphere.firstMaterial?.addAnimation(glowAnim, forKey: "breathingGlow")
                
                let node = SCNNode(geometry: sphere)
                
                // Spherical coordinates place the node in 3D space.
                // pow(volumeRandom, 0.4) biases nodes toward the center so the brain
                // looks naturally denser in the middle rather than hollow.
                let volumeRandom = Float.random(in: 0...1)
                let r = pow(volumeRandom, 0.4) * 1.35
                let theta = Float.random(in: 0...Float.pi * 2)
                let phi = Float.random(in: 0...Float.pi)
                var x = r * sin(phi) * cos(theta) * 0.85
                var y = r * sin(phi) * sin(theta) * 0.75
                let z = r * cos(phi) * 1.15
                // foldOffset adds a subtle wave distortion to mimic the brain's folded surface
                let foldOffset = sin(theta * 6) * cos(phi * 5) * 0.12
                x += x * foldOffset; y += y * foldOffset
                // Push nodes slightly outward on each side to create a gap between hemispheres
                if x > 0 { x += 0.18 } else { x -= 0.18 }
                node.position = SCNVector3(x, y, z)
                brainNode.addChildNode(node)
                generatedNodes.append(node)
            }
            
            // Draw thin wires between nearby nodes to look like neural connections.
            // Each wire tries up to 15 random candidates to find a neighbour at a
            // reasonable distance (0.05–0.4 units) — close enough to look connected,
            // far enough to not overlap.
            let wireCount = renderQ == "Low" ? 500 : (renderQ == "High" ? 2000 : 1500)
            for _ in 0..<wireCount {
                let startIndex = Int.random(in: 0..<generatedNodes.count)
                let startNode = generatedNodes[startIndex]
                var endNode: SCNNode?
                for _ in 0..<15 {
                    let randIndex = Int.random(in: 0..<generatedNodes.count)
                    if randIndex == startIndex { continue }
                    let candidate = generatedNodes[randIndex]
                    let dx = candidate.position.x - startNode.position.x
                    let dy = candidate.position.y - startNode.position.y
                    let dz = candidate.position.z - startNode.position.z
                    let dist = sqrt(dx*dx + dy*dy + dz*dz)
                    if dist > 0.05 && dist < 0.4 { endNode = candidate; break }
                }
                if let endNode = endNode {
                    let v1 = startNode.position, v2 = endNode.position
                    let dist = sqrt(pow(v2.x-v1.x,2)+pow(v2.y-v1.y,2)+pow(v2.z-v1.z,2))
                    let cylinder = SCNCylinder(radius: 0.003, height: CGFloat(dist))
                    cylinder.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
                    let wireColor = palette.randomElement() ?? .themeLightBlue
                    cylinder.firstMaterial?.emission.contents = wireColor.withAlphaComponent(0.6)
                    cylinder.firstMaterial?.lightingModel = .physicallyBased
                    let lineNode = SCNNode(geometry: cylinder)
                    // Position the wire at the midpoint between the two nodes, then rotate it to face the end node
                    lineNode.position = SCNVector3((v1.x+v2.x)/2, (v1.y+v2.y)/2, (v1.z+v2.z)/2)
                    lineNode.look(at: v2, up: scene.rootNode.worldUp, localFront: lineNode.worldUp)
                    brainNode.addChildNode(lineNode)
                }
            }
            
            brainNode.scale = SCNVector3(2.8, 2.8, 2.8)
            brainNode.position = SCNVector3(0, -0.6, 0)
            // One full rotation every 25 seconds — skipped if reduce motion is enabled
            if !UserDefaults.standard.bool(forKey: "reduceMotion") {
                let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 25)
                brainNode.runAction(SCNAction.repeatForever(rotateAction), forKey: "rotateAction")
            }
            scene.rootNode.addChildNode(brainNode)
            
            let keyLight = SCNNode(); keyLight.light = SCNLight()
            keyLight.light?.type = .omni; keyLight.light?.intensity = 1500
            keyLight.light?.color = UIColor.white; keyLight.position = SCNVector3(5, 5, 8)
            scene.rootNode.addChildNode(keyLight)
            let fillLight = SCNNode(); fillLight.light = SCNLight()
            fillLight.light?.type = .omni; fillLight.light?.intensity = 1200
            fillLight.light?.color = UIColor.themeCream; fillLight.position = SCNVector3(-5, -2, 5)
            scene.rootNode.addChildNode(fillLight)
            
            return scene
        }
    }
}
