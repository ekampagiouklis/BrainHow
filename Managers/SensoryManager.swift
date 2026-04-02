import Foundation

final class SensoryManager: @unchecked Sendable {
    static let shared = SensoryManager()
    private init() {}
    func lightImpact() {}
    func heavyImpact() {}
    func successFeedback() {}
    func errorFeedback() {}
    func softWhoosh() {}
}
