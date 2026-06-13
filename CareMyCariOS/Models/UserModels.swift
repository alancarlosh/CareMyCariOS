import Foundation

struct User: Codable, Equatable, Identifiable {
    let id: String
    let email: String?
    let name: String?
    let role: String?
}

struct UserDTO: Decodable {
    let id: String
    let email: String?
    let name: String?
    let role: String?

    var asUser: User {
        User(id: id, email: email, name: name, role: role)
    }
}
