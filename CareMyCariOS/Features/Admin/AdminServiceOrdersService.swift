import Foundation

final class AdminServiceOrdersService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func listOrders(status: String? = nil) async throws -> [ServiceOrder] {
        let queryItems = status.map { [URLQueryItem(name: "status", value: $0)] } ?? []
        let response: ServiceOrderListResponse = try await apiClient.get(
            "api/service-orders",
            queryItems: queryItems
        )
        return response.items.map(\.asServiceOrder)
    }

    func start(orderId: String, agencyNotes: String?) async throws -> ServiceOrder {
        let response: ServiceOrderDetailResponse = try await apiClient.patch(
            "api/service-orders/\(orderId)/start",
            body: StartServiceOrderRequest(agencyNotes: agencyNotes)
        )
        return response.order.asServiceOrder
    }

    func complete(orderId: String, completionToken: String, finalCost: Double?, agencyNotes: String?, mileage: Int?) async throws -> ServiceOrder {
        let response: ServiceOrderDetailResponse = try await apiClient.patch(
            "api/service-orders/\(orderId)/complete",
            body: CompleteServiceOrderRequest(
                completionToken: completionToken,
                finalCost: finalCost,
                agencyNotes: agencyNotes,
                mileage: mileage
            )
        )
        return response.order.asServiceOrder
    }

    func cancel(orderId: String, agencyNotes: String?) async throws -> ServiceOrder {
        let response: ServiceOrderDetailResponse = try await apiClient.patch(
            "api/service-orders/\(orderId)/cancel",
            body: CancelServiceOrderRequest(agencyNotes: agencyNotes)
        )
        return response.order.asServiceOrder
    }

    func reportPDF(from: String?, to: String?, status: String? = "FINALIZADO") async throws -> Data {
        var queryItems = [URLQueryItem]()
        if let from, !from.isEmpty {
            queryItems.append(URLQueryItem(name: "from", value: from))
        }
        if let to, !to.isEmpty {
            queryItems.append(URLQueryItem(name: "to", value: to))
        }
        if let status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await apiClient.getData("api/service-orders/report", queryItems: queryItems)
    }
}
