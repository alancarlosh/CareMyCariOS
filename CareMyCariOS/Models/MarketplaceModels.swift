import Foundation

struct PartListResponse: Decodable {
    let items: [PartDTO]
    let total: Int
}

struct PartDetailResponse: Decodable {
    let part: PartDTO
}

struct PartOptionsResponse: Decodable {
    let categories: [String]
    let makes: [String]
    let years: [Int]
    let models: [String]
}

struct CreatePartRequest: Encodable {
    let name: String
    let category: String
    let make: String?
    let year: Int?
    let model: String?
    let compatibility: [String]
    let price: Double
    let quantity: Int
}

struct UpdatePartRequest: Encodable {
    let name: String
    let category: String
    let make: String
    let year: Int
    let model: String
    let price: Double
    let quantity: Int
}

struct PartDTO: Decodable {
    let id: String
    let userId: String
    let name: String
    let category: String
    let make: String?
    let year: Int?
    let model: String?
    let compatibility: [String]?
    let price: Double
    let quantity: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case category
        case make
        case year
        case model
        case compatibility
        case price
        case quantity
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var asPart: Part {
        Part(
            id: id,
            userId: userId,
            name: name,
            category: category,
            make: make,
            year: year,
            model: model,
            compatibility: compatibility ?? [],
            price: price,
            quantity: quantity,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct Part: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let name: String
    let category: String
    let make: String?
    let year: Int?
    let model: String?
    let compatibility: [String]
    let price: Double
    let quantity: Int
    let createdAt: String?
    let updatedAt: String?

    var vehicleLabel: String {
        var values = [String]()
        if let make, !make.isEmpty {
            values.append(make)
        }
        if let model, !model.isEmpty {
            values.append(model)
        }
        if let year {
            values.append(String(year))
        }
        return values.isEmpty ? "Compatibilidad general" : values.joined(separator: " ")
    }
}

struct MarketplacePurchaseRequest: Encodable {
    let partId: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case partId = "part_id"
        case quantity
    }
}

struct OrderListResponse: Decodable {
    let items: [OrderDTO]
    let total: Int
    let allCount: Int?
    let pendingCount: Int?

    enum CodingKeys: String, CodingKey {
        case items
        case total
        case allCount = "all_count"
        case pendingCount = "pending_count"
    }
}

struct OrderDetailResponse: Decodable {
    let order: OrderDTO
}

struct CreateOrderRequest: Encodable {
    let clientName: String
    let vin: String
    let make: String
    let year: Int
    let model: String
    let partId: String
    let quantity: Int
    let status: String

    enum CodingKeys: String, CodingKey {
        case clientName = "client_name"
        case vin
        case make
        case year
        case model
        case partId = "part_id"
        case quantity
        case status
    }
}

struct UpdateOrderStatusRequest: Encodable {
    let status: String
}

struct SalesDailyReportResponse: Decodable {
    let report: SalesDailyReportDTO
}

struct SalesDailyReportDTO: Decodable {
    let date: String
    let totalOrders: Int
    let totalSales: Double
    let pendingCount: Int
    let confirmedCount: Int
    let deliveredCount: Int
    let canceledCount: Int
    let items: [OrderDTO]

    enum CodingKeys: String, CodingKey {
        case date
        case totalOrders = "total_orders"
        case totalSales = "total_sales"
        case pendingCount = "pending_count"
        case confirmedCount = "confirmed_count"
        case deliveredCount = "delivered_count"
        case canceledCount = "canceled_count"
        case items
    }

    var asSalesDailyReport: SalesDailyReport {
        SalesDailyReport(
            date: date,
            totalOrders: totalOrders,
            totalSales: totalSales,
            pendingCount: pendingCount,
            confirmedCount: confirmedCount,
            deliveredCount: deliveredCount,
            canceledCount: canceledCount,
            items: items.map(\.asOrder)
        )
    }
}

struct SalesDailyReport: Equatable {
    let date: String
    let totalOrders: Int
    let totalSales: Double
    let pendingCount: Int
    let confirmedCount: Int
    let deliveredCount: Int
    let canceledCount: Int
    let items: [Order]
}

struct OrderDTO: Decodable {
    let id: String
    let userId: String
    let buyerId: String?
    let clientName: String
    let vin: String
    let make: String
    let year: Int
    let model: String
    let partId: String
    let partName: String?
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let status: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case buyerId = "buyer_id"
        case clientName = "client_name"
        case vin
        case make
        case year
        case model
        case partId = "part_id"
        case partName = "part_name"
        case quantity
        case unitPrice = "unit_price"
        case totalPrice = "total_price"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var asOrder: Order {
        Order(
            id: id,
            userId: userId,
            buyerId: buyerId,
            clientName: clientName,
            vin: vin,
            make: make,
            year: year,
            model: model,
            partId: partId,
            partName: partName,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct Order: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let buyerId: String?
    let clientName: String
    let vin: String
    let make: String
    let year: Int
    let model: String
    let partId: String
    let partName: String?
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double
    let status: String
    let createdAt: String?
    let updatedAt: String?

    var partLabel: String {
        partName?.nilIfEmpty ?? "Refaccion"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
