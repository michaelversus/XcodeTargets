//
//  ConfigurationLoaderError.swift
//  XcodeTargets
//
//  Created by Michalis Karagiorgos on 22/9/25.
//

enum ConfigurationLoaderError: Error, CustomStringConvertible, Equatable {
    case configurationFileNotFound(String)

    var description: String {
        switch self {
        case .configurationFileNotFound(let path):
            return "❌ Configuration file not found at path: \(path)"
        }
    }
}
