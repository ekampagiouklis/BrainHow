import SwiftUI

struct InteractionHint: View {
    var text: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption).fontWeight(.bold)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.ultraThinMaterial).clipShape(Capsule())
        .foregroundStyle(Color.themeCream.opacity(0.8))
        .padding(.bottom, 20)
    }
}
