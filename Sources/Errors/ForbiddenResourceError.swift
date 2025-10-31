import Foundation

/// Error thrown when a target contains one or more resources that match any forbidden resource rule.
///
/// Use this error to surface all offending resource paths discovered for a specific target in a single throw.
struct ForbiddenResourceError: Error, CustomStringConvertible, Equatable {
    /// The name of the target where forbidden resources were found.
    let targetName: String
    /// The set of resource paths that matched forbidden patterns. Each path is unique.
    let matchingPaths: Set<String>

    /// A human readable, multiline description enumerating each forbidden resource path found.
    var description: String {
        "error: ❌ Forbidden resource(s) found in target \(targetName):\n" +
        matchingPaths
            .map { " - \($0)" }
            .sorted()
            .joined(separator: "\n")
    }
}
