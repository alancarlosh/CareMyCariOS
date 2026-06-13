import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case backend(String)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Respuesta invalida del servidor."
        case .unauthorized:
            return "Tu sesion expiro. Inicia sesion nuevamente."
        case .backend(let message):
            return message
        case .decoding:
            return "No se pudo leer la respuesta del servidor."
        case .transport:
            return "Error de conexion."
        }
    }
}

struct EmptyResponse: Decodable {}

final class APIClient {
    private let baseURL: URL
    private let tokenStore: KeychainTokenStore
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        baseURL: URL = AppConfig.apiBaseURL,
        tokenStore: KeychainTokenStore = .shared,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.tokenStore = tokenStore
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func get<Response: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await send(path, method: "GET", queryItems: queryItems, body: Optional<Data>.none, requiresAuth: requiresAuth)
    }

    func getData(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        requiresAuth: Bool = true
    ) async throws -> Data {
        try await sendData(path, method: "GET", queryItems: queryItems, body: Optional<Data>.none, requiresAuth: requiresAuth)
    }

    func post<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await send(path, method: "POST", body: data, requiresAuth: requiresAuth)
    }

    func put<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await send(path, method: "PUT", body: data, requiresAuth: requiresAuth)
    }

    func patch<Request: Encodable, Response: Decodable>(
        _ path: String,
        body: Request,
        requiresAuth: Bool = true
    ) async throws -> Response {
        let data = try encoder.encode(body)
        return try await send(path, method: "PATCH", body: data, requiresAuth: requiresAuth)
    }

    func delete<Response: Decodable>(
        _ path: String,
        requiresAuth: Bool = true
    ) async throws -> Response {
        try await send(path, method: "DELETE", body: Optional<Data>.none, requiresAuth: requiresAuth)
    }

    private func send<Response: Decodable>(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data?,
        requiresAuth: Bool
    ) async throws -> Response {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth, let token = tokenStore.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                tokenStore.clear()
                throw APIError.unauthorized
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.backend(Self.backendMessage(from: data) ?? "Error del servidor.")
            }

            if Response.self == EmptyResponse.self {
                return EmptyResponse() as! Response
            }

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error)
        }
    }

    private func sendData(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: Data?,
        requiresAuth: Bool
    ) async throws -> Data {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth, let token = tokenStore.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode == 401 {
                tokenStore.clear()
                throw APIError.unauthorized
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw APIError.backend(Self.backendMessage(from: data) ?? "Error del servidor.")
            }

            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error)
        }
    }

    private static func backendMessage(from data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if let error = object["error"] as? String, !error.isEmpty {
            return error
        }

        if let errors = object["errors"] as? [String], !errors.isEmpty {
            return errors.joined(separator: "\n")
        }

        return nil
    }
}
