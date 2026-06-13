import Foundation

struct MaintenanceRecord: Identifiable, Equatable, Hashable {
    let id: String
    let serviceType: String?
    let description: String?
    let cost: Double?
    let mileage: Int?
    let serviceDate: String?

    var title: String {
        serviceType?.nonEmpty ?? "Servicio"
    }

    var subtitle: String {
        serviceDate?.nonEmpty ?? "Sin fecha"
    }
}

struct MaintenanceRecordDTO: Decodable {
    let id: String
    let serviceType: String?
    let description: String?
    let cost: Double?
    let mileage: Int?
    let serviceDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case serviceType = "service_type"
        case description
        case cost
        case mileage
        case serviceDate = "service_date"
    }

    var asMaintenanceRecord: MaintenanceRecord {
        MaintenanceRecord(
            id: id,
            serviceType: serviceType,
            description: description,
            cost: cost,
            mileage: mileage,
            serviceDate: serviceDate
        )
    }
}

struct MaintenanceListResponse: Decodable {
    let items: [MaintenanceRecordDTO]
}

struct MaintenanceDetailResponse: Decodable {
    let maintenance: MaintenanceRecordDTO
}

struct CreateMaintenanceRequest: Encodable {
    let vehicleId: String
    let serviceType: String
    let serviceDate: String
    let description: String?
    let cost: Double?
    let mileage: Int?

    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case serviceType = "service_type"
        case serviceDate = "service_date"
        case description
        case cost
        case mileage
    }
}

struct UpdateMaintenanceRequest: Encodable {
    let serviceType: String?
    let serviceDate: String?
    let description: String?
    let cost: Double?
    let mileage: Int?

    enum CodingKeys: String, CodingKey {
        case serviceType = "service_type"
        case serviceDate = "service_date"
        case description
        case cost
        case mileage
    }
}

struct MaintenanceRecommendationsResponse: Decodable {
    let vehicleId: String
    let recommendations: [MaintenanceRecommendationDTO]

    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case recommendations
    }
}

struct MaintenanceRecommendationDTO: Decodable {
    let serviceKey: String
    let serviceLabel: String
    let dueDate: String
    let dueKm: Int
    let daysLeft: Int
    let kmLeft: Int
    let status: String
    let recommended: Bool

    enum CodingKeys: String, CodingKey {
        case serviceKey = "service_key"
        case serviceLabel = "service_label"
        case dueDate = "due_date"
        case dueKm = "due_km"
        case daysLeft = "days_left"
        case kmLeft = "km_left"
        case status
        case recommended
    }

    var asMaintenanceRecommendation: MaintenanceRecommendation {
        MaintenanceRecommendation(
            serviceKey: serviceKey,
            serviceLabel: serviceLabel,
            dueDate: dueDate,
            dueKm: dueKm,
            daysLeft: daysLeft,
            kmLeft: kmLeft,
            status: status,
            recommended: recommended
        )
    }
}

struct MaintenanceRecommendation: Identifiable, Equatable, Hashable {
    var id: String { serviceKey }
    let serviceKey: String
    let serviceLabel: String
    let dueDate: String
    let dueKm: Int
    let daysLeft: Int
    let kmLeft: Int
    let status: String
    let recommended: Bool
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
