import SwiftUI

struct ParticleCanvas: View {
    @ObservedObject var simulation: BrainSimulation
    var color: Color
    var connectionDistance: CGFloat
    var lineWidth: CGFloat
    @AppStorage("backgroundAnimations") private var backgroundAnimations = true
    
    var body: some View {
        if backgroundAnimations {
            Canvas { context, size in
                context.blendMode = .plusLighter
                let neurons = simulation.neurons
                for i in 0..<neurons.count {
                    for j in (i + 1)..<neurons.count {
                        let n1 = neurons[i]; let n2 = neurons[j]
                        let dist = hypot(n1.x - n2.x, n1.y - n2.y)
                        if dist < connectionDistance {
                            let opacity = 1.0 - (dist / connectionDistance)
                            var path = Path()
                            path.move(to: CGPoint(x: n1.x, y: n1.y))
                            path.addLine(to: CGPoint(x: n2.x, y: n2.y))
                            context.stroke(path, with: .color(color.opacity(opacity * 0.6)), lineWidth: lineWidth)
                        }
                    }
                }
                for neuron in neurons {
                    let rect = CGRect(x: neuron.x - neuron.size/2, y: neuron.y - neuron.size/2, width: neuron.size, height: neuron.size)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}
