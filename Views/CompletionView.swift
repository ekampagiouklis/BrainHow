import SwiftUI
import Combine

struct BlurredSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.disabled)
        } else {
            content
        }
    }
}

struct CompletionView: View {
    let topic: LearningTopic
    var onDismiss: () -> Void
    @State private var animateBadge = false
    @ObservedObject var simulation: BrainSimulation
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    var body: some View {
        ZStack {
            Color.themeDarkBlue.ignoresSafeArea()
            
            GeometryReader { geo in
                ParticleCanvas(
                    simulation: simulation,
                    color: topic.color.opacity(0.4),
                    connectionDistance: 130,
                    lineWidth: 1.0
                )
                .onAppear { simulation.setup(width: geo.size.width, height: geo.size.height) }
                .onReceive(timer) { _ in simulation.update(bounds: geo.size) }
            }
            .opacity(0.6)
            
            VStack(spacing: 28) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(topic.color.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateBadge ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true), value: animateBadge)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 68))
                        .foregroundStyle(topic.color)
                        .scaleEffect(animateBadge ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1), value: animateBadge)
                }
                .accessibilityLabel("Lesson complete")
                
                VStack(spacing: 12) {
                    Text("Lesson Complete!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.themeCream)
                    Text(topic.title)
                        .font(.title3.bold())
                        .foregroundStyle(topic.color)
                    
                    Divider()
                        .background(Color.themeCream.opacity(0.2))
                        .padding(.vertical, 4)
                    
                    Text("You now understand your brain")
                        .font(.body)
                        .foregroundStyle(Color.themeLightBlue)
                        .multilineTextAlignment(.center)
                    Text("better than most adults do.")
                        .font(.body.bold())
                        .foregroundStyle(Color.themeLightBlue)
                        .multilineTextAlignment(.center)
                    Text("Keep learning. Keep growing.")
                        .font(.subheadline)
                        .foregroundStyle(Color.themeCream.opacity(0.55))
                        .padding(.top, 4)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
                .background(
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.themeCream.opacity(0.04))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [topic.color.opacity(0.5), topic.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: { onDismiss() }) {
                    Text("Back to Lessons")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .frame(width: 220, height: 56)
                        .background(topic.color)
                        .clipShape(Capsule())
                        .shadow(color: topic.color.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 60)
                .accessibilityLabel("Return to lessons list")
            }
        }
        .onAppear { withAnimation { animateBadge = true } }
        .dynamicTypeSize(.small ... .accessibility2)
        .presentationDragIndicator(.visible)
        .modifier(BlurredSheetModifier())
    }
}
