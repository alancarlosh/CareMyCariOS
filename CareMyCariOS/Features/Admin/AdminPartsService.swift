import Foundation

final class AdminPartsService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func listParts(query: String?, category: String?, page: Int = 1, limit: Int = 50) async throws -> (items: [Part], total: Int) {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        let response: PartListResponse = try await apiClient.get("api/parts", queryItems: queryItems)
        return (response.items.map(\.asPart), response.total)
    }

    func createPart(request: CreatePartRequest) async throws -> Part {
        let response: PartDetailResponse = try await apiClient.post("api/parts", body: request)
        return response.part.asPart
    }

    func updatePart(id: String, request: UpdatePartRequest) async throws -> Part {
        let response: PartDetailResponse = try await apiClient.put("api/parts/\(id)", body: request)
        return response.part.asPart
    }

    func deletePart(id: String) async throws {
        let _: EmptyResponse = try await apiClient.delete("api/parts/\(id)")
    }
}
