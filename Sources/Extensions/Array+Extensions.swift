import Foundation

// MARK: - String Array Duplicate Validation

/// Provides duplicate validation utilities for arrays of `String`.
///
/// Use `duplicatesValidation(context:)` to assert that a collection of string values (such as target names,
/// file paths, or dependency identifiers) contains no duplicates. The method performs a case-sensitive check and
/// throws `DuplicatesError.duplicateEntries` including the offending duplicate values and a caller-supplied
/// contextual description to aid diagnostics.
///
/// Example:
/// ```swift
/// let targetNames = ["App", "Core", "App"]
/// do {
///     try targetNames.duplicatesValidation(context: "target names")
///     // If we reach here, there were no duplicates
/// } catch let DuplicatesError.duplicateEntries(duplicates, context) {
///     // Handle duplicates
///     // duplicates == ["App"]
///     // context == "target names"
/// }
/// ```
///
/// Example without duplicates:
/// ```swift
/// let moduleNames = ["App", "Core", "UI"]
/// try moduleNames.duplicatesValidation(context: "module names")
/// // No error thrown
/// ```
extension Array where Element == String {
    /// Validates that the array contains no duplicate string entries for the provided context.
    ///
    /// The validation is case-sensitive. If duplicates are detected, a `DuplicatesError.duplicateEntries` error
    /// is thrown including the sorted list of duplicate values and the supplied context to help pinpoint the source.
    ///
    /// - Parameter context: A human-readable description of what the array represents (e.g. "target names"). Used to
    ///   enrich the thrown error for debugging purposes.
    /// - Throws: `DuplicatesError.duplicateEntries` when one or more duplicate strings are found.
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
