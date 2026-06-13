import SwiftUI

struct AppDependencies {
    let apiClient: APIClient
    let authService: AuthService
    let vehicleService: VehicleService
    let maintenanceService: MaintenanceService
    let serviceOrderService: ServiceOrderService
    let marketplaceService: MarketplaceService
    let monthlyCostService: MonthlyCostService
    let adminPartsService: AdminPartsService
    let adminOrdersService: AdminOrdersService
    let adminServiceOrdersService: AdminServiceOrdersService

    static let live: AppDependencies = {
        let apiClient = APIClient()
        return AppDependencies(
            apiClient: apiClient,
            authService: AuthService(apiClient: apiClient),
            vehicleService: VehicleService(apiClient: apiClient),
            maintenanceService: MaintenanceService(apiClient: apiClient),
            serviceOrderService: ServiceOrderService(apiClient: apiClient),
            marketplaceService: MarketplaceService(apiClient: apiClient),
            monthlyCostService: MonthlyCostService(apiClient: apiClient),
            adminPartsService: AdminPartsService(apiClient: apiClient),
            adminOrdersService: AdminOrdersService(apiClient: apiClient),
            adminServiceOrdersService: AdminServiceOrdersService(apiClient: apiClient)
        )
    }()
}

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.live
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}

