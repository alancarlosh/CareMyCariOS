import Foundation

final class MaintenanceService {
    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
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
