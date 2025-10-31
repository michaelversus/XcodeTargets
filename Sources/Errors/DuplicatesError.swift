import Foundation

/// Error thrown when duplicate entries are detected for a given context (e.g. Source File, Resource, Framework).
///
/// Provides the offending duplicate values plus a textual context to aid diagnostics and test assertions.
/// Conforms to `Error`, `CustomStringConvertible`, and `Equatable` for throwing, human‑readable output, and comparison in tests.
enum DuplicatesError: Error, CustomStringConvertible, Equatable {
    /// Duplicate entries were found.
    /// - Parameters:
    ///   - duplicates: The distinct values that appeared more than once.
    ///   - context: Human‑readable description of where they were found.
    case duplicateEntries(duplicates: [String], context: String)

    /// Human‑readable description enumerating the duplicate values.
    var description: String {
        switch self {
        case .duplicateEntries(let duplicates, let context):
            "❌ Duplicate \(context) entries found:\n\(duplicates.joined(separator: ", "))"
        }
    }
}
