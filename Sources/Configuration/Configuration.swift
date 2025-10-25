struct Configuration: Codable, Equatable {
    let name: String
    let fileMembershipSets: [FileMembershipSet]
    let forbiddenResourceSets: [ForbiddenResourceSet]?
    let duplicatesValidationExcludedTargets: [String]?
}

extension Configuration {
    struct FileMembershipSet: Codable, Equatable {
        let targets: [String]
        let exclusive: [String: TargetExclusive]?
    }
}

extension Configuration {
    struct TargetExclusive: Codable, Equatable {
        let files: [String]?
        let dependencies: [String]?
        let frameworks: [String]?
    }
}

extension Configuration {
    struct ForbiddenResourceSet: Codable, Equatable {
        let targets: [String]
        let paths: [String]?
    }
}
