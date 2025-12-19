import Foundation
import Combine

class OrderService: OrderServiceProtocol {
    private var orders: [Order] = []
    private let subject = CurrentValueSubject<[Order], Never>([])

    init() {
        loadSampleOrders()
    }

    func createOrder() -> AnyPublisher<Order, OrderError> {
        let newOrder = Order()
        orders.append(newOrder)
        subject.send(orders)
        return Just(newOrder)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func getOrder(id: UUID) -> AnyPublisher<Order?, OrderError> {
        let order = orders.first { $0.id == id }
        return Just(order)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func getAllOrders() -> AnyPublisher<[Order], OrderError> {
        return Just(orders)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func getOrdersWithStatus(_ status: OrderStatus) -> AnyPublisher<[Order], OrderError> {
        let filteredOrders = orders.filter { $0.status == status }
        return Just(filteredOrders)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        var updatedOrder = order
        updatedOrder.updatedAt = Date()
        orders[index] = updatedOrder
        subject.send(orders)

        return Just(updatedOrder)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func updateOrderStatus(id: UUID, status: OrderStatus) -> AnyPublisher<Order, OrderError> {
        guard let index = orders.firstIndex(where: { $0.id == id }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        let result = orders[index].updateStatus(status)

        switch result {
        case .success(let updatedOrder):
            orders[index] = updatedOrder
            subject.send(orders)
            return Just(updatedOrder)
                .setFailureType(to: OrderError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError> {
        guard let index = orders.firstIndex(where: { $0.id == id }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        orders.remove(at: index)
        subject.send(orders)

        return Just(())
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func addItemToOrder(orderId: UUID, item: OrderItem) -> AnyPublisher<Order, OrderError> {
        guard let index = orders.firstIndex(where: { $0.id == orderId }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        var updatedOrder = orders[index]
        updatedOrder = updatedOrder.addItem(item)
        orders[index] = updatedOrder
        subject.send(orders)

        return Just(updatedOrder)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func removeItemFromOrder(orderId: UUID, itemIndex: Int) -> AnyPublisher<Order, OrderError> {
        guard let orderIndex = orders.firstIndex(where: { $0.id == orderId }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        let result = orders[orderIndex].removeItem(at: itemIndex)

        switch result {
        case .success(let updatedOrder):
            orders[orderIndex] = updatedOrder
            subject.send(orders)
            return Just(updatedOrder)
                .setFailureType(to: OrderError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func updateItemQuantity(orderId: UUID, itemIndex: Int, quantity: Int) -> AnyPublisher<Order, OrderError> {
        guard let orderIndex = orders.firstIndex(where: { $0.id == orderId }) else {
            return Fail(error: OrderError.invalidItemIndex)
                .eraseToAnyPublisher()
        }

        let result = orders[orderIndex].updateItemQuantity(at: itemIndex, quantity: quantity)

        switch result {
        case .success(let updatedOrder):
            orders[orderIndex] = updatedOrder
            subject.send(orders)
            return Just(updatedOrder)
                .setFailureType(to: OrderError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func getOrders(from startDate: Date, to endDate: Date) -> AnyPublisher<[Order], OrderError> {
        let filteredOrders = orders.filter { order in
            order.createdAt >= startDate && order.createdAt <= endDate
        }
        return Just(filteredOrders)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func searchOrders(query: String) -> AnyPublisher<[Order], OrderError> {
        let trimmedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return Just(orders)
                .setFailureType(to: OrderError.self)
                .eraseToAnyPublisher()
        }

        let filteredOrders = orders.filter { order in
            order.orderNumber.lowercased().contains(trimmedQuery) ||
            order.items.contains { item in
                item.name.lowercased().contains(trimmedQuery)
            }
        }
        return Just(filteredOrders)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    private func loadSampleOrders() {
        let burger = OrderItem(name: "Classic Burger", quantity: 2, unitPrice: 12.99, modifiers: ["Cheese", "Bacon"])
        let fries = OrderItem(name: "French Fries", quantity: 1, unitPrice: 4.99)
        let soda = OrderItem(name: "Coca Cola", quantity: 2, unitPrice: 2.99)

        let order1 = Order(
            orderNumber: "ORD-20251219-1001",
            status: .completed,
            items: [burger, fries, soda]
        )

        let pizza = OrderItem(name: "Margherita Pizza", quantity: 1, unitPrice: 14.99, modifiers: ["Extra Cheese"])
        let salad = OrderItem(name: "Caesar Salad", quantity: 1, unitPrice: 8.99, specialInstructions: "No croutons")

        let order2 = Order(
            orderNumber: "ORD-20251219-1002",
            status: .inProgress,
            items: [pizza, salad]
        )

        let sandwich = OrderItem(name: "Club Sandwich", quantity: 1, unitPrice: 10.99)
        let coffee = OrderItem(name: "Cappuccino", quantity: 1, unitPrice: 3.99)

        let order3 = Order(
            orderNumber: "ORD-20251219-1003",
            status: .pending,
            items: [sandwich, coffee]
        )

        orders = [order1, order2, order3]
        subject.send(orders)
    }
}