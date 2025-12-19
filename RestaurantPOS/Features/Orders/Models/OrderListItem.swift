import Foundation

public struct OrderListItem: Identifiable {
    public let id: UUID
    let orderNumber: String
    let status: OrderStatus
    let itemCount: Int
    let totalAmount: Decimal
    let formattedTotalAmount: String
    let createdAt: Date
    let formattedCreatedAt: String
    let timeElapsed: String
    let customerName: String?
    let itemsSummary: String

    init(
        id: UUID = UUID(),
        orderNumber: String,
        status: OrderStatus,
        itemCount: Int,
        totalAmount: Decimal,
        createdAt: Date,
        customerName: String? = nil,
        items: [OrderItem] = []
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.status = status
        self.itemCount = itemCount
        self.totalAmount = totalAmount
        self.formattedTotalAmount = Self.formatCurrency(totalAmount)
        self.createdAt = createdAt
        self.formattedCreatedAt = Self.formatDate(createdAt)
        self.timeElapsed = Self.timeAgo(from: createdAt)
        self.customerName = customerName
        self.itemsSummary = Self.summarizeItems(items)
    }

    static func from(_ order: Order) -> OrderListItem {
        return OrderListItem(
            id: order.id,
            orderNumber: order.orderNumber,
            status: order.status,
            itemCount: order.itemCount,
            totalAmount: order.totalAmount,
            createdAt: order.createdAt,
            items: order.items
        )
    }

    // MARK: - Formatting Helpers

    private static func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func timeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days) day\(days > 1 ? "s" : "") ago"
        }
    }

    private static func summarizeItems(_ items: [OrderItem]) -> String {
        guard !items.isEmpty else { return "No items" }

        if items.count == 1 {
            return items[0].name
        } else if items.count == 2 {
            return "\(items[0].name) & \(items[1].name)"
        } else {
            return "\(items[0].name) + \(items.count - 1) more"
        }
    }
}

// MARK: - Sorting Options

public enum OrderListSortOption: CaseIterable {
    case newestFirst
    case oldestFirst
    case highestAmount
    case lowestAmount

    var displayName: String {
        switch self {
        case .newestFirst:
            return "Newest First"
        case .oldestFirst:
            return "Oldest First"
        case .highestAmount:
            return "Highest Amount"
        case .lowestAmount:
            return "Lowest Amount"
        }
    }

    func sort(_ items: [OrderListItem]) -> [OrderListItem] {
        return items.sorted { lhs, rhs in
            switch self {
            case .newestFirst:
                return lhs.createdAt > rhs.createdAt
            case .oldestFirst:
                return lhs.createdAt < rhs.createdAt
            case .highestAmount:
                return lhs.totalAmount > rhs.totalAmount
            case .lowestAmount:
                return lhs.totalAmount < rhs.totalAmount
            }
        }
    }
}

// MARK: - Filter Options

public struct OrderListFilter {
    var statuses: Set<OrderStatus> = []
    var searchText: String = ""
    var dateRange: DateRange? = nil

    struct DateRange {
        let startDate: Date
        let endDate: Date
    }

    var isActive: Bool {
        return !statuses.isEmpty || !searchText.isEmpty || dateRange != nil
    }
}