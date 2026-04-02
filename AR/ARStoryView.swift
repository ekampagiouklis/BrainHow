import SwiftUI

struct ARStoryView: View {
    let topic: LearningTopic
    @Binding var currentStep: Int
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userProgress: UserProgress
    
    @StateObject private var interactionState = LessonInteractionState()
    @State private var myelinOffset: CGSize = .zero
    @AppStorage("arTextEnabled") private var arTextEnabled = true
    @State private var resetPosition: Bool = false
    @State private var showARHint: Bool = true
    @State private var showCompletionScreen = false
    @StateObject private var completionSimulation = BrainSimulation()
    private let completionTimer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var isLastStep: Bool { currentStep == topic.sections.count - 1 }
    
    var body: some View {
        ZStack {
            ARViewContainer(
                currentStep: $currentStep,
                topicTitle: topic.title,
                interactionState: interactionState,
                resetPosition: $resetPosition,
                totalSteps: topic.sections.count,
                onAdvance: { self.handleAdvance() }
            )

            .edgesIgnoringSafeArea(.all)
            .accessibilityLabel("AR Camera View")
            
            if topic.title == "What is Burnout?" && currentStep == 6 && interactionState.itemsToClear > 0 {
                VStack {
                    InteractionHint(text: "Tap Cortisol to Clear: \(interactionState.itemsToClear)", icon: "hand.tap.fill").padding(.top, 100)
                    Spacer()
                }
            } else if topic.title == "What is Procrastination?" && currentStep == 5 && interactionState.itemsToClear > 0 {
                VStack {
                    InteractionHint(text: "Tap Distractions to Focus: \(interactionState.itemsToClear)", icon: "hand.tap.fill").padding(.top, 100)
                    Spacer()
                }
            } else if topic.title == "How Learning Works" && currentStep == 6 && !interactionState.isMyelinAttached {
                VStack {
                    InteractionHint(text: "Drag Myelin Up to Connect!", icon: "arrow.up").padding(.top, 100)
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Text("AR Mode")
                        .font(.caption).bold()
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(5)
                        .foregroundColor(Color.themeCream)
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) { showARHint = true }
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2).bold()
                            .foregroundColor(Color.themeCream)
                            .padding(12)
                            .background(Color.themeDarkBlue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 5)
                    .accessibilityLabel("Show AR Guide")
                    
                    Button(action: { resetPosition = true }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2).bold()
                            .foregroundColor(Color.themeCream)
                            .padding(12)
                            .background(Color.themeDarkBlue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 5)
                    .accessibilityLabel("Reset AR Position")
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2).bold()
                            .foregroundColor(Color.themeCream)
                            .padding(12)
                            .background(Color.themeDarkBlue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Exit AR Mode")
                }
                .padding(.top, 50)
                .padding(.horizontal)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 15) {
                    let section = topic.sections[currentStep]
                    HStack {
                        if let title = section.title, arTextEnabled {
                            Text(title).font(.title2).bold().foregroundStyle(Color.themeCream)
                        }
                        Spacer()
                        CircularProgressView(
                            progress: Double(currentStep + 1) / Double(topic.sections.count),
                            color: Color.themeLightBlue
                        )
                    }
                    if arTextEnabled {
                        Text(LocalizedStringKey(section.content))
                            .font(.body)
                            .foregroundStyle(Color.themeCream.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    
                    HStack {
                        if currentStep > 0 {
                            Button(action: {
                                interactionState.reset()
                                myelinOffset = .zero
                                withAnimation(.easeInOut(duration: 0.3)) { currentStep -= 1 }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.title3).bold()
                                    .foregroundStyle(Color.themeCream)
                                    .frame(width: 50, height: 50)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.themeCream.opacity(0.3), lineWidth: 1))
                            }
                        }
                        
                        if topic.title == "How Learning Works" && currentStep == 6 && !interactionState.isMyelinAttached {
                            Spacer()
                            Image(systemName: "capsule.fill")
                                .resizable().frame(width: 60, height: 25)
                                .foregroundStyle(Color.themeCream)
                                .offset(myelinOffset)
                                .gesture(DragGesture()
                                    .onChanged { value in myelinOffset = value.translation }
                                    .onEnded { value in
                                        if value.translation.height < -50 {
                                            withAnimation { interactionState.isMyelinAttached = true }
                                        } else {
                                            withAnimation(.spring()) { myelinOffset = .zero }
                                        }
                                    })
                            Spacer()
                        } else if topic.title == "What is Burnout?" && currentStep == 6 && interactionState.itemsToClear > 0 {
                            Spacer()
                            Text("Clear Cortisol to Continue!").font(.headline).foregroundStyle(Color.themeLightBlue)
                            Spacer()
                        } else if topic.title == "What is Procrastination?" && currentStep == 5 && interactionState.itemsToClear > 0 {
                            Spacer()
                            Text("Clear Distractions to Continue!").font(.headline).foregroundStyle(Color.themeLightBlue)
                            Spacer()
                        } else {
                            // ── Next / Finish button ──
                            Button(action: { handleAdvance() }) {
                                Text(isLastStep ? "Finish" : "Next")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(topic.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(20)
                .background(ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Rectangle().fill(Color.themeCream.opacity(0.05))
                })
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.themeCream.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 15)
                .padding(.bottom, 30)
            }
            
            if showARHint {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.themeCream)
                        
                        Text("Set Up & Explore")
                            .font(.title2.bold())
                            .foregroundStyle(Color.themeCream)
                        
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Step 1: Screen Controls 🖥️", systemImage: "")
                                    .font(.headline)
                                    .foregroundStyle(Color.themeCream)
                                Divider().background(Color.themeCream.opacity(0.2))
                                HStack(alignment: .top, spacing: 16) {
                                    Label("Drag, pinch, and twist on the screen to place and size the 3D model to your liking.", systemImage: "hand.point.up.left")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.themeCream.opacity(0.85))
                                    Label("Use the revert icon to revert the 3D model on its original state.", systemImage: "arrow.counterclockwise")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.themeCream.opacity(0.85))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Step 2: Hand Gestures 🖐️", systemImage: "")
                                    .font(.headline)
                                    .foregroundStyle(Color.themeCream)
                                Divider().background(Color.themeCream.opacity(0.2))
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("Before any gesture show your full palm on camera!", systemImage: "hand.raised")
                                    Label("Rotate: Pinch Thumb & Index", systemImage: "arrow.triangle.2.circlepath")
                                    Label("Next: Pinch Thumb & Pinky (Hold for 0.5s)", systemImage: "forward.end")
                                }
                                .font(.subheadline)
                                .foregroundStyle(Color.themeCream.opacity(0.85))
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                    Text("Keep your full hand visible in the camera frame.")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.yellow)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) { showARHint = false }
                        }) {
                            Text("Got it!")
                                .font(.headline.bold())
                                .foregroundStyle(Color.themeDarkBlue)
                                .frame(width: 180, height: 50)
                                .background(Color.themeBeige)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial)
                            Rectangle().fill(Color.themeDarkBlue.opacity(0.7))
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.themeCream.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .navigationBarHidden(true)
        // ── CompletionView sheet ──
        .sheet(isPresented: $showCompletionScreen, onDismiss: {
            dismiss()
        }) {
            CompletionView(
                topic: topic,
                onDismiss: { showCompletionScreen = false },
                simulation: completionSimulation,
                timer: completionTimer
            )
            .environmentObject(userProgress)
        }
    }
    
    // ── Shared advance logic — called by button AND gesture ──
    func handleAdvance() {
        interactionState.reset()
        myelinOffset = .zero
        if isLastStep {
            userProgress.markComplete(topic.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCompletionScreen = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { currentStep += 1 }
        }
    }
}
