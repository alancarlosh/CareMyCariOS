import Foundation

final class AuthService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password
        )
        return try await apiClient.post("api/auth/login", body: request, requiresAuth: false)
    }

    func register(email: String, password: String, name: String?) async throws -> RegisterResponse {
        let trimmedName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = RegisterRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            name: trimmedName?.isEmpty == true ? nil : trimmedName
        )
        return try await apiClient.post("api/auth/register", body: request, requiresAuth: false)
    }
}
