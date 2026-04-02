import SwiftUI

enum AppScreen { case intro, onboarding, learningProcess }

enum SectionType { case paragraph, highlight }

struct Neuron: Identifiable {
    let id = UUID()
    var x: CGFloat, y: CGFloat, velocityX: CGFloat, velocityY: CGFloat
    let size: CGFloat
}

struct TopicSection: Identifiable, Hashable {
    let id = UUID()
    let title: String?
    let content: String
    let type: SectionType
}

struct LearningTopic: Identifiable, Hashable {
    let id = UUID()
    let icon: String, color: Color, title: String, shortDescription: String, sections: [TopicSection]
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: LearningTopic, rhs: LearningTopic) -> Bool { lhs.id == rhs.id }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String, title: String, description: String, color: Color
}
