import Foundation

struct Category: Codable, Identifiable {
    var id: String
    var name: String
    var iconName: String
    var colorHex: String     
    var type: CategoryType
    var isDefault: Bool
}


enum CategoryType: String, Codable {
    case income
    case expense
}
