import Foundation

struct ForbiddenResourceError: Error, CustomStringConvertible, Equatable {
    let targetName: String
    let matchingPaths: Set<String>

    var description: String {
        "❌ Forbidden resource(s) found in target \(targetName):\n" +
        matchingPaths
            .map { " - \($0)" }
            .sorted()
            .joined(separator: "\n")
    }
}
