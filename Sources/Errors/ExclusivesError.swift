import Foundation

enum ExclusivesError: Error, CustomStringConvertible, Equatable {
    case invalidTargetName(String)
    case invalidPathForTarget(targetName: String, path: String)
    case exclusiveEntriesFound(targetNames: String)

    var description: String {
        switch self {
        case .invalidTargetName(let name):
            return "❌ Target name \(name) inside exclusive section doesn't exist in the project"
        case .invalidPathForTarget(let targetName, let path):
            return "❌ Path \(path) inside exclusive section for target \(targetName) doesn't exist in the project"
        case .exclusiveEntriesFound(let targetNames):
            return "❌ Exclusive entries found for targets: \(targetNames)"
        }
    }
}
