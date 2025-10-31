<p align="center">
    <img src="https://img.shields.io/badge/Swift-6.0-red.svg" />
    <img src="https://codecov.io/gh/michaelversus/XcodeTargets/graph/badge.svg?token=HH7KVALXSY"/>
</p>

<p align="center">
    <img src="logo/xcodeTargets_logo.png" alt="Xcode Targets logo" />
</p>

# 🎯 XcodeTargets
An SPM CLI tool that validates multiple Xcode project targets for common files, duplicate references and forbidden resources.

## 🛠️ Instalation

```bash
brew tap michaelversus/xcodetargets https://github.com/michaelversus/XcodeTargets.git
brew install xcodetargets
```

## ⚙️ Command line flags
- `-c` lets you specify a path to your .xcode-targets.json configuration file.
- `-r` sets the path XcodeTargets should scan. This defaults to your current working directory.
- `-v` enables verbose output. Default value is false.
- `-e` enables error only output. Default value is false. (Practical for CICD)

## ⚙️ Configuration
You can customize the behavior of **XcodeTargets** by creating a **.xcode-targets.json** file inside the directory you want to scan.

Example:
```json
 {
    "name": "MyProject",
    "fileMembershipSets": [
        {
            "targets": [
                "App", 
                "AppStaging", 
                "AppProd"
            ],
            "exclusive": {
                "AppStaging": {
                    "files": [
                        "Config/Staging/*", 
                        "Features/DebugPanel/"
                    ],
                    "dependencies": ["StagingAnalytics"],
                    "frameworks": ["StagingSDK"]
                 },
                "AppProd": {
                    "files": ["Config/Prod/.*"],
                    "dependencies": ["ProdAnalytics"],
                    "frameworks": ["ProdSDK"]
                }
            }
        },
        {
            "targets": [
                "Widget", 
                "WidgetExtension"
            ],
            "exclusive": {
                "WidgetExtension": {
                    "files": ["WidgetExtensionSpecific/*"],
                    "dependencies": ["WidgetExtensionSupport"],
                    "frameworks": []
                }
            }
        }
    ],
    "forbiddenResourceSets": [
        {
            "targets": ["App", "AppStaging", "AppProd"],
            "paths": ["/Debug/", "Temporary/"]
        },
        {
            "targets": ["Widget"],
            "paths": ["LargeAssets/"]
        }
    ],
    "duplicatesValidationExcludedTargets": ["Tests", "UITests"]
}
```

- **fileMembershipSets** validates that Xcode project targets contains same files. You can exclude files using the exclusive
- **forbiddenResourceSets** throws errors when files contain specific subpaths. (For example __Snapshots__ to ensure that snapshot tests images are not included inside your binary for distribution)
- **duplicatesValidationExcludedTargets** you can add the Xcode project targets that you want to exclude from duplicate references validation.

## 🚀 Usage
```bash
xcodetargets -c path/to/.xcode-targets.json -r /path/to/project
```

## Credits
XcodeTargets is build on top of
- tuist's [XcodeProj](https://github.com/tuist/XcodeProj) library for parsing the xcodeproj file, which is available under the MIT license.

The implementation is inspired from the below ruby script:
- [xcode-same-targets](https://github.com/smirn0v/xcode-same-targets)

Swift, the Swift logo, and Xcode are trademarks of Apple Inc., registered in the U.S. and other countries.

## 🤝 Contributions

Contributions are more than welcome!
