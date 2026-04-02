import SwiftUI

struct SettingsView: View {
    var resetSimulation: (() -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var userProgress: UserProgress
    
    @AppStorage("backgroundAnimations") private var backgroundAnimations = true
    @AppStorage("lessonGraphics") private var lessonGraphics = true
    @AppStorage("renderQuality") private var renderQuality = "Medium"
    @AppStorage("arExperience") private var arExperience = true
    @AppStorage("arGesturesRotate") private var arGesturesRotate = true
    @AppStorage("arGesturesNext") private var arGesturesNext = true
    @AppStorage("arTextEnabled") private var arTextEnabled = true
    @AppStorage("arHighQuality") private var arHighQuality = true
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("highContrastUI") private var highContrastUI = false
    @AppStorage("modelLabelSize") private var modelLabelSize = "Medium"
    @State private var showResetAlert = false
    @State private var showHowToUse = false
    @State private var showAboutApp = false
    
    var body: some View {
        ZStack {
            Color.themeDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Color.themeCream)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundColor(Color.themeCream)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close Settings")
                }
                .padding(.horizontal, 25)
                .padding(.top, 25)
                .padding(.bottom, 15)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        
                        SettingsSectionContainer(title: "Visuals & Audio") {
                            SettingsToggleRow(title: "Background Animations", isOn: $backgroundAnimations)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "Lesson Graphics", isOn: $lessonGraphics)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "High Contrast UI", isOn: $highContrastUI)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "Reduce Motion", isOn: $reduceMotion)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsPickerRow(title: "Render Quality", options: ["Low", "Medium", "High"], selection: $renderQuality)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsPickerRow(title: "3D Label Size", options: ["Small", "Medium", "Large"], selection: $modelLabelSize)
                        }
                        
                        SettingsSectionContainer(title: "AR Experience") {
                            SettingsToggleRow(title: "Enable AR Experience", isOn: $arExperience)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "Text in AR mode", isOn: $arTextEnabled)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "AR High Quality Lighting", isOn: $arHighQuality)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "Gestures - Pinch to rotate", isOn: $arGesturesRotate)
                            Divider().background(Color.themeCream.opacity(0.2))
                            SettingsToggleRow(title: "Gestures - Pinch to next step", isOn: $arGesturesNext)
                        }
                        
                        SettingsSectionContainer(title: "About") {
                            Button(action: { showHowToUse = true }) {
                                HStack {
                                    Text("How to Use")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(Color.themeCream)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.themeLightBlue)
                                }
                                .padding(.vertical, 8)
                            }
                            Divider().background(Color.themeCream.opacity(0.2))
                            Button(action: { showAboutApp = true }) {
                                HStack {
                                    Text("About This App")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(Color.themeCream)
                                    Spacer()
                                    Image(systemName: "info.circle")
                                        .foregroundColor(Color.themeLightBlue)
                                }
                                .padding(.vertical, 8)
                            }
                            Divider().background(Color.themeCream.opacity(0.2))
                            HStack {
                                Text("App Version")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(Color.themeCream.opacity(0.7))
                                Spacer()
                                Text("1.0.0")
                                    .font(.footnote)
                                    .foregroundColor(Color.themeLightBlue)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        SettingsSectionContainer(title: "Data") {
                            Button(action: { showResetAlert = true }) {
                                HStack {
                                    Image(systemName: "trash.fill").foregroundColor(.red)
                                    Text("Reset App Data")
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                            .accessibilityLabel("Reset all course progress")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Reset App?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                userProgress.resetProgress()
                resetSimulation?()
            }
        } message: {
            Text("This will permanently erase your completed progress.")
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
        .sheet(isPresented: $showAboutApp) {
            ZStack {
                Color.themeDarkBlue.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
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
