import Foundation

enum DuplicatesError: Error, CustomStringConvertible, Equatable {
    case duplicateEntries(duplicates: [String], context: String)

    var description: String {
        switch self {
        case .duplicateEntries(let duplicates, let context):
            return "❌ Duplicate \(context) entries found:\n\(duplicates.joined(separator: ", "))"
        }
    }
}
