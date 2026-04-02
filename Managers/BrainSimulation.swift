import SwiftUI

class BrainSimulation: ObservableObject {
    @Published var neurons: [Neuron] = []
    
    private var count: Int {
        let quality = UserDefaults.standard.string(forKey: "renderQuality") ?? "Medium"
        return quality == "Low" ? 20 : (quality == "High" ? 60 : 40)
    }
    
    func setup(width: CGFloat, height: CGFloat) {
        neurons.removeAll()
        for _ in 0..<count { spawnNeuron(width: width, height: height) }
    }
    
    func spawnNeuron(width: CGFloat, height: CGFloat) {
        let n = Neuron(
            x: CGFloat.random(in: 0...width),
            y: CGFloat.random(in: 0...height),
            velocityX: CGFloat.random(in: -0.5...0.5),
            velocityY: CGFloat.random(in: -0.5...0.5),
            size: CGFloat.random(in: 2...4)
        )
        neurons.append(n)
    }
    
    func shake() {
        for i in neurons.indices {
            neurons[i].velocityX = CGFloat.random(in: -5...5)
            neurons[i].velocityY = CGFloat.random(in: -5...5)
        }
    }
    
    func update(bounds: CGSize) {
        for i in neurons.indices {
            neurons[i].x += neurons[i].velocityX
            neurons[i].y += neurons[i].velocityY
            if neurons[i].x < 0 || neurons[i].x > bounds.width { neurons[i].velocityX *= -1 }
            if neurons[i].y < 0 || neurons[i].y > bounds.height { neurons[i].velocityY *= -1 }
        }
    }
}
