import Foundation

/// Errors emitted while parsing and validating Xcode project target metadata.
///
/// These cases surface specific, actionable failures encountered during parsing:
/// - A target name referenced in configuration does not match any target in the Xcode project (`invalidTargetName`).
/// - A provided path is malformed or does not exist (`invalidPath`).
/// - The parser could not resolve the expected buildable folder path for a target (`failedToResolveBuildableFolderPath`).
/// - Certain group folders were flagged as forbidden buildable folders (`forbiddenBuildableFoldersForGroups`).
/// - An exception set referenced a group for which the target is `nil` (`exceptionSetTargetIsNil`).
/// - An exception set referenced a group for which the product type is `nil` (`exceptionSetTargetProductTypeIsNil`).
///
/// Conforms to `CustomStringConvertible` for human‑readable diagnostics and `Equatable` for test assertions.
enum XcodeProjectParserError: Error, CustomStringConvertible, Equatable {
    /// A target name referenced in configuration does not exist in the parsed Xcode project.
    /// - Parameter name: The invalid (unknown) target name.
    case invalidTargetName(String)
    /// A path value encountered during parsing is invalid (missing, malformed, or non-resolvable).
    /// - Parameter path: The offending path string.
    case invalidPath(String)
    /// The parser failed to resolve an expected buildable folder (e.g. sources root) for a target.
    /// - Parameter path: The folder path that could not be resolved.
    case failedToResolveBuildableFolderPath(String)
    /// One or more group folders mapped to forbidden buildable folder locations.
    /// - Parameter groups: The list of group path strings that are considered forbidden.
    case forbiddenBuildableFoldersForGroups([String])
    /// While evaluating an exception set, the target resolved for a group was unexpectedly `nil`.
    /// - Parameter groupPath: The path of the group whose target was `nil`.
    case exceptionSetTargetIsNil(String)
    /// While evaluating an exception set, the target product type resolved for a group was unexpectedly `nil`.
    /// - Parameter groupPath: The path of the group whose target product type was `nil`.
    case exceptionSetTargetProductTypeIsNil(String)

    /// Human‑readable description for logging or CLI output.
    var description: String {
        switch self {
        case .invalidTargetName(let name):
            "error: ❌ Invalid target name \(name)"
        case .invalidPath(let path):
            "error: ❌ Invalid path \(path)"
        case .failedToResolveBuildableFolderPath(let path):
            "error: ❌ Failed to resolve buildable folder path \(path)"
        case .forbiddenBuildableFoldersForGroups(let groups):
            "error: ❌ Forbidden buildable folders for groups: \n\(groups.joined(separator: ", \n"))"
        case .exceptionSetTargetIsNil(let groupPath):
            "error: ❌ Exception set target is nil for group at path: \(groupPath)"
        case .exceptionSetTargetProductTypeIsNil(let groupPath):
            "error: ❌ Exception set target product type is nil for group at path: \(groupPath)"
        }
    }
}
