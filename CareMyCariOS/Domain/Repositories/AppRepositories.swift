import Foundation

protocol AuthRepository {
    func login(email: String, password: String) async throws -> LoginResponse
    func register(email: String, password: String, name: String?) async throws -> RegisterResponse
}

protocol VehicleRepository {
    func listVehicles() async throws -> [Vehicle]
    func getVehicle(id: String) async throws -> Vehicle
    func listCatalogVehicles() async throws -> [CatalogVehicle]
    func createVehicle(request: CreateVehicleRequest) async throws -> Vehicle
    func updateMileage(vehicleId: String, mileage: Int) async throws -> Vehicle
    func deleteVehicle(id: String) async throws
}

protocol MaintenanceRepository {
    func listMaintenance(vehicleId: String) async throws -> [MaintenanceRecord]
    func listRecommendations(vehicleId: String) async throws -> [MaintenanceRecommendation]
    func createMaintenance(request: CreateMaintenanceRequest) async throws -> MaintenanceRecord
    func updateMaintenance(id: String, request: UpdateMaintenanceRequest) async throws -> MaintenanceRecord
    func deleteMaintenance(id: String) async throws
}

protocol ServiceOrderRepository {
    func listMyServiceOrders(vehicleId: String) async throws -> [ServiceOrder]
    func quote(vehicleId: String, serviceType: String) async throws -> ServiceQuote
    func create(request: CreateServiceOrderRequest) async throws -> ServiceOrder
}

protocol MarketplaceRepository {
    func listProducts(query: String?, category: String?, page: Int, limit: Int) async throws -> (items: [Part], total: Int)
    func purchase(partId: String, quantity: Int) async throws -> Order
    func listMyPurchases(status: String?, page: Int, limit: Int) async throws -> (items: [Order], total: Int)
}

protocol MonthlyCostRepository {
    func estimate(monthlyKm: Double, kmPerLiter: Double, fuelPrice: Double, maintenancePerKm: Double) async throws -> MonthlyCostEstimate
}

protocol AdminPartsRepository {
    func listParts(query: String?, category: String?, page: Int, limit: Int) async throws -> (items: [Part], total: Int)
    func createPart(request: CreatePartRequest) async throws -> Part
    func updatePart(id: String, request: UpdatePartRequest) async throws -> Part
    func deletePart(id: String) async throws
}

protocol AdminOrdersRepository {
    func listOrders(query: String?, status: String?, page: Int, limit: Int) async throws -> OrderListResponse
    func dailyReport(date: String?) async throws -> SalesDailyReport
    func dailyReportPDF(date: String?) async throws -> Data
    func createOrder(request: CreateOrderRequest) async throws -> Order
    func updateStatus(orderId: String, status: String) async throws -> Order
}

protocol AdminServiceOrdersRepository {
    func listOrders(status: String?) async throws -> [ServiceOrder]
    func start(orderId: String, agencyNotes: String?) async throws -> ServiceOrder
    func complete(orderId: String, completionToken: String, finalCost: Double?, agencyNotes: String?, mileage: Int?) async throws -> ServiceOrder
    func cancel(orderId: String, agencyNotes: String?) async throws -> ServiceOrder
    func reportPDF(from: String?, to: String?, status: String?) async throws -> Data
}

