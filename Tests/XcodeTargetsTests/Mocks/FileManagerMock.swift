@testable import XcodeTargets
import Foundation

final class FileManagerMock: FileManagerProtocol {
    var currentDirectoryPath: String = ""
    var actions: [Action] = []
    var fileExistsReturnValue: Bool = false
    var allFilePathsReturnValue: Set<String>
    var allFileURLsReturnValue: Set<URL> = []

    enum Action: Equatable {
        case fileExists(atPath: String)
        case allFiles(inDirectoryPath: String)
        case allFiles(inDirectoryURL: URL, membershipExceptions: Set<MembershipException>)
    }

    init(
        currentDirectoryPath: String = "",
        fileExistsReturnValue: Bool = false,
        allFilePathsReturnValue: Set<String> = [],
        allFileURLsReturnValue: Set<URL> = []
    ) {
        self.currentDirectoryPath = currentDirectoryPath
        self.fileExistsReturnValue = fileExistsReturnValue
        self.allFilePathsReturnValue = allFilePathsReturnValue
        self.allFileURLsReturnValue = allFileURLsReturnValue
    }

    func fileExists(atPath path: String) -> Bool {
        actions.append(.fileExists(atPath: path))
        return fileExistsReturnValue
    }

    func allFiles(in directoryPath: String) throws -> Set<String> {
        actions.append(.allFiles(inDirectoryPath: directoryPath))
        return allFilePathsReturnValue
    }

    func allFiles(in directoryURL: URL, membershipExceptions: Set<MembershipException>) throws -> Set<URL> {
        actions.append(.allFiles(inDirectoryURL: directoryURL, membershipExceptions: membershipExceptions))
        return allFileURLsReturnValue
    }
}
