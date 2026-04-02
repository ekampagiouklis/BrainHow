import Foundation

class LessonInteractionState: ObservableObject {
    @Published var itemsToClear: Int = 10
    @Published var isMyelinAttached: Bool = false
    
    func reset() {
        itemsToClear = 10
        isMyelinAttached = false
    }
}
