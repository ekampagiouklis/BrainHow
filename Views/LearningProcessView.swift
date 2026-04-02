import SwiftUI
import Combine

struct LearningProcessView: View {
    var onBack: () -> Void
    @StateObject var simulation = BrainSimulation()
    @EnvironmentObject var userProgress: UserProgress
    @State private var showSettings = false
    @State private var showHowToUse = false
    @State private var showAboutApp = false
    let topics = TopicData.topics
    
    @AppStorage("backgroundAnimations") private var backgroundAnimations = true
    @AppStorage("highContrastUI") private var highContrastUI = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.themeDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        if backgroundAnimations {
                            ProceduralBrainView()
                                .frame(height: UIScreen.main.bounds.height * 0.48)
                                .mask(LinearGradient(
                                    colors: [.themeDarkBlue, .themeDarkBlue, .clear],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .accessibilityHidden(true)
                                .id(highContrastUI)
                        } else {
                            Spacer().frame(height: UIScreen.main.bounds.height * 0.48)
                        }
                        InteractionHint(text: "Move and Experience", icon: "hand.tap.fill").offset(y: 10)
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Image("BrainLogoYellow")
                                .resizable().scaledToFit()
                                .frame(height: 300, alignment: .leading)
                                .padding(.top, -80).padding(.bottom, -85).padding(.leading, -30)
                                .accessibilityLabel("BrainHow Logo")
                            
                            Text("Explore the available lessons:")
                                .font(.subheadline)
                                .foregroundStyle(Color.themeLightBlue)
                                .padding(.bottom, 20)
                            
                            VStack(spacing: 15) {
                                ForEach(topics) { topic in
                                    NavigationLink(destination: TopicDetailView(topic: topic).environmentObject(userProgress)) {
                                        HStack(spacing: 15) {
                                            ZStack {
                                                Circle().fill(topic.color.opacity(0.2)).frame(width: 50, height: 50)
                                                Image(systemName: topic.icon).font(.title2).foregroundStyle(topic.color)
                                            }
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(topic.title).font(.headline).foregroundStyle(Color.themeCream)
                                                Text(topic.shortDescription).font(.caption).foregroundStyle(Color.themeLightBlue).multilineTextAlignment(.leading)
                                            }
                                            Spacer()
                                            if userProgress.isCompleted(topic.id) {
                                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title2).accessibilityLabel("Completed")
                                            } else {
                                                Image(systemName: "chevron.right").foregroundStyle(Color.themeLightBlue.opacity(0.8))
                                            }
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.themeCream.opacity(0.08))
                                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(topic.color.opacity(0.5), lineWidth: 1))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Starts the \(topic.title) lesson.")
                                }
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 50)
                    }
                    .background(Color.themeDarkBlue)
                }
                
                HStack(spacing: 10) {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.body.bold())
                            Text("Back").font(.body.bold())
                        }
                        .foregroundStyle(Color.themeCream)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.themeCream.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Go back")
                    Spacer()
                    Button(action: { showHowToUse = true }) {
                        Image(systemName: "questionmark.circle").padding(10)
                            .background(Color.themeCream.opacity(0.15)).clipShape(Circle())
                    }
                    .accessibilityLabel("How to Use")
                    Button(action: { showAboutApp = true }) {
                        Image(systemName: "heart.text.square").padding(10)
                            .background(Color.themeCream.opacity(0.15)).clipShape(Circle())
                    }
                    .accessibilityLabel("About This App")
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill").padding(10)
                            .background(Color.themeCream.opacity(0.15)).clipShape(Circle())
                    }
                    .accessibilityLabel("Settings")
                }
                .foregroundColor(Color.themeCream)
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(resetSimulation: { simulation.shake() })
                .environmentObject(userProgress)
        }
        // ── How to Use sheet ──
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
        // ── About This App sheet ──
        .sheet(isPresented: $showAboutApp) {
            ZStack {
                Color.themeDarkBlue.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("About This App")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color.themeCream)
                        
                        Text("""
                        I built BrainHow for the version of me that was sitting on the floor at 2am, \
                        textbook open, completely unable to read a single word and genuinely \
                        convinced that something was wrong with me.
                        
                        I was seventeen, and I was already burned out. I'd stare at my notes for hours \
                        and retain nothing. I'd make a study plan every Sunday and abandon it by \
                        Monday. I'd watch everyone around me seem to just... get it, while I sat there \
                        cycling between panic and guilt and the strange, heavy numbness of a brain \
                        that had simply stopped cooperating.
                        
                        Nobody told me that what I was experiencing had a name. Nobody told me it had \
                        a biology. That procrastination isn't laziness — it's your amygdala treating a \
                        textbook like a threat. That burnout isn't weakness — it's cortisol physically \
                        shrinking the part of your brain responsible for focus. That the reason \
                        I couldn't just "try harder" is because the very tool I needed to try harder \
                        with was the one being damaged.
                        
                        The day I learned that, something shifted. Not because my workload got easier, \
                        but because I stopped hating myself for struggling.
                        
                        I made BrainHow because I needed it to exist. Not another productivity app \
                        with timers and to-do lists, but something that would sit a struggling student \
                        down and say: here is what is actually happening inside your head, and none of \
                        it means you aren't capable. I wanted the science to feel real and alive — \
                        something you could reach out and touch — because abstract words on a page \
                        never helped me the way a visual, visceral moment of understanding did.
                        
                        If even one student walks away from this app feeling seen instead of broken, \
                        then every late night building it was worth it.
                        """)
                        .font(.title3)
                        .lineSpacing(10)
                        .foregroundStyle(Color.themeCream.opacity(0.9))
                        .padding(24)
                        .background(
                            ZStack {
                                Rectangle().fill(.ultraThinMaterial)
                                Rectangle().fill(Color.themeCream.opacity(0.04))
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.themeCream.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        
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
