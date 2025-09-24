import Foundation

extension URL {
    enum Mock {
        static let exampleConfig = Bundle.module.url(forResource: "Example/xcode-targets", withExtension: "json")!
    }
}
