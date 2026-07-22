import Foundation

struct Category: Codable, Identifiable {
    var id: String
    var name: String
    var iconName: String       // SF Symbol name, e.g. "fork.knife"
    var colorHex: String       // Hex color string, e.g. "FF5733"
    var type: CategoryType
    var isDefault: Bool
}


enum CategoryType: String, Codable {
    case income
    case expense
}
