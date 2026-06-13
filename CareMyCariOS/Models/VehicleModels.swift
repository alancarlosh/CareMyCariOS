import Foundation

struct Vehicle: Identifiable, Equatable {
    let id: String
    let make: String?
    let model: String?
    let year: Int?
    let color: String?
    let vehicleType: String?
    let transmission: String?
    let fuelType: String?
    let currentMileage: Double?
    let imageUrls: [String]

    var title: String {
        [make, model]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .nonEmpty ?? "Vehiculo sin nombre"
    }

    var subtitle: String {
        var parts: [String] = []
        if let year {
            parts.append(String(year))
        }
        if let color = color?.nonEmpty {
            parts.append(color)
        }
        return parts.isEmpty ? "Sin datos generales" : parts.joined(separator: " - ")
    }

    var detailRows: [(String, String)] {
        [
            ("Marca", make),
            ("Modelo", model),
            ("Ano", year.map(String.init)),
            ("Color", color),
            ("Tipo", vehicleType),
            ("Transmision", transmission),
            ("Combustible", fuelType),
            ("Kilometraje", currentMileage.map { NumberFormatter.vehicleMileage.string(from: NSNumber(value: $0)) ?? "\($0) km" })
        ]
        .compactMap { label, value in
            guard let value = value?.nonEmpty else { return nil }
            return (label, value)
        }
    }
}

struct VehicleListResponse: Decodable {
    let items: [VehicleDTO]
}

struct VehicleDetailResponse: Decodable {
    let vehicle: VehicleDTO
}

struct CreateVehicleRequest: Encodable {
    let catalogVehicleId: String?
    let make: String?
    let model: String?
    let year: Int
    let currentMileage: Int
    let color: String?
    let fuelType: String?
    let transmission: String?
    let vehicleType: String?

    enum CodingKeys: String, CodingKey {
        case catalogVehicleId = "catalog_vehicle_id"
        case make
        case model
        case year
        case currentMileage = "current_mileage"
        case color
        case fuelType = "fuel_type"
        case transmission
        case vehicleType = "vehicle_type"
    }
}

struct VehicleDTO: Decodable {
    let id: String
    let make: String?
    let model: String?
    let year: Int?
    let color: String?
    let vehicleType: String?
    let transmission: String?
    let fuelType: String?
    let currentMileage: Double?
    let imageUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case make
        case model
        case year
        case color
        case vehicleType = "vehicle_type"
        case transmission
        case fuelType = "fuel_type"
        case currentMileage = "current_mileage"
        case imageUrls = "image_urls"
    }

    var asVehicle: Vehicle {
        Vehicle(
            id: id,
            make: make,
            model: model,
            year: year,
            color: color,
            vehicleType: vehicleType,
            transmission: transmission,
            fuelType: fuelType,
            currentMileage: currentMileage,
            imageUrls: imageUrls ?? []
        )
    }
}

struct CatalogVehicle: Identifiable, Equatable {
    let id: String
    let make: String
    let model: String
    let vehicleType: String
    let fuelType: String
    let transmission: String
    let imageUrls: [String]

    var title: String {
        "\(make) \(model)"
    }
}

struct CatalogVehicleListResponse: Decodable {
    let items: [CatalogVehicleDTO]
}

struct CatalogVehicleDTO: Decodable {
    let id: String
    let make: String
    let model: String
    let vehicleType: String
    let fuelType: String
    let transmission: String
    let imageUrls: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case make
        case model
        case vehicleType = "vehicle_type"
        case fuelType = "fuel_type"
        case transmission
        case imageUrls = "image_urls"
    }

    var asCatalogVehicle: CatalogVehicle {
        CatalogVehicle(
            id: id,
            make: make,
            model: model,
            vehicleType: vehicleType,
            fuelType: fuelType,
            transmission: transmission,
            imageUrls: imageUrls ?? []
        )
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension NumberFormatter {
    static let vehicleMileage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = " km"
        return formatter
    }()
}
