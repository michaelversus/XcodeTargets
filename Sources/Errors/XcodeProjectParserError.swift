import Foundation

enum XcodeProjectParserError: Error, CustomStringConvertible, Equatable {
        case invalidTargetName(String)
        case invalidPath(String)
        case failedToResolveBuildableFolderPath(String)
        case forbiddenBuildableFoldersForGroups([String])
        case exceptionSetTargetIsNil(String)
        case exceptionSetTargetProductTypeIsNil(String)

        var description: String {
            switch self {
            case .invalidTargetName(let name):
                return "❌ Invalid target name \(name)"
            case .invalidPath(let path):
                return "❌ Invalid path \(path)"
            case .failedToResolveBuildableFolderPath(let path):
                return "❌ Failed to resolve buildable folder path \(path)"
            case .forbiddenBuildableFoldersForGroups(let groups):
                return "❌ Forbidden buildable folders for groups: \n\(groups.joined(separator: ", \n"))"
            case .exceptionSetTargetIsNil(let groupPath):
                return "❌ Exception set target is nil for group at path: \(groupPath)"
            case .exceptionSetTargetProductTypeIsNil(let groupPath):
                return "❌ Exception set target product type is nil for group at path: \(groupPath)"
            }
        }
    }
