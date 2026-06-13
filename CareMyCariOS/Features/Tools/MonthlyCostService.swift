import Foundation

final class MonthlyCostService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
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
