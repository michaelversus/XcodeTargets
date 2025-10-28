import Foundation

extension String {
    /// Returns a new string with a trailing wildcard directory component removed.
    ///
    /// This method inspects the receiver for a terminal pattern representing a directory
    /// wildcard and strips only the wildcard characters, leaving the directory path and trailing slash intact.
    /// Supported terminal patterns:
    /// - `/*`  (e.g. "Sources/*" -> "Sources/") removes the final asterisk
    /// - `/.*` (e.g. "Sources/.*" -> "Sources/") removes the final dot and asterisk
    ///
    /// If the receiver does not end with one of the supported patterns, the original string is returned unchanged.
    /// The method does not modify internal wildcard occurrences—only a trailing match is considered.
    ///
    /// Examples:
    /// ```swift
    /// "Sources/*".dropWildCards()    // "Sources/"
    /// "Sources/.*".dropWildCards()   // "Sources/"
    /// "Sources/File.swift".dropWildCards() // "Sources/File.swift"
    /// "/*".dropWildCards()          // "/"
    /// "Path/To/*/File".dropWildCards() // "Path/To/*/File" (no trailing wildcard pattern)
    /// ```
    ///
    /// - Returns: The receiver without a terminal wildcard pattern, or the original string when no pattern matches.
    func dropWildCards() -> String {
        if hasSuffix("/*") {
            return String(dropLast(1))
        } else if hasSuffix("/.*") {
            return String(dropLast(2))
        } else {
            return self
        }
    }
}
