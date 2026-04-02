import Foundation

class UserProgress: ObservableObject {
    @Published var completedTopicIDs: Set<UUID> = []
    
    func markComplete(_ topicID: UUID) {
        completedTopicIDs.insert(topicID)
        objectWillChange.send()
    }
    func isCompleted(_ topicID: UUID) -> Bool { completedTopicIDs.contains(topicID) }
    func resetProgress() { completedTopicIDs.removeAll() }
}
