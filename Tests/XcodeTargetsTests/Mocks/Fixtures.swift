import PathKit
import Foundation

func fixturesPath() -> Path {
    Path(#filePath).parent().parent().parent().parent() + "Fixtures"
}

func duplicateSourceFilesProjectPath() throws -> URL {
    let path = fixturesPath() + "DuplicateSourceFiles.xcodeproj"
    return path.url
}

func duplicateResourceFilesProjectPath() throws -> URL {
    let path = fixturesPath() + "DuplicateResourceFiles.xcodeproj"
    return path.url
}

func duplicateDependenciesProjectPath() throws -> URL {
    let path = fixturesPath() + "DuplicateDependencies.xcodeproj"
    return path.url
}

func duplicateFrameworksProjectPath() throws -> URL {
    let path = fixturesPath() + "DuplicateFrameworks.xcodeproj"
    return path.url
}

func fullSuccessDemoProjectPath() throws -> URL {
    let path = fixturesPath() + "FullSuccessDemo.xcodeproj"
    return path.url
}
