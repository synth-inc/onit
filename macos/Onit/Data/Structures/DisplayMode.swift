import Defaults

enum DisplayMode: String, CaseIterable, Codable, Defaults.Serializable {
    case pinned
    case tethered
    case conventional
}
