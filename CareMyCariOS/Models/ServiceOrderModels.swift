import Foundation

struct CreateServiceOrderRequest: Encodable {
    let vehicleId: String
    let serviceType: String
    let scheduledDate: String
    let estimatedCost: Double?
    let userNotes: String?

    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case serviceType = "service_type"
        case scheduledDate = "scheduled_date"
        case estimatedCost = "estimated_cost"
        case userNotes = "user_notes"
    }
}

struct StartServiceOrderRequest: Encodable {
    let agencyNotes: String?

    enum CodingKeys: String, CodingKey {
        case agencyNotes = "agency_notes"
    }
}

struct CompleteServiceOrderRequest: Encodable {
    let completionToken: String
    let finalCost: Double?
    let agencyNotes: String?
    let mileage: Int?

    enum CodingKeys: String, CodingKey {
        case completionToken = "completion_token"
        case finalCost = "final_cost"
        case agencyNotes = "agency_notes"
        case mileage
    }
}

struct CancelServiceOrderRequest: Encodable {
    let agencyNotes: String?

    enum CodingKeys: String, CodingKey {
        case agencyNotes = "agency_notes"
    }
}

struct ServiceOrderListResponse: Decodable {
    let items: [ServiceOrderDTO]
}

struct ServiceOrderDetailResponse: Decodable {
    let order: ServiceOrderDTO
}

struct ServiceOrderQuoteRequest: Encodable {
    let serviceType: String

    enum CodingKeys: String, CodingKey {
        case serviceType = "service_type"
    }
}

struct ServiceOrderQuoteResponse: Decodable {
    let vehicleId: String
    let serviceType: String
    let quote: ServiceQuoteDTO

    enum CodingKeys: String, CodingKey {
        case vehicleId = "vehicle_id"
        case serviceType = "service_type"
        case quote
    }
}

struct ServiceQuoteDTO: Decodable {
    let serviceKey: String
    let prediction: ServiceQuotePredictionDTO?
    let products: [ServiceQuoteProductDTO]?
    let productsTotalMxn: Double?
    let laborTotalMxn: Double?
    let suggestedTotalMxn: Double?

    enum CodingKeys: String, CodingKey {
        case serviceKey = "service_key"
        case prediction
        case products
        case productsTotalMxn = "products_total_mxn"
        case laborTotalMxn = "labor_total_mxn"
        case suggestedTotalMxn = "suggested_total_mxn"
    }

    var asServiceQuote: ServiceQuote {
        ServiceQuote(
            serviceKey: serviceKey,
            modelUsed: prediction?.modelUsed ?? "",
            estimatedCostMxn: prediction?.estimatedCostMxn ?? 0,
            products: products?.map(\.asServiceQuoteProduct) ?? [],
            productsTotalMxn: productsTotalMxn ?? 0,
            laborTotalMxn: laborTotalMxn ?? 0,
            suggestedTotalMxn: suggestedTotalMxn ?? 0
        )
    }
}

struct ServiceQuotePredictionDTO: Decodable {
    let estimatedCostMxn: Double?
    let serviceType: String?
    let modelUsed: String?

    enum CodingKeys: String, CodingKey {
        case estimatedCostMxn = "estimated_cost_mxn"
        case serviceType = "service_type"
        case modelUsed = "model_used"
    }
}

struct ServiceQuoteProductDTO: Decodable {
    let sku: String?
    let name: String?
    let qty: Int?
    let unitPriceMxn: Double?

    enum CodingKeys: String, CodingKey {
        case sku
        case name
        case qty
        case unitPriceMxn = "unit_price_mxn"
    }

    var asServiceQuoteProduct: ServiceQuoteProduct {
        ServiceQuoteProduct(
            sku: sku ?? "",
            name: name ?? "",
            qty: qty ?? 0,
            unitPriceMxn: unitPriceMxn ?? 0
        )
    }
}

struct ServiceQuoteProduct: Identifiable, Equatable, Hashable {
    var id: String { "\(sku)-\(name)" }
    let sku: String
    let name: String
    let qty: Int
    let unitPriceMxn: Double
}

struct ServiceQuote: Equatable, Hashable {
    let serviceKey: String
    let modelUsed: String
    let estimatedCostMxn: Double
    let products: [ServiceQuoteProduct]
    let productsTotalMxn: Double
    let laborTotalMxn: Double
    let suggestedTotalMxn: Double
}

