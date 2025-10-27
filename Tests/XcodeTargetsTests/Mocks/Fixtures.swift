import PathKit
import Foundation

func fixturesPath() -> Path {
    Path(#filePath).parent().parent().parent().parent() + "Fixtures"
}

func duplicateSourceFilesProjectPath() throws -> URL {
    let path = fixturesPath() + "DuplicateSourceFiles.xcodeproj"
    return path.url
}
