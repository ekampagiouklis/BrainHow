import SwiftUI

struct TopicDetailView: View {
    let topic: LearningTopic
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userProgress: UserProgress
    @State private var currentStep = 0
    @StateObject private var interactionState = LessonInteractionState()
    @State private var myelinOffset: CGSize = .zero
    @State private var showCompletionScreen = false
    @State private var showHowToUse = false
    @StateObject private var completionSimulation = BrainSimulation()
    @State private var sceneID = UUID()
    private let completionTimer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var isLastStep: Bool { currentStep == topic.sections.count - 1 }
    
    @AppStorage("lessonGraphics") private var lessonGraphics = true
    @AppStorage("arExperience") private var arExperience = true
    @AppStorage("highContrastUI") private var highContrastUI = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("renderQuality") private var renderQuality = "Medium"
    
    var body: some View {
        ZStack {
            Color.themeDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if lessonGraphics {
                    ZStack(alignment: .bottom) {
                        Color.themeDarkBlue
                        InteractiveSceneView(
                            step: currentStep,
                            topicTitle: topic.title,
                            interactionState: interactionState
                        )
                        .id("\(topic.title)-\(currentStep)-\(highContrastUI)-\(reduceMotion)-\(renderQuality)-\(sceneID)")
                        .transition(.opacity)
                        .accessibilityLabel("Interactive 3D model illustrating \(topic.sections[currentStep].title ?? "the brain").")
                        
                        if topic.title == "What is Burnout?" && currentStep == 6 && interactionState.itemsToClear > 0 {
                            InteractionHint(text: "Tap Cortisol to Clear: \(interactionState.itemsToClear)", icon: "hand.tap.fill").offset(y: -40)
                        } else if topic.title == "What is Procrastination?" && currentStep == 5 && interactionState.itemsToClear > 0 {
                            InteractionHint(text: "Tap Distractions to Focus: \(interactionState.itemsToClear)", icon: "hand.tap.fill").offset(y: -40)
                        } else if topic.title == "How Learning Works" && currentStep == 6 && !interactionState.isMyelinAttached {
                            InteractionHint(text: "Drag Myelin Up to Connect!", icon: "arrow.up").offset(y: -40)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .clipped()
                } else {
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.1)
                }
                
                ZStack {
                    VStack(spacing: 20) {
                        // ── Header ──
                        HStack {
                            Text(topic.title).font(.headline.bold()).foregroundColor(topic.color)
                            Spacer()
                            CircularProgressView(
                                progress: Double(currentStep + 1) / Double(topic.sections.count),
                                color: Color.themeLightBlue
                            )
                        }
                        
                        // ── Text fills all remaining space ──
                        ScrollView {
                            VStack(alignment: .leading, spacing: 15) {
                                let section = topic.sections[currentStep]
                                if let title = section.title {
                                    Text(title)
                                        .font(.title).bold()
                                        .foregroundStyle(Color.themeCream)
                                }
                                Text(LocalizedStringKey(section.content))
                                    .font(.title3)
                                    .lineSpacing(8)
                                    .foregroundStyle(Color.themeCream.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: .infinity)
                        .id("\(topic.title)-\(currentStep)-text")
                        .transition(.opacity)
                        
                        // ── Buttons always pinned to bottom ──
                        HStack(spacing: 15) {
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
                                .accessibilityLabel("Previous Step")
                            }
                            
                            if topic.title == "How Learning Works" && currentStep == 6 && !interactionState.isMyelinAttached {
                                Spacer()
                                Image(systemName: "capsule.fill")
                                    .resizable().frame(width: 60, height: 25)
                                    .foregroundStyle(Color.themeCream)
                                    .offset(myelinOffset)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in myelinOffset = value.translation }
                                            .onEnded { value in
                                                if value.translation.height < -50 {
                                                    withAnimation { interactionState.isMyelinAttached = true }
                                                } else {
                                                    withAnimation(.spring()) { myelinOffset = .zero }
                                                }
                                            }
                                    )
                                    .accessibilityLabel("Draggable Myelin")
                                    .accessibilityHint("Drag up to apply myelin to the axon.")
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
                                if arExperience {
                                    NavigationLink(destination: ARStoryView(topic: topic, currentStep: $currentStep).environmentObject(userProgress)) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arkit").font(.title3.bold())
                                            Text("View in AR").font(.headline.bold())
                                        }
                                        .foregroundStyle(Color.themeDarkBlue)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.themeLightBlue)
                                        .clipShape(Capsule())
                                        .shadow(color: Color.themeLightBlue.opacity(0.5), radius: 8, x: 0, y: 4)
                                    }
                                    .accessibilityLabel("View this lesson in Augmented Reality")
                                }
                                
                                Button(action: {
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
                                }) {
                                    Text(isLastStep ? "Finish" : "Next")
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(topic.color)
                                        .clipShape(Capsule())
                                }
                                .accessibilityLabel(isLastStep ? "Finish Lesson" : "Next Step")
                            }
                        }
                    }
                    .padding(25)
                    .background(ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                        Rectangle().fill(Color.themeCream.opacity(0.05))
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(LinearGradient(
                                colors: [.themeCream.opacity(0.4), .themeCream.opacity(0.1), .themeCream.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 15)
                    .padding(.top, 15)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: .infinity)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(.small ... .accessibility2)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showHowToUse = true }) {
                    VStack {
                        Spacer().frame(height: 8)
                        Image(systemName: "questionmark.circle")
                            .font(.body)
                            .foregroundColor(Color.themeCream)
                    }
                }
                .accessibilityLabel("How to Use")
                
