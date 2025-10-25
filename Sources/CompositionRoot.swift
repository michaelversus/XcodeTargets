import Foundation

struct CompositionRoot {
    let configurationPath: String?
    let rootPath: String?
    let fileManager: FileManagerProtocol
    let defaultPath: String = ".xcode-targets.json"
    let vPrint: (String) -> Void

    var root: String {
        let rootPath = rootPath ?? fileManager.currentDirectoryPath
        if rootPath.hasSuffix("/") {
            return rootPath
        } else {
            return rootPath + "/"
        }
    }

    init(
        configurationPath: String? = nil,
        rootPath: String? = nil,
        fileManager: FileManagerProtocol,
        vPrint: @escaping (String) -> Void = { print($0) }
    ) {
        self.configurationPath = configurationPath
        self.rootPath = rootPath ?? fileManager.currentDirectoryPath
        self.fileManager = fileManager
        self.vPrint = vPrint
    }
    
    func run() throws {
        let configurationLoader = ConfigurationLoader(
            fileManager: fileManager,
            defaultPath: defaultPath,
            vPrint: vPrint
        )
        let configuration = try configurationLoader.loadConfiguration(
            at: configurationPath,
            root: root
        )
        let projectPath = root + configuration.name + ".xcodeproj"
        let parser = XcodeProjectParser(
            fileManager: fileManager,
            configuration: configuration,
            vPrint: vPrint
        )
        let targetsIndex = try parser.parseXcodeProject(at: projectPath, root: root)

//        // Step 1
//        // parse exclusive files or wildcard directories path/* or path/.* and check if they are included inside the proper target. Also check that they are not included in other targets.
//        // create new targets that don't have excluded files
//        // check if rest of files are common for all fileMembershipSets
        let fileMembershipSets = configuration.fileMembershipSets
        var targetsWithoutExclusives = targetsIndex.mapValues { $0.mappingToTarget() }
        for fileMembershipSet in fileMembershipSets {
            guard let exclusive = fileMembershipSet.exclusive else { continue }
            for (targetName, targetExclusive) in exclusive {
                for exclusiveFile in targetExclusive.files ?? [] {
                    guard let target = targetsWithoutExclusives[targetName] else {
                        throw ExclusivesError.invalidTargetName(targetName)
                    }
                    let isWildcard = exclusiveFile.hasSuffix("/*") || exclusiveFile.hasSuffix("/.*")
                    if isWildcard {
                        let directoryPath = exclusiveFile.dropWildCards()
                        let filesInDirectory = target.filePaths.filter { $0.contains(directoryPath) }
                        if filesInDirectory.isEmpty {
                            throw ExclusivesError.invalidPathForTarget(targetName: targetName, path: exclusiveFile)
                        } else {
                            let filePaths = target.filePaths.subtracting(filesInDirectory)
                            let newTarget = Target(
                                name: target.name,
                                filePaths: filePaths,
                                dependencies: target.dependencies,
                                frameworks: target.frameworks
                            )
                            targetsWithoutExclusives[targetName] = newTarget
                        }
                    } else {
                        let filesInDirectory = target.filePaths.filter { $0.contains(exclusiveFile) }
                        if filesInDirectory.isEmpty {
                            throw ExclusivesError.invalidPathForTarget(targetName: targetName, path: exclusiveFile)
                        } else {
                            let filePaths = target.filePaths.subtracting(filesInDirectory)
                            let newTarget = Target(
                                name: target.name,
                                filePaths: filePaths,
                                dependencies: target.dependencies,
                                frameworks: target.frameworks
                            )
                            targetsWithoutExclusives[targetName] = newTarget
                        }
                    }
                }
                for exclusiveDependency in targetExclusive.dependencies ?? [] {
                    guard let target = targetsWithoutExclusives[targetName] else {
                        throw ExclusivesError.invalidTargetName(targetName)
                    }
                    let filteredDependencies = target.dependencies.filter { $0.contains(exclusiveDependency) }
                    if filteredDependencies.isEmpty {
                        throw ExclusivesError.invalidPathForTarget(targetName: targetName, path: exclusiveDependency)
                    } else {
                        let dependencies = target.dependencies.subtracting(filteredDependencies)
                        let newTarget = Target(
                            name: target.name,
                            filePaths: target.filePaths,
                            dependencies: dependencies,
                            frameworks: target.frameworks
                        )
                        targetsWithoutExclusives[targetName] = newTarget
                    }
                }
                for exclusiveFramework in targetExclusive.frameworks ?? [] {
                    guard let target = targetsWithoutExclusives[targetName] else {
                        throw ExclusivesError.invalidTargetName(targetName)
                    }
                    let filteredFrameworks = target.frameworks.filter { $0.contains(exclusiveFramework) }
                    if filteredFrameworks.isEmpty {
                        throw ExclusivesError.invalidPathForTarget(targetName: targetName, path: exclusiveFramework)
                    } else {
                        let frameworks = target.frameworks.subtracting(filteredFrameworks)
                        let newTarget = Target(
                            name: target.name,
                            filePaths: target.filePaths,
                            dependencies: target.dependencies,
                            frameworks: frameworks
                        )
                        targetsWithoutExclusives[targetName] = newTarget
                    }
                }
            }
        }
        for fileMembershipSet in fileMembershipSets {
            let fileMembershipTargetNames = fileMembershipSet.targets
            let fileMembershipTargetWithoutExclusives = targetsWithoutExclusives.filter { fileMembershipTargetNames.contains($0.key) }
            let diff = fileMembershipTargetWithoutExclusives.differenceTarget()
            let commaSeparatedTargetNames = fileMembershipTargetNames.joined(separator: ", ")
            if !diff.filePaths.isEmpty {
                print("Exclusive files found between targets \(commaSeparatedTargetNames):")
                for file in diff.filePaths {
                    print(" - \(file)")
                }
            }
            if !diff.dependencies.isEmpty {
                print("Exclusive dependencies found between targets \(commaSeparatedTargetNames):")
                for dependency in diff.dependencies {
                    print(" - \(dependency)")
                }
            }
            if !diff.frameworks.isEmpty {
                print("Exclusive frameworks found between targets \(commaSeparatedTargetNames):")
                for framework in diff.frameworks {
                    print(" - \(framework)")
                }
            }
            if diff.containsNotEmptySets {
                throw ExclusivesError.exclusiveEntriesFound(targetNames: commaSeparatedTargetNames)
            }
        }

        // Step 2
        // use forbiddenResourceSets to validate if we have any forbidden resources in targets
    }
}
