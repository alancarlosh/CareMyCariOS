import Foundation

final class AdminOrdersService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func listOrders(query: String?, status: String?, page: Int = 1, limit: Int = 50) async throws -> OrderListResponse {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        if let status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }

        return try await apiClient.get("api/orders", queryItems: queryItems)
    }

    func dailyReport(date: String? = nil) async throws -> SalesDailyReport {
        let queryItems = date.map { [URLQueryItem(name: "date", value: $0)] } ?? []
        let response: SalesDailyReportResponse = try await apiClient.get(
            "api/orders/sales/daily-report",
            queryItems: queryItems
        )
        return response.report.asSalesDailyReport
    }

    func dailyReportPDF(date: String? = nil) async throws -> Data {
        let queryItems = date.map { [URLQueryItem(name: "date", value: $0)] } ?? []
        return try await apiClient.getData(
            "api/orders/sales/daily-report/pdf",
            queryItems: queryItems
        )
    }

    func createOrder(request: CreateOrderRequest) async throws -> Order {
        let response: OrderDetailResponse = try await apiClient.post("api/orders", body: request)
        return response.order.asOrder
    }

    func updateStatus(orderId: String, status: String) async throws -> Order {
        let response: OrderDetailResponse = try await apiClient.put(
            "api/orders/\(orderId)",
            body: UpdateOrderStatusRequest(status: status)
        )
        return response.order.asOrder
    }
}
