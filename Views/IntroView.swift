import SwiftUI

struct IntroView: View {
    var onStart: () -> Void
    @State private var showContent = false
    @State private var hasTappedNeuron = false
    @State private var isPromptPulsing = false
    @State private var tapLocation: CGPoint = .zero
    @State private var isGlowing = false
    
    var body: some View {
        ZStack {
            Color.themeDarkBlue.ignoresSafeArea()
            
            if showContent {
                GeometryReader { geo in
                    ProceduralBrainView(
                        isFrozen: hasTappedNeuron,
                        onNeuronTapped: { location in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                tapLocation = location
                                hasTappedNeuron = true
                            }
                        }
                    )
                    .frame(height: geo.size.height * 0.6)
                    .mask(LinearGradient(colors: [.themeDarkBlue, .themeDarkBlue, .clear], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        ZStack {
                            if hasTappedNeuron {
                                let isNearTop = tapLocation.y < 200
                                let cardX = max(140, min(UIScreen.main.bounds.width - 140, tapLocation.x))
                                let cardY = isNearTop ? tapLocation.y + 140 : tapLocation.y - 140
                                let lineTargetY = isNearTop ? cardY - 65 : cardY + 65
                                
                                Circle()
                                    .fill(Color.themeCream)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: Color.themeCream, radius: 10, x: 0, y: 0)
                                    .position(tapLocation)
                                    .transition(.scale.combined(with: .opacity))
                                
                                Path { path in
                                    path.move(to: tapLocation)
                                    path.addLine(to: CGPoint(x: cardX, y: lineTargetY))
                                }
                                .stroke(Color.themeLightBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .shadow(color: Color.themeLightBlue.opacity(0.8), radius: 5, x: 0, y: 0)
                                .transition(.opacity)
                                
                                VStack(spacing: 12) {
                                    Text("This is a Neuron.")
                                        .font(.headline)
                                        .foregroundStyle(Color.themeCream)
                                    Text("We will talk about these a lot.")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.themeLightBlue)
                                        .multilineTextAlignment(.center)
                                    Button(action: onStart) {
                                        Text("Start")
                                            .font(.headline.bold())
                                            .foregroundColor(.black)
                                            .frame(width: 140, height: 40)
                                            .background(Color.themeBeige)
                                            .clipShape(Capsule())
                                            .shadow(color: Color.themeBeige.opacity(0.4), radius: 5, x: 0, y: 2)
                                    }.padding(.top, 5)
                                }
                                .padding(20)
                                .background(ZStack {
                                    Rectangle().fill(.ultraThinMaterial)
                                    Rectangle().fill(Color.themeDarkBlue.opacity(0.8))
                                })
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.themeCream.opacity(0.4), lineWidth: 1))
                                .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
                                .frame(width: 260)
                                .position(x: cardX, y: cardY)
                                .transition(.scale(
                                    scale: 0.1,
                                    anchor: isNearTop ? UnitPoint(x: 0.5, y: 0.0) : UnitPoint(x: 0.5, y: 1.0)
                                ).combined(with: .opacity))
                            }
                        }
                    )
                    .transition(.opacity)
                    Spacer()
                }
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                if !showContent { Spacer() } else { Spacer().frame(height: UIScreen.main.bounds.height * 0.5) }
                
                ZStack {
                    Rectangle()
                        .fill(Color.themeCream)
                        .mask(Image("BrainLogoYellow").resizable().scaledToFit())
                        .frame(height: 500)
                        .blur(radius: isGlowing ? 30 : 15)
                        .opacity(showContent ? 0.0 : (isGlowing ? 0.6 : 0.2))
                        .padding(.top, -80).padding(.bottom, -85)
                    Image("BrainLogoYellow")
                        .resizable().scaledToFit()
                        .frame(height: 500)
                        .padding(.top, -80).padding(.bottom, -85)
                }
                .scaleEffect(showContent ? 0.7 : 1.0)
                
                if showContent && !hasTappedNeuron {
                    VStack(spacing: 6) {
                        Text("See your brain learn, procrastinate,")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.themeLightBlue)
                            .multilineTextAlignment(.center)
                        Text("and burn out — in 3D.")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.themeLightBlue)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, -70)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    InteractionHint(text: "Touch a bubble to begin", icon: "hand.tap.fill")
                        .opacity(isPromptPulsing ? 1.0 : 0.5)
                        .padding(.top, 0)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever()) { isPromptPulsing = true }
                        }
                }
                
                if !showContent { Spacer() } else { Spacer().frame(height: 70) }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { isGlowing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.5)) { showContent = true }
            }
        }
    }
}
