import SwiftUI

struct AppDependencies {
    let apiClient: APIClient
    let authUseCase: AuthUseCase
    let vehicleUseCase: VehicleUseCase
    let maintenanceUseCase: MaintenanceUseCase
    let serviceOrderUseCase: ServiceOrderUseCase
    let marketplaceUseCase: MarketplaceUseCase
    let monthlyCostUseCase: MonthlyCostUseCase
    let adminPartsUseCase: AdminPartsUseCase
    let adminOrdersUseCase: AdminOrdersUseCase
    let adminServiceOrdersUseCase: AdminServiceOrdersUseCase

    static let live: AppDependencies = {
        let apiClient = APIClient()
        return AppDependencies(
            apiClient: apiClient,
            authUseCase: AuthUseCase(repository: APIAuthRepository(apiClient: apiClient)),
            vehicleUseCase: VehicleUseCase(repository: APIVehicleRepository(apiClient: apiClient)),
            maintenanceUseCase: MaintenanceUseCase(repository: APIMaintenanceRepository(apiClient: apiClient)),
            serviceOrderUseCase: ServiceOrderUseCase(repository: APIServiceOrderRepository(apiClient: apiClient)),
            marketplaceUseCase: MarketplaceUseCase(repository: APIMarketplaceRepository(apiClient: apiClient)),
            monthlyCostUseCase: MonthlyCostUseCase(repository: APIMonthlyCostRepository(apiClient: apiClient)),
            adminPartsUseCase: AdminPartsUseCase(repository: APIAdminPartsRepository(apiClient: apiClient)),
            adminOrdersUseCase: AdminOrdersUseCase(repository: APIAdminOrdersRepository(apiClient: apiClient)),
            adminServiceOrdersUseCase: AdminServiceOrdersUseCase(repository: APIAdminServiceOrdersRepository(apiClient: apiClient))
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
