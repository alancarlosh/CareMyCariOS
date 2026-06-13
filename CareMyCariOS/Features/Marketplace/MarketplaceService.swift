import Foundation

final class MarketplaceService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func listProducts(query: String?, category: String?, page: Int = 1, limit: Int = 50) async throws -> (items: [Part], total: Int) {
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

        let response: PartListResponse = try await apiClient.get(
            "api/orders/marketplace/products",
            queryItems: queryItems
        )
        return (response.items.map(\.asPart), response.total)
    }

    func purchase(partId: String, quantity: Int) async throws -> Order {
        let response: OrderDetailResponse = try await apiClient.post(
            "api/orders/marketplace/purchase",
            body: MarketplacePurchaseRequest(partId: partId, quantity: quantity)
        )
        return response.order.asOrder
    }

    func listMyPurchases(status: String? = nil, page: Int = 1, limit: Int = 50) async throws -> (items: [Order], total: Int) {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }

        let response: OrderListResponse = try await apiClient.get(
            "api/orders/purchases/my",
            queryItems: queryItems
        )
        return (response.items.map(\.asOrder), response.total)
    }
}
