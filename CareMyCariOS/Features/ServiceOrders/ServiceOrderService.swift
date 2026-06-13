import Foundation

final class ServiceOrderService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func listMyServiceOrders(vehicleId: String) async throws -> [ServiceOrder] {
        let response: ServiceOrderListResponse = try await apiClient.get("api/service-orders/my")
        return response.items
            .map(\.asServiceOrder)
            .filter { $0.vehicleId == vehicleId }
    }

    func quote(vehicleId: String, serviceType: String) async throws -> ServiceQuote {
        let response: ServiceOrderQuoteResponse = try await apiClient.post(
            "api/service-orders/quote/\(vehicleId)",
            body: ServiceOrderQuoteRequest(serviceType: serviceType)
        )
        return response.quote.asServiceQuote
    }

    func create(request: CreateServiceOrderRequest) async throws -> ServiceOrder {
        let response: ServiceOrderDetailResponse = try await apiClient.post("api/service-orders", body: request)
        return response.order.asServiceOrder
    }
}
