import Foundation

final class APIAuthRepository: AuthRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

final class APIVehicleRepository: VehicleRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listVehicles() async throws -> [Vehicle] {
        let response: VehicleListResponse = try await apiClient.get("api/vehicles")
        return response.items.map(\.asVehicle)
    }

    func getVehicle(id: String) async throws -> Vehicle {
        let response: VehicleDetailResponse = try await apiClient.get("api/vehicles/\(id)")
        return response.vehicle.asVehicle
    }

    func listCatalogVehicles() async throws -> [CatalogVehicle] {
        let response: CatalogVehicleListResponse = try await apiClient.get("api/catalog/vehicles")
        return response.items.map(\.asCatalogVehicle)
    }

    func createVehicle(request: CreateVehicleRequest) async throws -> Vehicle {
        let response: VehicleDetailResponse = try await apiClient.post("api/vehicles", body: request)
        return response.vehicle.asVehicle
    }

    func updateMileage(vehicleId: String, mileage: Int) async throws -> Vehicle {
        let response: VehicleDetailResponse = try await apiClient.put(
            "api/vehicles/\(vehicleId)",
            body: ["current_mileage": mileage]
        )
        return response.vehicle.asVehicle
    }

    func deleteVehicle(id: String) async throws {
        let _: EmptyResponse = try await apiClient.delete("api/vehicles/\(id)")
    }
}

final class APIMaintenanceRepository: MaintenanceRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func listMaintenance(vehicleId: String) async throws -> [MaintenanceRecord] {
        let response: MaintenanceListResponse = try await apiClient.get("api/maintenance/\(vehicleId)")
        return response.items.map(\.asMaintenanceRecord)
    }

    func listRecommendations(vehicleId: String) async throws -> [MaintenanceRecommendation] {
        let response: MaintenanceRecommendationsResponse = try await apiClient.get("api/maintenance/insights/recommendations/\(vehicleId)")
        return response.recommendations.map(\.asMaintenanceRecommendation)
    }

    func createMaintenance(request: CreateMaintenanceRequest) async throws -> MaintenanceRecord {
        let response: MaintenanceDetailResponse = try await apiClient.post("api/maintenance", body: request)
        return response.maintenance.asMaintenanceRecord
    }

    func updateMaintenance(id: String, request: UpdateMaintenanceRequest) async throws -> MaintenanceRecord {
        let response: MaintenanceDetailResponse = try await apiClient.put("api/maintenance/\(id)", body: request)
        return response.maintenance.asMaintenanceRecord
    }

    func deleteMaintenance(id: String) async throws {
        let _: EmptyResponse = try await apiClient.delete("api/maintenance/\(id)")
    }
}

final class APIServiceOrderRepository: ServiceOrderRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

final class APIMarketplaceRepository: MarketplaceRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

final class APIMonthlyCostRepository: MonthlyCostRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func estimate(monthlyKm: Double, kmPerLiter: Double, fuelPrice: Double, maintenancePerKm: Double) async throws -> MonthlyCostEstimate {
        let response: MonthlyCostEstimateResponse = try await apiClient.get(
            "api/tools/monthly-cost",
            queryItems: [
                URLQueryItem(name: "monthlyKm", value: String(monthlyKm)),
                URLQueryItem(name: "kmPerLiter", value: String(kmPerLiter)),
                URLQueryItem(name: "fuelPrice", value: String(fuelPrice)),
                URLQueryItem(name: "maintenancePerKm", value: String(maintenancePerKm))
            ]
        )
        return response.asMonthlyCostEstimate
    }
}

final class APIAdminPartsRepository: AdminPartsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

final class APIAdminOrdersRepository: AdminOrdersRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

final class APIAdminServiceOrdersRepository: AdminServiceOrdersRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
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

