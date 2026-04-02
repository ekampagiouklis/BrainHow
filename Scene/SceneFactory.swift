import SceneKit
import UIKit

class SceneFactory {
    
    // Gives a node a glowing bubble look.
    // The diffuse (base color) is darkened to 20% so the glowing emission color
    // stands out visually instead of competing with the surface color.
    static func applyBubbleStyle(to node: SCNNode, baseColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let darkColor = UIColor(red: r * 0.2, green: g * 0.2, blue: b * 0.2, alpha: a)
        let material = SCNMaterial()
        material.diffuse.contents = darkColor
        material.emission.contents = baseColor
        material.roughness.contents = 0.15
        material.metalness.contents = 0.3
        material.lightingModel = .physicallyBased
        node.geometry?.materials = [material]
        
        // Animates the glow brightness up and down to create a breathing pulse effect.
        // timeOffset staggers the start so not all nodes pulse at the same time.
        let pulseDuration = Double.random(in: 2.5...4.0)
        let glowAnim = CABasicAnimation(keyPath: "emission.intensity")
        glowAnim.fromValue = 0.1
        glowAnim.toValue = 0.8
        glowAnim.duration = pulseDuration
        glowAnim.autoreverses = true
        glowAnim.repeatCount = .infinity
        glowAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowAnim.timeOffset = Double.random(in: 0...pulseDuration)
        node.geometry?.firstMaterial?.addAnimation(glowAnim, forKey: "breathingGlow")
    }
    