struct ServiceOrderVehicleSnapshotDTO: Decodable {
    let make: String?
    let model: String?
    let year: Int?
}

struct ServiceOrderVehicleSnapshot: Equatable, Hashable {
    let make: String?
    let model: String?
    let year: Int?

    var label: String {
        [make, model].compactMap { $0 }.joined(separator: " ").nilIfEmpty ?? "Vehiculo"
    }
}

struct ServiceOrderDTO: Decodable {
    let id: String
    let userId: String
    let vehicleId: String
    let vehicleSnapshot: ServiceOrderVehicleSnapshotDTO?
    let serviceType: String?
    let scheduledDate: String?
    let status: String?
    let estimatedCost: Double?
    let finalCost: Double?
    let costBreakdown: ServiceOrderCostBreakdownDTO?
    let userNotes: String?
    let agencyNotes: String?
    let completionToken: String?
    let checkInAt: String?
    let completedAt: String?
    let createdAt: String?
    let updatedAt: String?
    let userName: String?
    let userEmail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case vehicleSnapshot = "vehicle_snapshot"
        case serviceType = "service_type"
        case scheduledDate = "scheduled_date"
        case status
        case estimatedCost = "estimated_cost"
        case finalCost = "final_cost"
        case costBreakdown = "cost_breakdown"
        case userNotes = "user_notes"
        case agencyNotes = "agency_notes"
        case completionToken = "completion_token"
        case checkInAt = "check_in_at"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userName = "user_name"
        case userEmail = "user_email"
    }

    var asServiceOrder: ServiceOrder {
        ServiceOrder(
            id: id,
            userId: userId,
            vehicleId: vehicleId,
            vehicleSnapshot: ServiceOrderVehicleSnapshot(
                make: vehicleSnapshot?.make,
                model: vehicleSnapshot?.model,
                year: vehicleSnapshot?.year
            ),
            serviceType: serviceType ?? "",
            scheduledDate: scheduledDate ?? "",
            status: status ?? "",
            estimatedCost: estimatedCost,
            finalCost: finalCost,
            costBreakdown: costBreakdown?.asServiceOrderCostBreakdown,
            userNotes: userNotes ?? "",
            agencyNotes: agencyNotes ?? "",
            completionToken: completionToken ?? "",
            checkInAt: checkInAt ?? "",
            completedAt: completedAt ?? "",
            createdAt: createdAt ?? "",
            updatedAt: updatedAt ?? "",
            userName: userName ?? "",
            userEmail: userEmail ?? ""
        )
    }
}

struct ServiceOrderCostBreakdownDTO: Decodable {
    let prediction: ServiceQuotePredictionDTO?
    let products: [ServiceQuoteProductDTO]?
    let productsTotalMxn: Double?
    let laborTotalMxn: Double?

    enum CodingKeys: String, CodingKey {
        case prediction
        case products
        case productsTotalMxn = "products_total_mxn"
        case laborTotalMxn = "labor_total_mxn"
    }

    var asServiceOrderCostBreakdown: ServiceOrderCostBreakdown {
        ServiceOrderCostBreakdown(
            estimatedCostMxn: prediction?.estimatedCostMxn ?? 0,
            modelUsed: prediction?.modelUsed ?? "",
            products: products?.map(\.asServiceQuoteProduct) ?? [],
            productsTotalMxn: productsTotalMxn ?? 0,
            laborTotalMxn: laborTotalMxn ?? 0
        )
    }
}

struct ServiceOrderCostBreakdown: Equatable, Hashable {
    let estimatedCostMxn: Double
    let modelUsed: String
    let products: [ServiceQuoteProduct]
    let productsTotalMxn: Double
    let laborTotalMxn: Double
}

struct ServiceOrder: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let vehicleId: String
    let vehicleSnapshot: ServiceOrderVehicleSnapshot
    let serviceType: String
    let scheduledDate: String
    let status: String
    let estimatedCost: Double?
    let finalCost: Double?
    let costBreakdown: ServiceOrderCostBreakdown?
    let userNotes: String
    let agencyNotes: String
    let completionToken: String
    let checkInAt: String
    let completedAt: String
    let createdAt: String
    let updatedAt: String
    let userName: String
    let userEmail: String
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
