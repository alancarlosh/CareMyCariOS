import Foundation

final class VehicleService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
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
