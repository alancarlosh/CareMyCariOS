import Foundation

struct AuthUseCase {
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        try await repository.login(email: email, password: password)
    }

    func register(email: String, password: String, name: String?) async throws -> RegisterResponse {
        try await repository.register(email: email, password: password, name: name)
    }
}

struct VehicleUseCase {
    private let repository: any VehicleRepository

    init(repository: any VehicleRepository) {
        self.repository = repository
    }

    func listVehicles() async throws -> [Vehicle] {
        try await repository.listVehicles()
    }

    func getVehicle(id: String) async throws -> Vehicle {
        try await repository.getVehicle(id: id)
    }

    func listCatalogVehicles() async throws -> [CatalogVehicle] {
        try await repository.listCatalogVehicles()
    }

    func createVehicle(request: CreateVehicleRequest) async throws -> Vehicle {
        try await repository.createVehicle(request: request)
    }

    func updateMileage(vehicleId: String, mileage: Int) async throws -> Vehicle {
        try await repository.updateMileage(vehicleId: vehicleId, mileage: mileage)
    }

    func deleteVehicle(id: String) async throws {
        try await repository.deleteVehicle(id: id)
    }
}

struct MaintenanceUseCase {
    private let repository: any MaintenanceRepository

    init(repository: any MaintenanceRepository) {
        self.repository = repository
    }

    func listMaintenance(vehicleId: String) async throws -> [MaintenanceRecord] {
        try await repository.listMaintenance(vehicleId: vehicleId)
    }

    func listRecommendations(vehicleId: String) async throws -> [MaintenanceRecommendation] {
        try await repository.listRecommendations(vehicleId: vehicleId)
    }

    func createMaintenance(request: CreateMaintenanceRequest) async throws -> MaintenanceRecord {
        try await repository.createMaintenance(request: request)
    }

    func updateMaintenance(id: String, request: UpdateMaintenanceRequest) async throws -> MaintenanceRecord {
        try await repository.updateMaintenance(id: id, request: request)
    }

    func deleteMaintenance(id: String) async throws {
        try await repository.deleteMaintenance(id: id)
    }
}

struct ServiceOrderUseCase {
    private let repository: any ServiceOrderRepository

    init(repository: any ServiceOrderRepository) {
        self.repository = repository
    }

    func listMyServiceOrders(vehicleId: String) async throws -> [ServiceOrder] {
        try await repository.listMyServiceOrders(vehicleId: vehicleId)
    }

    func quote(vehicleId: String, serviceType: String) async throws -> ServiceQuote {
        try await repository.quote(vehicleId: vehicleId, serviceType: serviceType)
    }

    func create(request: CreateServiceOrderRequest) async throws -> ServiceOrder {
        try await repository.create(request: request)
    }
}

struct MarketplaceUseCase {
    private let repository: any MarketplaceRepository

    init(repository: any MarketplaceRepository) {
        self.repository = repository
    }

    func listProducts(query: String?, category: String?, page: Int = 1, limit: Int = 50) async throws -> (items: [Part], total: Int) {
        try await repository.listProducts(query: query, category: category, page: page, limit: limit)
    }

    func purchase(partId: String, quantity: Int) async throws -> Order {
        try await repository.purchase(partId: partId, quantity: quantity)
    }

    func listMyPurchases(status: String? = nil, page: Int = 1, limit: Int = 50) async throws -> (items: [Order], total: Int) {
        try await repository.listMyPurchases(status: status, page: page, limit: limit)
    }
}

struct MonthlyCostUseCase {
    private let repository: any MonthlyCostRepository

    init(repository: any MonthlyCostRepository) {
        self.repository = repository
    }

    func estimate(monthlyKm: Double, kmPerLiter: Double, fuelPrice: Double, maintenancePerKm: Double) async throws -> MonthlyCostEstimate {
        try await repository.estimate(monthlyKm: monthlyKm, kmPerLiter: kmPerLiter, fuelPrice: fuelPrice, maintenancePerKm: maintenancePerKm)
    }
}

struct AdminPartsUseCase {
    private let repository: any AdminPartsRepository

    init(repository: any AdminPartsRepository) {
        self.repository = repository
    }

    func listParts(query: String?, category: String?, page: Int = 1, limit: Int = 50) async throws -> (items: [Part], total: Int) {
        try await repository.listParts(query: query, category: category, page: page, limit: limit)
    }

    func createPart(request: CreatePartRequest) async throws -> Part {
        try await repository.createPart(request: request)
    }

    func updatePart(id: String, request: UpdatePartRequest) async throws -> Part {
        try await repository.updatePart(id: id, request: request)
    }

    func deletePart(id: String) async throws {
        try await repository.deletePart(id: id)
    }
}

struct AdminOrdersUseCase {
    private let repository: any AdminOrdersRepository

    init(repository: any AdminOrdersRepository) {
        self.repository = repository
    }

    func listOrders(query: String?, status: String?, page: Int = 1, limit: Int = 50) async throws -> OrderListResponse {
        try await repository.listOrders(query: query, status: status, page: page, limit: limit)
    }

    func dailyReport(date: String? = nil) async throws -> SalesDailyReport {
        try await repository.dailyReport(date: date)
    }

    func dailyReportPDF(date: String? = nil) async throws -> Data {
        try await repository.dailyReportPDF(date: date)
    }

    func createOrder(request: CreateOrderRequest) async throws -> Order {
        try await repository.createOrder(request: request)
    }

    func updateStatus(orderId: String, status: String) async throws -> Order {
        try await repository.updateStatus(orderId: orderId, status: status)
    }
}

struct AdminServiceOrdersUseCase {
    private let repository: any AdminServiceOrdersRepository

    init(repository: any AdminServiceOrdersRepository) {
        self.repository = repository
    }

    func listOrders(status: String? = nil) async throws -> [ServiceOrder] {
        try await repository.listOrders(status: status)
    }

    func start(orderId: String, agencyNotes: String?) async throws -> ServiceOrder {
        try await repository.start(orderId: orderId, agencyNotes: agencyNotes)
    }

    func complete(orderId: String, completionToken: String, finalCost: Double?, agencyNotes: String?, mileage: Int?) async throws -> ServiceOrder {
        try await repository.complete(orderId: orderId, completionToken: completionToken, finalCost: finalCost, agencyNotes: agencyNotes, mileage: mileage)
    }

    func cancel(orderId: String, agencyNotes: String?) async throws -> ServiceOrder {
        try await repository.cancel(orderId: orderId, agencyNotes: agencyNotes)
    }

    func reportPDF(from: String?, to: String?, status: String? = "FINALIZADO") async throws -> Data {
        try await repository.reportPDF(from: from, to: to, status: status)
    }
}

