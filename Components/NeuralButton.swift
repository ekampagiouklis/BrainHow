import SwiftUI

struct NeuralButton: View {
    let action: () -> Void
    let color: Color
    var text: String
    
    var body: some View {
        Button(action: { action() }) {
            ZStack {
                Color.themeDarkBlue.opacity(0.8).clipShape(Capsule())
                    .overlay(Capsule().stroke(color, lineWidth: 1.5))
                HStack(spacing: 10) {
                    Text(text).font(.title3.bold())
                    Image(systemName: "arrow.right").font(.title3.bold())
                }
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(width: 200, height: 60)
        }
    }
}