                Button(action: { sceneID = UUID() }) {
                    VStack {
                        Spacer().frame(height: 8)
                        Image(systemName: "arrow.counterclockwise")
                            .font(.body)
                            .foregroundColor(Color.themeCream)
                    }
                }
                .accessibilityLabel("Revert 3D model to original state")
            }
        }
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
        .sheet(isPresented: $showHowToUse) {
            ZStack {
                Color.themeDarkBlue.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("How to Use")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.themeCream)
                        
                        Group {
                            Text("3D Mode").font(.title2.bold()).foregroundStyle(Color.themeBeige)
                            Text("The 3D viewer is your main way to explore each lesson. Every step has its own unique scene — from a full glowing brain to a live neuron pair.")
                                .font(.title3).lineSpacing(8).foregroundStyle(Color.themeCream.opacity(0.9))
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Drag one finger to rotate the model freely.", systemImage: "hand.draw")
                                Label("Pinch two fingers to zoom in or out.", systemImage: "arrow.up.left.and.arrow.down.right")
                                Label("On interactive steps, tap glowing objects to trigger an effect.", systemImage: "hand.tap")
                                Label("On the myelin step, drag the sheath onto the connection to upgrade it.", systemImage: "arrow.right.circle")
                            }
                            .font(.body).foregroundStyle(Color.themeCream.opacity(0.85)).padding(.leading, 4)
                        }
                        
                        Group {
                            Text("AR Mode").font(.title2.bold()).foregroundStyle(Color.themeBeige)
                            Text("AR Mode places the 3D scene into your real environment using your iPad's camera. Once placed, you control the lesson entirely with hand gestures.")
                                .font(.title3).lineSpacing(8).foregroundStyle(Color.themeCream.opacity(0.9))
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Point your camera at a flat surface and wait for the scene to appear.", systemImage: "camera.viewfinder")
                                Label("Pinch your thumb and index finger together and move your hand to rotate.", systemImage: "hand.pinch")
                                Label("Hold your thumb and pinky finger together to advance to the next step.", systemImage: "hand.raised.fingers.spread")
                                Label("Keep your full hand visible in the camera frame for gestures to register.", systemImage: "eye")
                                Label("Good lighting makes hand tracking significantly more accurate.", systemImage: "lightbulb")
                            }
                            .font(.body).foregroundStyle(Color.themeCream.opacity(0.85)).padding(.leading, 4)
                        }
                        
                        Group {
                            Text("Interactive Steps").font(.title2.bold()).foregroundStyle(Color.themeBeige)
                            Text("Some steps require you to interact before continuing. Look for the hint banner at the bottom of the 3D view.")
                                .font(.title3).lineSpacing(8).foregroundStyle(Color.themeCream.opacity(0.9))
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Tap red cortisol or distraction bubbles to clear them from the synapse.", systemImage: "circle.slash")
                                Label("Drag the myelin sheath onto the axon to insulate it and speed up the signal.", systemImage: "arrow.right.circle.fill")
                                Label("The circular progress indicator tracks how far through a topic you are.", systemImage: "circle.dotted")
                            }
                            .font(.body).foregroundStyle(Color.themeCream.opacity(0.85)).padding(.leading, 4)
                        }
                        
                        Group {
                            Text("Tips").font(.title2.bold()).foregroundStyle(Color.themeBeige)
                            VStack(alignment: .leading, spacing: 10) {
                                Label("If AR gestures feel unresponsive, try moving to a brighter room.", systemImage: "sun.max")
                                Label("You can switch between 3D and AR mode mid-lesson without losing your progress.", systemImage: "arrow.triangle.2.circlepath")
                                Label("Reduce motion and high contrast options are available in Settings if needed.", systemImage: "accessibility")
                                Label("Lower the render quality in Settings if the app feels slow on your device.", systemImage: "gauge.with.dots.needle.bottom.50percent")
                            }
                            .font(.body).foregroundStyle(Color.themeCream.opacity(0.85)).padding(.leading, 4)
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding(30)
                }
            }
            .presentationDragIndicator(.visible)
            .modifier(BlurredSheetModifier())
        }
    }
}
