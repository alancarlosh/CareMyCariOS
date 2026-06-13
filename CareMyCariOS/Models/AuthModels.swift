import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let user: UserDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String?
}

struct RegisterResponse: Decodable {
    let user: UserDTO
}
