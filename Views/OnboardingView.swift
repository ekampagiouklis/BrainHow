import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @StateObject var simulation = BrainSimulation()
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "brain.head.profile",
            title: "See Your Brain in 3D",
            description: "See your brain learn, procrastinate, and burn out in 3D. Built by a student, for students.",
            color: .themeLightBlue
        ),
        OnboardingPage(
            icon: "arkit",
            title: "Step Inside Your Mind",
            description: "Place your brain in AR and explore it with your hands. Understand the science behind how you think, focus, and recover.",
            color: .themeBeige
        )
    ]
    
    var body: some View {
        ZStack {
            Color.themeDarkBlue.ignoresSafeArea()
            
            GeometryReader { geo in
                ParticleCanvas(
                    simulation: simulation,
                    color: pages[currentPage].color.opacity(0.3),
                    connectionDistance: 120,
                    lineWidth: 1.0
                )
                .onAppear { simulation.setup(width: geo.size.width, height: geo.size.height) }
                .onReceive(timer) { _ in simulation.update(bounds: geo.size) }
            }
            .opacity(0.5)
            
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .foregroundStyle(Color.themeCream.opacity(0.6))
                        .padding()
                }
                
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            ZStack {
                                Circle()
                                    .fill(pages[index].color.opacity(0.2))
                                    .frame(width: 150, height: 150)
                                Image(systemName: pages[index].icon)
                                    .font(.system(size: 70))
                                    .foregroundStyle(pages[index].color)
                            }
                            .accessibilityHidden(true)
                            
                            Text(pages[index].title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.themeCream)
                            
                            Text(pages[index].description)
                                .font(.title3)
                                .foregroundStyle(Color.themeLightBlue)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 450)
                
                Spacer()
                
                NeuralButton(
                    action: {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            onFinish()
                        }
                    },
                    color: pages[currentPage].color,
                    text: currentPage == pages.count - 1 ? "Let's Go" : "Next"
                )
                .padding(.bottom, 50)
            }
        }
    }
}
