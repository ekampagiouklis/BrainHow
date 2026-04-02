import SwiftUI

struct ContentView: View {
    @StateObject private var userProgress = UserProgress()
    @State private var currentScreen: AppScreen = .intro
    
    var body: some View {
        NavigationStack {
            switch currentScreen {
            case .intro:
                IntroView(onStart: {
                    withAnimation { currentScreen = .onboarding }
                })
            case .onboarding:
                OnboardingView(onFinish: {
                    withAnimation { currentScreen = .learningProcess }
                })
            case .learningProcess:
                LearningProcessView(onBack: {
                    withAnimation { currentScreen = .onboarding }
                })
                .environmentObject(userProgress)
            }
        }
    }
}
