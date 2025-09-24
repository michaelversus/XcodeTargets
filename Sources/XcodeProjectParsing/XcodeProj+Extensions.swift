import XcodeProj
import Path

extension XcodeProj {
    /// A computed property that either returns the project’s `path`
    public var projectPath: AbsolutePath {
        try! AbsolutePath(validating: path!.string)
    }

    public var srcPath: AbsolutePath {
        projectPath.parentDirectory
    }

    public var srcPathString: String {
        srcPath.pathString
    }
}
