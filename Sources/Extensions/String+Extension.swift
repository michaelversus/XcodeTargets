import Foundation

extension String {
    func dropWildCards() -> String {
        if hasSuffix("/*") {
            return String(dropLast(1))
        } else if hasSuffix("/.*") {
            return String(dropLast(2))
        } else {
            return self
        }
    }
}
