import Foundation

enum DuplicatesError: Error, CustomStringConvertible {
    case duplicateEntries(duplicates: [String], context: String)

    var description: String {
        switch self {
        case .duplicateEntries(let duplicates, let context):
            return "❌ Duplicate \(context) entries found:\n\(duplicates.joined(separator: ", "))"
        }
    }
}

extension Array where Element == String {
    func duplicatesValidation(context: String) throws {
        let uniqueElements = Set(self)
        if uniqueElements.count != count {
            let duplicates = reduce(into: [Element: Int]()) { counts, element in
                counts[element, default: 0] += 1
            }
            .filter { $0.value > 1 }
            .map { $0.key }
            .sorted()
            throw DuplicatesError.duplicateEntries(duplicates: duplicates, context: context)
        }
    }
}
