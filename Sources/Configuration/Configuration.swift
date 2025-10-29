/// Top-level configuration describing project name, target membership grouping, forbidden resources,
/// and duplicate validation exclusions.
///
/// Instances of this type are consumed by multiple processors:
/// - CompositionRoot derives the `.xcodeproj` path from `name`.
/// - ExclusivesProcessor uses `fileMembershipSets` (and nested `TargetExclusive`) to prune and verify
///   alignment of files, dependencies, and frameworks across grouped targets.
/// - ForbiddenResourcesProcessor validates `forbiddenResourceSets` to ensure no disallowed resource paths exist.
/// - XcodeProjectParser consults `duplicatesValidationExcludedTargets` to skip duplicate checks for specified targets.
///
/// Example JSON (full):
/// ```json
/// {
///     "name": "MyProject",
///     "fileMembershipSets": [
///         {
///             "targets": ["App", "AppStaging", "AppProd"],
///             "exclusive": {
///                 "AppStaging": {
///                     "files": ["Config/Staging/*", "Features/DebugPanel/"],
///                     "dependencies": ["StagingAnalytics"],
///                     "frameworks": ["StagingSDK"]
///                 },
///                 "AppProd": {
///                     "files": ["Config/Prod/*"],
///                     "dependencies": ["ProdAnalytics"],
///                     "frameworks": ["ProdSDK"]
///                 }
///             }
///         },
///         {
///             "targets": ["Widget", "WidgetExtension"],
///             "exclusive": {
///                 "WidgetExtension": {
///                     "files": ["WidgetExtensionSpecific/*"],
///                     "dependencies": ["WidgetExtensionSupport"],
///                     "frameworks": []
///                 }
///             }
///         }
///     ],
///     "forbiddenResourceSets": [
///         {
///             "targets": ["App", "AppStaging", "AppProd"],
///             "paths": ["/Debug/", "Temporary/"]
///         },
///         {
///             "targets": ["Widget"],
///             "paths": ["LargeAssets/"]
///         }
///     ],
///     "duplicatesValidationExcludedTargets": ["Tests", "UITests"]
/// }
/// ```
///
/// Minimal JSON (only required keys):
/// ```json
/// {
///     "name": "MyProject",
///     "fileMembershipSets": [
///         { "targets": ["App"] }
///     ]
/// }
/// ```
struct Configuration: Codable, Equatable {
    /// Logical name of the Xcode project (without the `.xcodeproj` extension).
    /// Used to construct the project path.
    let name: String
    /// Groups of target names whose file / dependency / framework memberships must match after pruning exclusives.
    /// Each group can define per-target exclusives via `exclusive`.
    let fileMembershipSets: [FileMembershipSet]
    /// Optional sets defining resource path substrings that must not appear in the matching targets' resource file paths.
    /// Each forbidden resource path is evaluated via simple substring containment.
    let forbiddenResourceSets: [ForbiddenResourceSet]?
    /// Optional list of target names excluded from duplicate validation (source files, resources, dependencies, frameworks).
    let duplicatesValidationExcludedTargets: [String]?
}

// MARK: - FileMembershipSet
extension Configuration {
    /// Describes a group of targets whose membership collections (files, dependencies, frameworks) should align.
    /// Exclusive differences that are intentional per target can be declared through `exclusive` and will be pruned
    /// before cross-target comparison.
    struct FileMembershipSet: Codable, Equatable {
        /// Names of the targets participating in this membership group.
        let targets: [String]
        /// Mapping of target name to exclusive entries that are unique to that target and should be pruned
        /// prior to validation. Keys must reference targets listed in `targets`.
        let exclusive: [String: TargetExclusive]?
    }
}

// MARK: - TargetExclusive
extension Configuration {
    /// Defines entries (files, dependencies, frameworks) considered exclusive to a single target.
    /// Exclusive entries are removed before membership alignment validation.
    ///
    /// File patterns support simple substring containment and wildcard directory forms:
    /// - `path/*` or `path/.*` include all contents beneath `path/`.
    /// Dependencies and frameworks apply an exact match first, then substring containment if exact match fails.
    struct TargetExclusive: Codable, Equatable {
        /// File path patterns or substrings exclusive to the target.
        let files: [String]?
        /// Dependency names or substrings exclusive to the target.
        let dependencies: [String]?
        /// Framework names or substrings exclusive to the target.
        let frameworks: [String]?
    }
}

// MARK: - ForbiddenResourceSet
extension Configuration {
    /// Defines forbidden resource path substrings for a set of targets.
    /// If any target's resource path contains one of the substrings, a `ForbiddenResourceError` is thrown.
    struct ForbiddenResourceSet: Codable, Equatable {
        /// Names of the targets to validate against the forbidden resource paths.
        let targets: [String]
        /// Resource path substrings that must not appear in the targets' resource file paths.
        let paths: [String]?
    }
}
