import Defaults
import Foundation

extension Defaults.Keys {
    static let localRequestTimeout = Key<TimeInterval>("localRequestTimeout", default: 60.0)
}