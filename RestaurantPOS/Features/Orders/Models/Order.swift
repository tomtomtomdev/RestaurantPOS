import Foundation

enum OrderStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case ready = "ready"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .ready:
            return "Ready"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var canTransitionTo: [OrderStatus] {
        switch self {
        case .pending:
            return [.inProgress, .cancelled]
        case .inProgress:
            return [.ready, .cancelled]
        case .ready:
            return [.completed, .cancelled]
        case .completed:
            return []
        case .cancelled:
            return []
        }
    }

    func canTransition(to newStatus: OrderStatus) -> Bool {
        return canTransitionTo.contains(newStatus)
    }
}

struct Order: Codable, Identifiable, Equatable {
    let id: UUID
    var orderNumber: String
    var status: OrderStatus
    var items: [OrderItem]
    var subtotal: Decimal
    var tax: Decimal
    var totalAmount: Decimal
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        orderNumber: String = Order.generateOrderNumber(),
        status: OrderStatus = .pending,
        items: [OrderItem] = [],
        tax: Decimal = 0.0825,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.status = status
        self.items = items
        self.subtotal = items.reduce(0) { $0 + $1.totalPrice }
        self.tax = tax
        self.totalAmount = subtotal * (1 + tax)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    func updateStatus(_ newStatus: OrderStatus) -> Result<Order, OrderError> {
        guard status.canTransition(to: newStatus) else {
            return .failure(.invalidStatusTransition(from: status, to: newStatus))
        }

        var updatedOrder = self
        updatedOrder.status = newStatus
        updatedOrder.updatedAt = Date()

        if newStatus == .completed {
            updatedOrder.completedAt = Date()
        }

        return .success(updatedOrder)
    }

    func addItem(_ item: OrderItem) -> Order {
        var updatedOrder = self
        if let existingIndex = updatedOrder.items.firstIndex(where: { $0.name == item.name && $0.modifiers == item.modifiers }) {
            updatedOrder.items[existingIndex].quantity += item.quantity
        } else {
            updatedOrder.items.append(item)
        }
        updatedOrder.recalculateTotals()
        updatedOrder.updatedAt = Date()
        return updatedOrder
    }

    func removeItem(at index: Int) -> Result<Order, OrderError> {
        guard index >= 0 && index < items.count else {
            return .failure(.invalidItemIndex)
        }

        var updatedOrder = self
        updatedOrder.items.remove(at: index)
        updatedOrder.recalculateTotals()
        updatedOrder.updatedAt = Date()
        return .success(updatedOrder)
    }

    func updateItemQuantity(at index: Int, quantity: Int) -> Result<Order, OrderError> {
        guard index >= 0 && index < items.count else {
            return .failure(.invalidItemIndex)
        }

        guard quantity > 0 else {
            return .failure(.invalidQuantity)
        }

        var updatedOrder = self
        updatedOrder.items[index].quantity = quantity
        updatedOrder.recalculateTotals()
        updatedOrder.updatedAt = Date()
        return .success(updatedOrder)
    }

    private mutating func recalculateTotals() {
        subtotal = items.reduce(0) { $0 + $1.totalPrice }
        totalAmount = subtotal * (1 + tax)
    }

    static func generateOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        let random = Int.random(in: 1000...9999)
        return "ORD-\(dateString)-\(random)"
    }
}

enum OrderError: Error, LocalizedError, Equatable {
    case invalidStatusTransition(from: OrderStatus, to: OrderStatus)
    case invalidItemIndex
    case invalidQuantity
    case emptyOrder

    var errorDescription: String? {
        switch self {
        case .invalidStatusTransition(let from, let to):
            return "Cannot transition order from \(from.displayName) to \(to.displayName)"
        case .invalidItemIndex:
            return "Invalid item index"
        case .invalidQuantity:
            return "Quantity must be greater than 0"
        case .emptyOrder:
            return "Order cannot be empty"
        }
    }
}