    // Creates a 3D text label that always faces the camera.
    // The pivot is shifted to the center of the text bounding box so the label
    // rotates around its own middle instead of its bottom-left corner.
    static func createBillboardText(_ string: String, color: UIColor, position: SCNVector3) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.05)
        text.font = UIFont.systemFont(ofSize: 1.0, weight: .bold)
        text.alignmentMode = "center"
        text.firstMaterial?.diffuse.contents = color
        text.firstMaterial?.emission.contents = color
        text.flatness = 0.01
        
        let textNode = SCNNode(geometry: text)
        let (minVec, maxVec) = textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(
            (maxVec.x + minVec.x) / 2,
            (maxVec.y + minVec.y) / 2,
            (maxVec.z + minVec.z) / 2
        )
        
        // Scale the label based on the user's label size preference in Settings
        let sizePref = UserDefaults.standard.string(forKey: "modelLabelSize") ?? "Medium"
        let scale: Float = sizePref == "Small" ? 0.08 : (sizePref == "Large" ? 0.18 : 0.12)
        textNode.scale = SCNVector3(scale, scale, scale)
        
        let wrapperNode = SCNNode()
        wrapperNode.addChildNode(textNode)
        wrapperNode.position = position
        
        // SCNBillboardConstraint makes the node always rotate to face the camera
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = .all
        wrapperNode.constraints = [constraint]
        return wrapperNode
    }
    
    // Spawns 30 gold particles that fly outward and fade — represents a dopamine reward burst
    static func triggerDopamineBurst(on rootNode: SCNNode, at position: SCNVector3) {
        let gold = UIColor(red: 255/255, green: 215/255, blue: 0, alpha: 1.0)
        for _ in 0..<30 {
            let particle = SCNNode(geometry: SCNSphere(radius: 0.08))
            particle.geometry?.firstMaterial?.emission.contents = gold
            particle.position = position
            rootNode.addChildNode(particle)
            let randomX = Float.random(in: -3...3)
            let randomY = Float.random(in: -3...3)
            let randomZ = Float.random(in: -3...3)
            // Move and fade run at the same time using an action group,
            // then the particle removes itself from the scene when done
            let move = SCNAction.moveBy(x: CGFloat(randomX), y: CGFloat(randomY), z: CGFloat(randomZ), duration: 1.2)
            move.timingMode = .easeOut
            let fade = SCNAction.fadeOut(duration: 1.2)
            let group = SCNAction.group([move, fade])
            particle.runAction(SCNAction.sequence([group, SCNAction.removeFromParentNode()]))
        }
    }
    
    // Repeatedly spawns floating "Zzz" text nodes that rise and fade — used for the sleep steps
    static func createZzzFloating(root: SCNNode) {
        let timerAction = SCNAction.wait(duration: 0.8)
        let spawnAction = SCNAction.run { _ in
            let textGeo = SCNText(string: "Zzz", extrusionDepth: 0.1)
            textGeo.font = UIFont.systemFont(ofSize: 0.5, weight: .bold)
            textGeo.firstMaterial?.diffuse.contents = UIColor.white
            textGeo.firstMaterial?.emission.contents = UIColor.themeLightBlue
            let textNode = SCNNode(geometry: textGeo)
            textNode.scale = SCNVector3(0.5, 0.5, 0.5)
            textNode.position = SCNVector3(Float.random(in: -1...1), Float.random(in: -0.5...0.5), 0)
            let floatUp = SCNAction.moveBy(x: 0, y: 3.0, z: 0, duration: 3.0)
            let fadeOut = SCNAction.fadeOut(duration: 3.0)
            let group = SCNAction.group([floatUp, fadeOut])
            textNode.runAction(SCNAction.sequence([group, SCNAction.removeFromParentNode()]))
            root.addChildNode(textNode)
        }
        root.runAction(SCNAction.repeatForever(SCNAction.sequence([timerAction, spawnAction])))
    }
    
    // Creates an invisible glowing sphere used as a soft light ring around a neuron.
    // blendMode .add means the color adds on top of whatever is behind it (glow effect).
    // writesToDepthBuffer false prevents it from blocking other objects visually.
    static func createHalo(color: UIColor, size: CGFloat) -> SCNNode {
        let sphere = SCNSphere(radius: size)
        let node = SCNNode(geometry: sphere)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        material.emission.contents = color
        material.transparency = 0.0
        material.blendMode = .add
        material.isDoubleSided = false
        material.writesToDepthBuffer = false
        node.geometry?.materials = [material]
        return node
    }
    
    // Gently bobs a node up/down and slightly in/out over a very long cycle (8–12 seconds).
    // Each node gets a random wait offset so they never all move in sync.
    private static func addIdleBob(to node: SCNNode) {
        let dy = CGFloat.random(in: 0.015...0.030)
        let dz = CGFloat.random(in: 0.005...0.012)
        let duration = Double.random(in: 8.0...12.0)
        let bob = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: dy, z: dz, duration: duration),
            SCNAction.moveBy(x: 0, y: -dy, z: -dz, duration: duration)
        ])
        let offset = SCNAction.wait(duration: Double.random(in: 0...6.0))
        node.runAction(SCNAction.sequence([offset, SCNAction.repeatForever(bob)]))
    }
    
    // Slowly rocks the axon left and right by less than 1 degree — barely visible but alive
    private static func addIdleSway(to axon: SCNNode) {
        let angle = CGFloat(Float.pi / 200)
        let sway = SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: angle, duration: 9.0),
            SCNAction.rotateBy(x: 0, y: 0, z: -angle, duration: 9.0)
        ])
        axon.runAction(SCNAction.repeatForever(sway))
    }
    
    // Builds the standard two-neuron pair (somaA on the left, somaB on the right)
    // connected by an axon cylinder, with a signal ball that travels between them.
    // @discardableResult means callers can ignore the returned nodes if they don't need them.
    @discardableResult
    static func buildNeuronPair(rootNode: SCNNode) -> (somaA: SCNNode, somaB: SCNNode, axon: SCNNode, signal: SCNNode) {
        let somaA = SCNNode(geometry: SCNSphere(radius: 0.6))
        applyBubbleStyle(to: somaA, baseColor: .themeBeige)
        somaA.position = SCNVector3(-2.5, 0, 0)
        
        let somaB = SCNNode(geometry: SCNSphere(radius: 0.6))
        applyBubbleStyle(to: somaB, baseColor: .themeLightBlue)
        somaB.position = SCNVector3(2.5, 0, 0)
        somaB.name = "receiver_neuron"
        
        // The cylinder is rotated 90° on Z so it lies horizontally between the two neurons
        let cylinder = SCNCylinder(radius: 0.08, height: 5.0)
        let axon = SCNNode(geometry: cylinder)
        axon.eulerAngles.z = Float.pi / 2
        axon.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        
        let signal = SCNNode(geometry: SCNSphere(radius: 0.15))
        signal.geometry?.firstMaterial?.emission.contents = UIColor.themeCream
        signal.position = SCNVector3(-2.5, 0, 0)
        signal.name = "signal"
        
        rootNode.addChildNode(somaA)
        rootNode.addChildNode(somaB)
        rootNode.addChildNode(axon)
        rootNode.addChildNode(signal)
        
        addIdleBob(to: somaA)
        addIdleBob(to: somaB)
        addIdleSway(to: axon)
        
        return (somaA, somaB, axon, signal)
    }
    
    // Returns a looping action that moves the signal from left to right,
    // then instantly teleports it back to the start to repeat — simulates nerve firing
    static func makeSignalLoop(duration: Double) -> SCNAction {
        return SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.move(to: SCNVector3(2.5, 0, 0), duration: duration),
            SCNAction.hide(),
            SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0),
            SCNAction.unhide()
        ]))
    }
    
    // Builds the full brain cloud made of hundreds of small glowing spheres.
    // Node count scales with the render quality setting (Low=250, Medium=600, High=800).
    static func buildBrain(for topicTitle: String, step: Int) -> SCNNode {
        let brainNode = SCNNode()
        let renderQ = UserDefaults.standard.string(forKey: "renderQuality") ?? "Medium"
        let nodeCount = renderQ == "Low" ? 250 : (renderQ == "High" ? 800 : 600)
        
        for _ in 0...nodeCount {
            let size = Float.random(in: 0.03...0.08)
            let sphere = SCNSphere(radius: CGFloat(size))
            
            // Spherical coordinates (r, theta, phi) convert a random point into 3D space.
            // pow(volumeRandom, 0.4) biases nodes toward the center so the brain looks
            // naturally denser in the middle rather than hollow.
            let volumeRandom = Float.random(in: 0...1)
            let r = pow(volumeRandom, 0.4) * 1.35
            let theta = Float.random(in: 0...Float.pi * 2)
            let phi = Float.random(in: 0...Float.pi)
            var x = r * sin(phi) * cos(theta) * 0.85
            let y = r * sin(phi) * sin(theta) * 0.75
            let z = r * cos(phi) * 1.15
            // Push nodes slightly outward on each side to create a visible gap between hemispheres
            if x > 0 { x += 0.18 } else { x -= 0.18 }
            
            var finalColor = UIColor(hue: CGFloat.random(in: 0...1), saturation: CGFloat.random(in: 0.6...1.0), brightness: CGFloat.random(in: 0.8...1.0), alpha: 1.0)
            var isHighlighted = false
            
            // For highlighted steps, only specific brain regions get color — the rest turn dark gray.
            // Burnout step 1 highlights the top-front area (Prefrontal Cortex, z > 0.5).
            // Burnout step 2 highlights the inner core (Amygdala, distance from center < 0.4).
            if topicTitle == "What is Burnout?" {
                if step == 1 { if z > 0.5 { finalColor = .themeLightBlue; isHighlighted = true } }
                else if step == 2 { if sqrt(x*x + y*y + z*z) < 0.4 { finalColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0); isHighlighted = true } }
                if (step == 1 || step == 2) && !isHighlighted { finalColor = UIColor(white: 0.25, alpha: 1.0) }
            } else if topicTitle == "What is Procrastination?" {
                if step == 1 { if z > 0.5 { finalColor = .themeLightBlue; isHighlighted = true } }
                else if step == 2 { if y > 0.3 && z < 0.5 { finalColor = .purple; isHighlighted = true } }
                else if step == 3 { if sqrt(x*x + y*y + z*z) < 0.4 { finalColor = .red; isHighlighted = true } }
                if (step >= 1 && step <= 3) && !isHighlighted { finalColor = UIColor(white: 0.25, alpha: 1.0) }
            }
            
            // Separate the color into a dim diffuse (surface) and a bright emission (glow)
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            finalColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            let blendedEmission = UIColor(red: r1, green: g1, blue: b1, alpha: 1.0)
            let blendedDiffuse = UIColor(red: r1 * 0.2, green: g1 * 0.2, blue: b1 * 0.2, alpha: 1.0)
            
            sphere.firstMaterial?.diffuse.contents = blendedDiffuse
            sphere.firstMaterial?.emission.contents = blendedEmission
            sphere.firstMaterial?.roughness.contents = 0.2
            sphere.firstMaterial?.lightingModel = .physicallyBased
            
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(x, y, z)
            
            // Active or highlighted nodes pulse and drift slowly.
            // Inactive nodes are dimmed and have no glow.
            if step == 0 || isHighlighted || (topicTitle == "How Learning Works" && step == 1) {
                let pulseDuration = Double.random(in: 1.5...3.0)
                let glowAnim = CABasicAnimation(keyPath: "emission.intensity")
                glowAnim.fromValue = 0.2
                glowAnim.toValue = 2.5
                glowAnim.duration = pulseDuration
                glowAnim.autoreverses = true
                glowAnim.repeatCount = .infinity
                glowAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                glowAnim.timeOffset = Double.random(in: 0...pulseDuration)
                sphere.firstMaterial?.addAnimation(glowAnim, forKey: "breathingGlow")
                
                if !UserDefaults.standard.bool(forKey: "reduceMotion") {
                    let driftX = CGFloat.random(in: -0.008...0.008)
                    let driftY = CGFloat.random(in: -0.008...0.008)
                    let driftDuration = Double.random(in: 9.0...14.0)
                    let drift = SCNAction.sequence([
                        SCNAction.moveBy(x: driftX, y: driftY, z: 0, duration: driftDuration),
                        SCNAction.moveBy(x: -driftX, y: -driftY, z: 0, duration: driftDuration)
                    ])
                    node.runAction(SCNAction.repeatForever(drift))
                }
            } else {
                node.opacity = 0.4
                sphere.firstMaterial?.emission.contents = UIColor.clear
            }
            
            brainNode.addChildNode(node)
        }
        return brainNode
    }
    
    // Main entry point — builds the correct scene for the given topic and lesson step.
    // The step number maps directly to the index of the topic's sections array (0 = first section).
    static func getScene(for step: Int, topicTitle: String) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.themeDarkBlue
        let rootNode = SCNNode()
        rootNode.scale = SCNVector3(1.4, 1.4, 1.4)
        
        switch topicTitle {
        case "What is Burnout?":         buildBurnoutScene(step: step, root: rootNode)
        case "What is Procrastination?": buildProcrastinationScene(step: step, root: rootNode)
        case "How Learning Works":       buildLearningScene(step: step, root: rootNode)
        default: break
        }
        
        scene.rootNode.addChildNode(rootNode)
        
        // Slowly rotates the whole scene once every 90 seconds — skipped if reduce motion is on
        if !UserDefaults.standard.bool(forKey: "reduceMotion") {
            let slowSpin = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 90)
            rootNode.runAction(SCNAction.repeatForever(slowSpin), forKey: "idleRotation")
        }
        
        // Two lights: a bright white key light from the front-right, and a softer warm fill from the left
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1500
        keyLight.light?.color = UIColor.white
        keyLight.position = SCNVector3(5, 5, 8)
        scene.rootNode.addChildNode(keyLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.intensity = 1200
        fillLight.light?.color = UIColor.themeCream
        fillLight.position = SCNVector3(-5, -2, 5)
        scene.rootNode.addChildNode(fillLight)
        
        return scene
    }
    
    // Steps 0–2 show the full brain. Step 3 onward switches to the close-up neuron pair view.
    private static func buildBurnoutScene(step: Int, root: SCNNode) {
        if step <= 2 {
            let brainNode = buildBrain(for: "What is Burnout?", step: step)
            if step == 1 {
                brainNode.addChildNode(createBillboardText("Prefrontal Cortex\n(The CEO)", color: .themeLightBlue, position: SCNVector3(0, 1.8, 0.8)))
            } else if step == 2 {
                brainNode.addChildNode(createBillboardText("Amygdala\n(The Alarm)", color: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), position: SCNVector3(0, 1.8, 0.0)))
            }
            brainNode.scale = SCNVector3(1.3, 1.3, 1.3)
            root.addChildNode(brainNode)
        } else {
            let (somaA, somaB, axon, signal) = buildNeuronPair(rootNode: root)
            
            // Step 3: healthy fast signal
            if step == 3 {
                signal.runAction(makeSignalLoop(duration: 0.8))
            }
            // Step 4: early stress — signal slows, a few red hormone particles appear
            if step == 4 {
                signal.runAction(makeSignalLoop(duration: 1.2))
                for _ in 0..<5 {
                    let p = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.05...0.1)))
                    p.geometry?.firstMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.8)
                    p.position = SCNVector3(Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
                    let floatMove = SCNAction.moveBy(x: CGFloat.random(in: -0.5...0.5), y: CGFloat.random(in: -0.5...0.5), z: CGFloat.random(in: -0.5...0.5), duration: Double.random(in: 1...2))
                    floatMove.timingMode = .easeInEaseOut
                    p.runAction(SCNAction.repeatForever(SCNAction.sequence([floatMove, floatMove.reversed()])))
                    root.addChildNode(p)
                }
            }
            // Step 5: heavy hormone flood — more particles, signal noticeably slower
            if step == 5 {
                signal.runAction(makeSignalLoop(duration: 2.0))
                for _ in 0..<15 {
                    let p = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.05...0.1)))
                    p.geometry?.firstMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.8)
                    p.position = SCNVector3(Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
                    let floatMove = SCNAction.moveBy(x: CGFloat.random(in: -0.5...0.5), y: CGFloat.random(in: -0.5...0.5), z: CGFloat.random(in: -0.5...0.5), duration: Double.random(in: 1...2))
                    floatMove.timingMode = .easeInEaseOut
                    p.runAction(SCNAction.repeatForever(SCNAction.sequence([floatMove, floatMove.reversed()])))
                    root.addChildNode(p)
                }
            }
            // Step 6: signal gets blocked midway — tappable stress particles fill the synapse gap
            if step == 6 {
                let move = SCNAction.move(to: SCNVector3(0.0, 0, 0), duration: 1.0)
                let fade = SCNAction.fadeOut(duration: 0.2)
                let reset = SCNAction.sequence([SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()])
                signal.runAction(SCNAction.repeatForever(SCNAction.sequence([move, fade, SCNAction.wait(duration: 0.5), reset])), forKey: "blocked")
                for _ in 0..<30 {
                    let p = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.08...0.18)))
                    p.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
                    p.geometry?.firstMaterial?.emission.contents = UIColor.red.withAlphaComponent(0.9)
                    p.position = SCNVector3(Float.random(in: -0.5...1.5), Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
                    p.name = "stress"
                    root.addChildNode(p)
                }
            }
            // Step 7: the sending neuron (somaA) and axon shrink — PFC grey matter loss
            if step == 7 {
                signal.isHidden = true
                somaA.runAction(SCNAction.scale(to: 0.4, duration: 1.5))
                axon.runAction(SCNAction.scale(to: 0.5, duration: 1.5))
                axon.runAction(SCNAction.fadeOpacity(to: 0.4, duration: 1.5))
            }
            // Step 8: the receiving neuron (somaB/Amygdala) grows and turns red — it's enlarging
            if step == 8 {
                signal.isHidden = true
                somaA.scale = SCNVector3(0.4, 0.4, 0.4)
                axon.scale = SCNVector3(0.5, 0.5, 0.5)
                axon.opacity = 0.4
                somaB.runAction(SCNAction.scale(to: 1.6, duration: 1.5))
                // customAction lets us animate the color over time by calculating it per frame
                let colorChange = SCNAction.customAction(duration: 1.5) { node, elapsedTime in
                    let percentage = elapsedTime / 1.5
                    node.geometry?.firstMaterial?.emission.contents = UIColor(red: 1.0, green: 0.2*(1-percentage), blue: 0.2*(1-percentage), alpha: 1.0)
                }
                somaB.runAction(colorChange)
                let pulse = SCNAction.sequence([SCNAction.scale(to: 1.7, duration: 0.1), SCNAction.scale(to: 1.5, duration: 0.3)])
                somaB.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.wait(duration: 1.0), pulse])))
            }
            // Step 9: brain fog — gray particles drift across the scene
            if step == 9 {
                signal.isHidden = true
                somaA.scale = SCNVector3(0.4, 0.4, 0.4)
                somaB.scale = SCNVector3(1.6, 1.6, 1.6)
                somaB.geometry?.firstMaterial?.emission.contents = UIColor.red
                axon.scale = SCNVector3(0.5, 0.5, 0.5)
                axon.opacity = 0.2
                for _ in 0..<40 {
                    let fog = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.05...0.2)))
                    fog.geometry?.firstMaterial?.emission.contents = UIColor.gray.withAlphaComponent(0.6)
                    fog.position = SCNVector3(Float.random(in: -3.0...3.0), Float.random(in: -2.0...2.0), Float.random(in: -1.0...1.0))
                    let floatMove = SCNAction.moveBy(x: CGFloat.random(in: -0.2...0.2), y: CGFloat.random(in: -0.5...0.5), z: 0, duration: Double.random(in: 2...4))
                    floatMove.timingMode = .easeInEaseOut
                    fog.runAction(SCNAction.repeatForever(SCNAction.sequence([floatMove, floatMove.reversed()])))
                    root.addChildNode(fog)
                }
            }
            // Step 10: everything fades out — representing total burnout / emotional numbness
            if step == 10 {
                signal.isHidden = true
                somaA.scale = SCNVector3(0.4, 0.4, 0.4)
                somaB.scale = SCNVector3(1.6, 1.6, 1.6)
                somaB.geometry?.firstMaterial?.emission.contents = UIColor.red
                axon.scale = SCNVector3(0.5, 0.5, 0.5)
                somaA.runAction(SCNAction.fadeOpacity(to: 0.2, duration: 2.0))
                somaB.runAction(SCNAction.fadeOpacity(to: 0.2, duration: 2.0))
                axon.runAction(SCNAction.fadeOpacity(to: 0.0, duration: 2.0))
            }
            // Step 11: recovery — everything fades back in, signal returns, dopamine bursts fire
            if step == 11 {
                somaA.scale = SCNVector3(0.4, 0.4, 0.4)
                somaB.scale = SCNVector3(1.6, 1.6, 1.6)
                axon.scale = SCNVector3(0.5, 0.5, 0.5)
                axon.opacity = 0.0
                somaA.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 2.0))
                somaB.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 2.0))
                somaA.runAction(SCNAction.scale(to: 1.0, duration: 2.0))
                somaB.runAction(SCNAction.scale(to: 1.0, duration: 2.0))
                applyBubbleStyle(to: somaB, baseColor: .themeLightBlue)
                axon.runAction(SCNAction.scale(to: 1.0, duration: 2.0))
                axon.runAction(SCNAction.fadeOpacity(to: 1.0, duration: 2.0))
                createZzzFloating(root: root)
                signal.runAction(makeSignalLoop(duration: 0.8))
                let burstAction = SCNAction.run { _ in
                    SceneFactory.triggerDopamineBurst(on: root, at: somaB.position)
                    let scaleUp = SCNAction.scale(to: 1.3, duration: 0.15)
                    let scaleDown = SCNAction.scale(to: 1.0, duration: 0.4)
                    somaB.runAction(SCNAction.sequence([scaleUp, scaleDown]))
                }
                root.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.wait(duration: 2.0), burstAction])))
            }
        }
    }
    
    // Steps 0–3 show the full brain with highlighted regions.
    // Step 4 onward switches to the neuron pair view.
    private static func buildProcrastinationScene(step: Int, root: SCNNode) {
        if step <= 3 {
            let brainNode = buildBrain(for: "What is Procrastination?", step: step)
            if step == 1 {
                brainNode.addChildNode(createBillboardText("Prefrontal Cortex\n(Focus)", color: .themeLightBlue, position: SCNVector3(0, 1.8, 0.8)))
            } else if step == 2 {
                brainNode.addChildNode(createBillboardText("Default Mode Network\n(Daydreaming)", color: .purple, position: SCNVector3(0, 1.8, -0.5)))
            } else if step == 3 {
                brainNode.addChildNode(createBillboardText("Amygdala\n(Threat Detector)", color: UIColor.red, position: SCNVector3(0, 1.8, 0.0)))
            }
            brainNode.scale = SCNVector3(1.3, 1.3, 1.3)
            root.addChildNode(brainNode)
        } else {
            // somaA and axon are built by buildNeuronPair but not needed here, so they're ignored with _
            let (_, somaB, _, signal) = buildNeuronPair(rootNode: root)
            
            // Step 4: mind-wandering — purple fog clouds drift around the signal
            if step == 4 {
                signal.runAction(makeSignalLoop(duration: 2.0))
                for _ in 0..<15 {
                    let fog = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.1...0.3)))
                    fog.geometry?.firstMaterial?.emission.contents = UIColor.purple.withAlphaComponent(0.6)
                    fog.position = SCNVector3(Float.random(in: -3.0...1.0), Float.random(in: -1.5...1.5), Float.random(in: -1.0...1.0))
                    let floatMove = SCNAction.moveBy(x: CGFloat.random(in: -0.5...0.5), y: CGFloat.random(in: -0.5...0.5), z: 0, duration: Double.random(in: 2...4))
                    floatMove.timingMode = .easeInEaseOut
                    fog.runAction(SCNAction.repeatForever(SCNAction.sequence([floatMove, floatMove.reversed()])))
                    root.addChildNode(fog)
                }
            }
            // Step 5: distractions block the signal — colorful tappable spheres fill the scene
            if step == 5 {
                somaB.geometry?.firstMaterial?.emission.contents = UIColor.red
                let move = SCNAction.move(to: SCNVector3(0.0, 0, 0), duration: 1.0)
                let fade = SCNAction.fadeOut(duration: 0.2)
                let reset = SCNAction.sequence([SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()])
                signal.runAction(SCNAction.repeatForever(SCNAction.sequence([move, fade, SCNAction.wait(duration: 0.5), reset])), forKey: "blocked")
                for _ in 0..<30 {
                    let p = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.1...0.25)))
                    p.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
                    p.geometry?.firstMaterial?.emission.contents = UIColor(hue: CGFloat.random(in: 0...1), saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    p.position = SCNVector3(Float.random(in: -0.5...1.5), Float.random(in: -1.5...1.5), Float.random(in: -1.0...1.0))
                    p.name = "distraction"
                    root.addChildNode(p)
                }
            }
            // Steps 6 and 8 both show the signal being blocked (same vicious loop state)
            if step == 6 || step == 8 {
                somaB.geometry?.firstMaterial?.emission.contents = UIColor.red
                let move = SCNAction.move(to: SCNVector3(0.0, 0, 0), duration: 1.0)
                let fade = SCNAction.fadeOut(duration: 0.2)
                let reset = SCNAction.sequence([SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0), SCNAction.unhide()])
                signal.runAction(SCNAction.repeatForever(SCNAction.sequence([move, fade, SCNAction.wait(duration: 0.5), reset])))
            }
            // Steps 9–10: breaking the loop — signal is very slow at first, then somaB transitions
            // from red back to the theme blue color, showing the Amygdala calming down
            if step == 9 || step == 10 {
                somaB.geometry?.firstMaterial?.emission.contents = UIColor.red
                signal.runAction(makeSignalLoop(duration: 3.0))
                if step == 10 {
                    let colorChange = SCNAction.customAction(duration: 2.0) { node, elapsedTime in
                        let percentage = elapsedTime / 2.0
                        let r = 1.0 - (1.0 - 172.0/255.0) * percentage
                        let g = 0.0 + (186.0/255.0) * percentage
                        let b = 0.0 + (196.0/255.0) * percentage
                        node.geometry?.firstMaterial?.emission.contents = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                    }
                    somaB.runAction(colorChange)
                }
            }
            // Step 11: focus restored — fast signal and repeating dopamine bursts
            if step == 11 {
                signal.runAction(makeSignalLoop(duration: 0.8))
                let burstAction = SCNAction.run { _ in
                    SceneFactory.triggerDopamineBurst(on: root, at: somaB.position)
                    let scaleUp = SCNAction.scale(to: 1.3, duration: 0.15)
                    let scaleDown = SCNAction.scale(to: 1.0, duration: 0.4)
                    somaB.runAction(SCNAction.sequence([scaleUp, scaleDown]))
                }
                root.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.wait(duration: 2.0), burstAction])))
            }
        }
    }
    
    // Each case matches a lesson step number (0 = first slide, 11 = last slide).
    // The default case handles steps 2–7 which all use the standard neuron pair layout.
    private static func buildLearningScene(step: Int, root: SCNNode) {
        switch step {
            
            // Step 0: intro — one receiver neuron on the right, 5 senders on the left firing signals
        case 0:
            let receiver = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: receiver, baseColor: .themeBeige)
            receiver.position = SCNVector3(2.0, 0, 0)
            root.addChildNode(receiver)
            addIdleBob(to: receiver)
            
            let yPositions: [Float] = [2.0, 1.0, 0.0, -1.0, -2.0]
            for i in 0..<5 {
                let sender = SCNNode(geometry: SCNSphere(radius: 0.3))
                applyBubbleStyle(to: sender, baseColor: .themeLightBlue)
                sender.position = SCNVector3(-2.5, yPositions[i], 0)
                root.addChildNode(sender)
                addIdleBob(to: sender)
                
                // A thin faint cylinder connects each sender to the receiver visually
                let cylinder = SCNCylinder(radius: 0.02, height: 4.8)
                let link = SCNNode(geometry: cylinder)
                link.position = SCNVector3(-0.25, yPositions[i] * 0.5, 0)
                link.look(at: receiver.position, up: root.worldUp, localFront: link.worldUp)
                link.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
                root.addChildNode(link)
                
                let signal = SCNNode(geometry: SCNSphere(radius: 0.1))
                signal.geometry?.firstMaterial?.emission.contents = UIColor.themeCream
                signal.position = sender.position
                root.addChildNode(signal)
                
                // Each signal gets a slightly different travel speed so they don't all arrive at once
                let duration = Double.random(in: 0.8...1.2)
                let move = SCNAction.sequence([
                    SCNAction.move(to: receiver.position, duration: duration),
                    SCNAction.hide(),
                    SCNAction.move(to: sender.position, duration: 0),
                    SCNAction.unhide(),
                    SCNAction.wait(duration: Double.random(in: 0...0.5))
                ])
                signal.runAction(SCNAction.repeatForever(move))
            }
            
            // Step 1: the full colorful brain — all neurons active and pulsing
        case 1:
            let brainNode = buildBrain(for: "How Learning Works", step: step)
            brainNode.scale = SCNVector3(1.3, 1.3, 1.3)
            root.addChildNode(brainNode)
            
            // Step 8: synaptic pruning — weak gray connections fade out, strong halos appear
        case 8:
            let somaA8 = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaA8, baseColor: .themeBeige)
            somaA8.position = SCNVector3(-2.0, 0, 0)
            let haloA = createHalo(color: .themeCream, size: 0.85)
            somaA8.addChildNode(haloA)
            root.addChildNode(somaA8)
            addIdleBob(to: somaA8)
            
            let somaB8 = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaB8, baseColor: .themeLightBlue)
            somaB8.position = SCNVector3(2.0, 0, 0)
            let haloB = createHalo(color: .themeLightBlue, size: 0.85)
            somaB8.addChildNode(haloB)
            root.addChildNode(somaB8)
            addIdleBob(to: somaB8)
            
            let mainLink8 = SCNNode(geometry: SCNCylinder(radius: 0.08, height: 4.0))
            mainLink8.geometry?.firstMaterial?.emission.contents = UIColor.themeCream
            mainLink8.eulerAngles.z = Float.pi / 2
            root.addChildNode(mainLink8)
            addIdleSway(to: mainLink8)
            
            // Dim gray nodes with weak lines represent unused connections being pruned
            let noiseNode = SCNNode()
            for _ in 0..<5 {
                let n = SCNNode(geometry: SCNSphere(radius: 0.3))
                n.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
                n.geometry?.firstMaterial?.emission.contents = UIColor.darkGray
                n.position = SCNVector3(Float.random(in: -3...3), Float.random(in: -2...2), Float.random(in: -1...1))
                if abs(n.position.x) < 1.0 { n.position.y += 2.0 }
                noiseNode.addChildNode(n)
                let weakLine = SCNNode(geometry: SCNCylinder(radius: 0.01, height: 3.0))
                weakLine.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
                weakLine.position = SCNVector3(n.position.x/2, n.position.y/2, n.position.z/2)
                weakLine.look(at: SCNVector3(0, 0, 0), up: root.worldUp, localFront: weakLine.worldUp)
                noiseNode.addChildNode(weakLine)
            }
            root.addChildNode(noiseNode)
            
            // After 1 second, the weak connections fade out and the halos fade in
            let wait8 = SCNAction.wait(duration: 1.0)
            noiseNode.runAction(SCNAction.sequence([wait8, SCNAction.fadeOut(duration: 2.5)]))
            haloA.runAction(SCNAction.sequence([wait8, SCNAction.fadeOpacity(to: 0.6, duration: 2.5)]))
            haloB.runAction(SCNAction.sequence([wait8, SCNAction.fadeOpacity(to: 0.6, duration: 2.5)]))
            
            // Steps 9 and 10: sleep — two idle neurons with floating Zzz text
        case 9, 10:
            let somaA9 = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaA9, baseColor: .themeBeige)
            somaA9.position = SCNVector3(-2.5, 0, 0)
            root.addChildNode(somaA9)
            addIdleBob(to: somaA9)
            
            let somaB9 = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaB9, baseColor: .themeLightBlue)
            somaB9.position = SCNVector3(2.5, 0, 0)
            root.addChildNode(somaB9)
            addIdleBob(to: somaB9)
            createZzzFloating(root: root)
            
            // Step 11: dopamine / the save button — gold neurons, repeating burst every 2 seconds
        case 11:
            let somaA11 = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaA11, baseColor: .themeBeige)
            somaA11.position = SCNVector3(-2.5, 0, 0)
            root.addChildNode(somaA11)
            addIdleBob(to: somaA11)
            
            let somaB11 = SCNNode(geometry: SCNSphere(radius: 0.6))
            let gold = UIColor(red: 255/255, green: 215/255, blue: 0, alpha: 1.0)
            applyBubbleStyle(to: somaB11, baseColor: gold)
            somaB11.position = SCNVector3(2.5, 0, 0)
            somaB11.name = "receiver_neuron"
            root.addChildNode(somaB11)
            addIdleBob(to: somaB11)
            
            let cylinder11 = SCNCylinder(radius: 0.12, height: 5.0)
            let axon11 = SCNNode(geometry: cylinder11)
            axon11.eulerAngles.z = Float.pi / 2
            axon11.geometry?.firstMaterial?.emission.contents = gold.withAlphaComponent(0.5)
            root.addChildNode(axon11)
            addIdleSway(to: axon11)
            
            let burstAction11 = SCNAction.run { _ in
                SceneFactory.triggerDopamineBurst(on: root, at: somaB11.position)
                let scaleUp = SCNAction.scale(to: 1.3, duration: 0.15)
                let scaleDown = SCNAction.scale(to: 1.0, duration: 0.4)
                somaB11.runAction(SCNAction.sequence([scaleUp, scaleDown]))
            }
            root.runAction(SCNAction.repeatForever(SCNAction.sequence([SCNAction.wait(duration: 2.0), burstAction11])))
            
            // Default: handles steps 2–7 — standard neuron pair with step-specific additions
        default:
            let somaA = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaA, baseColor: .themeBeige)
            somaA.position = SCNVector3(-2.5, 0, 0)
            root.addChildNode(somaA)
            addIdleBob(to: somaA)
            
            let somaB = SCNNode(geometry: SCNSphere(radius: 0.6))
            applyBubbleStyle(to: somaB, baseColor: .themeLightBlue)
            somaB.position = SCNVector3(2.5, 0, 0)
            somaB.name = "receiver_neuron"
            root.addChildNode(somaB)
            addIdleBob(to: somaB)
            
            let cylinderD = SCNCylinder(radius: 0.08, height: 5.0)
            let axon = SCNNode(geometry: cylinderD)
            axon.eulerAngles.z = Float.pi / 2
            axon.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            root.addChildNode(axon)
            addIdleSway(to: axon)
            
            // Step 2: synapse gap — axon fades out, a particle floats across the gap
            if step == 2 {
                axon.opacity = 0.1
                let particles = SCNNode(geometry: SCNSphere(radius: 0.1))
                particles.geometry?.firstMaterial?.emission.contents = UIColor.themeCream
                particles.position = SCNVector3(0, 0, 0)
                particles.runAction(SCNAction.repeatForever(SCNAction.moveBy(x: 0.5, y: 0, z: 0, duration: 0.5)))
                root.addChildNode(particles)
            }
            // Step 3: synaptic plasticity — the axon pulses thick then thin to show the connection strengthening
            if step == 3 {
                let thick = SCNAction.scale(to: 3.0, duration: 1.0)
                let thin = SCNAction.scale(to: 1.0, duration: 1.0)
                axon.runAction(SCNAction.repeatForever(SCNAction.sequence([thick, thin])))
            }
            // Step 5: glial support cells — green spheres float around the connection
            if step == 5 {
                for _ in 0..<5 {
                    let glial = SCNNode(geometry: SCNSphere(radius: 0.15))
                    glial.geometry?.firstMaterial?.emission.contents = UIColor.green.withAlphaComponent(0.8)
                    glial.position = SCNVector3(Float.random(in: -1.5...1.5), Float.random(in: -1.0...1.0), Float.random(in: -1.0...1.0))
                    let move1 = SCNAction.moveBy(x: CGFloat.random(in: -0.5...0.5), y: CGFloat.random(in: -0.5...0.5), z: 0, duration: Double.random(in: 1.5...3.0))
                    move1.timingMode = .easeInEaseOut
                    glial.runAction(SCNAction.repeatForever(SCNAction.sequence([move1, move1.reversed()])))
                    root.addChildNode(glial)
                }
            }
            // Step 6: myelin sheath — 5 segments spaced along the axon, hidden until the user drags myelin on
            if step == 6 {
                let myelinGroup = SCNNode()
                myelinGroup.name = "myelin_sheath"
                myelinGroup.isHidden = true
                for i in 0..<5 {
                    let sGeo = SCNCylinder(radius: 0.12, height: 0.6)
                    let sNode = SCNNode(geometry: sGeo)
                    sNode.eulerAngles.z = Float.pi / 2
                    applyBubbleStyle(to: sNode, baseColor: .themeCream)
                    sNode.geometry?.firstMaterial?.diffuse.contents = UIColor.themeCream
                    let posX = -2.0 + (Float(i) * 1.0) + 0.5
                    sNode.position = SCNVector3(posX, 0, 0)
                    myelinGroup.addChildNode(sNode)
                }
                root.addChildNode(myelinGroup)
            }
            // Signal is skipped on step 2 because the synapse gap is the focus, not a full signal
            if step != 2 {
                let signal = SCNNode(geometry: SCNSphere(radius: 0.15))
                signal.geometry?.firstMaterial?.emission.contents = UIColor.themeCream
                signal.position = SCNVector3(-2.5, 0, 0)
                signal.name = "signal"
                root.addChildNode(signal)
                
                // Steps 4–5 use a faster signal (myelination forming), steps 7+ use the fastest (full myelin)
                let moveSpeed = (step >= 4 && step <= 5) ? 0.8 : (step >= 7 ? 0.3 : 1.5)
                let move = SCNAction.sequence([
                    SCNAction.move(to: SCNVector3(2.5, 0, 0), duration: moveSpeed),
                    SCNAction.run { _ in },
                    SCNAction.hide(),
                    SCNAction.move(to: SCNVector3(-2.5, 0, 0), duration: 0),
                    SCNAction.unhide()
                ])
                signal.runAction(SCNAction.repeatForever(move), forKey: "signal_move")
            }
        }
    }
}
