@testable import XcodeTargets

final class FileManagerMock: FileManagerProtocol {
    var currentDirectoryPath: String = ""
    var actions: [Action] = []
    var fileExistsReturnValue: Bool = false

    enum Action {
        case fileExists(atPath: String)
    }

    init(
        currentDirectoryPath: String = "",
        fileExistsReturnValue: Bool = false
    ) {
        self.currentDirectoryPath = currentDirectoryPath
        self.fileExistsReturnValue = fileExistsReturnValue
    }

    func fileExists(atPath path: String) -> Bool {
        actions.append(.fileExists(atPath: path))
        return fileExistsReturnValue
    }
}
