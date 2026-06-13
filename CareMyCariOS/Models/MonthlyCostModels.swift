import Foundation

struct MonthlyCostEstimate: Equatable, Hashable {
    let monthlyKm: Double
    let litersNeeded: Double
    let fuelCost: Double
    let maintenanceCost: Double
    let totalMonthlyCost: Double
}

struct MonthlyCostEstimateResponse: Decodable {
    let monthlyKm: Double
    let litersNeeded: Double
    let fuelCost: Double
    let maintenanceCost: Double
    let totalMonthlyCost: Double

    enum CodingKeys: String, CodingKey {
        case monthlyKm
        case monthlyKmSnake = "monthly_km"
        case litersNeeded
        case litersNeededSnake = "liters_needed"
        case fuelCost
        case fuelCostSnake = "fuel_cost"
        case maintenanceCost
        case maintenanceCostSnake = "maintenance_cost"
        case totalMonthlyCost
        case totalMonthlyCostSnake = "total_monthly_cost"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyKm = try container.decodeFlexibleDouble(.monthlyKm, .monthlyKmSnake)
        litersNeeded = try container.decodeFlexibleDouble(.litersNeeded, .litersNeededSnake)
        fuelCost = try container.decodeFlexibleDouble(.fuelCost, .fuelCostSnake)
        maintenanceCost = try container.decodeFlexibleDouble(.maintenanceCost, .maintenanceCostSnake)
        totalMonthlyCost = try container.decodeFlexibleDouble(.totalMonthlyCost, .totalMonthlyCostSnake)
    }

    var asMonthlyCostEstimate: MonthlyCostEstimate {
        MonthlyCostEstimate(
            monthlyKm: monthlyKm,
            litersNeeded: litersNeeded,
            fuelCost: fuelCost,
            maintenanceCost: maintenanceCost,
            totalMonthlyCost: totalMonthlyCost
        )
    }
}

private extension KeyedDecodingContainer where Key == MonthlyCostEstimateResponse.CodingKeys {
    func decodeFlexibleDouble(_ firstKey: Key, _ secondKey: Key) throws -> Double {
        if let value = try decodeIfPresent(Double.self, forKey: firstKey) {
            return value
        }
        return try decode(Double.self, forKey: secondKey)
    }
}
