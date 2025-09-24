struct Configuration: Codable, Equatable {
    let name: String
    let fileMembershipSets: [FileMembershipSet]
    let forbiddenResourceSets: [ForbiddenResourceSet]?
}

extension Configuration {
    struct FileMembershipSet: Codable, Equatable {
        let targets: [String]
        let exclusive: [String: [String]]?
    }
}

extension Configuration {
    struct ForbiddenResourceSet: Codable, Equatable {
        let targets: [String]
        let paths: [String]?
        let files: [String]?
    }
}
