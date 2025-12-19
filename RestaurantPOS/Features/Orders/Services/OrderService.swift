import Foundation
import CoreData
import Combine

class OrderService: OrderServiceProtocol {
    private let repository: OrderRepositoryProtocol
    private let databaseService: DatabaseServiceProtocol

    init(databaseService: DatabaseServiceProtocol) {
        self.databaseService = databaseService
        self.repository = OrderRepository(databaseService: databaseService)
        loadSampleOrdersIfNeeded()
    }

    // For testing purposes
    init(repository: OrderRepositoryProtocol) {
        self.repository = repository
        self.databaseService = MockDatabaseService()
    }

    func createOrder() -> AnyPublisher<Order, OrderError> {
        let newOrder = Order()
        return repository.createOrder(newOrder)
    }

    func getOrder(id: UUID) -> AnyPublisher<Order?, OrderError> {
        return repository.getOrder(id: id)
    }

    func getAllOrders() -> AnyPublisher<[Order], OrderError> {
        return repository.getAllOrders()
    }

    func getOrdersWithStatus(_ status: OrderStatus) -> AnyPublisher<[Order], OrderError> {
        return repository.getOrdersWithStatus(status)
    }

    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        return repository.updateOrder(order)
    }

    func updateOrderStatus(id: UUID, status: OrderStatus) -> AnyPublisher<Order, OrderError> {
        return repository.getOrder(id: id)
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                guard let order = order else {
                    return Fail(error: OrderError.invalidItemIndex)
                        .eraseToAnyPublisher()
                }

                let result = order.updateStatus(status)
                switch result {
                case .success(let updatedOrder):
                    return self.repository.updateOrder(updatedOrder)
                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError> {
        return repository.deleteOrder(id: id)
    }

    func addItemToOrder(orderId: UUID, item: OrderItem) -> AnyPublisher<Order, OrderError> {
        return repository.getOrder(id: orderId)
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                guard let order = order else {
                    return Fail(error: OrderError.invalidItemIndex)
                        .eraseToAnyPublisher()
                }

                let updatedOrder = order.addItem(item)
                return self.repository.updateOrder(updatedOrder)
            }
            .eraseToAnyPublisher()
    }

    func removeItemFromOrder(orderId: UUID, itemIndex: Int) -> AnyPublisher<Order, OrderError> {
        return repository.getOrder(id: orderId)
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                guard let order = order else {
                    return Fail(error: OrderError.invalidItemIndex)
                        .eraseToAnyPublisher()
                }

                let result = order.removeItem(at: itemIndex)
                switch result {
                case .success(let updatedOrder):
                    return self.repository.updateOrder(updatedOrder)
                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func updateItemQuantity(orderId: UUID, itemIndex: Int, quantity: Int) -> AnyPublisher<Order, OrderError> {
        return repository.getOrder(id: orderId)
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                guard let order = order else {
                    return Fail(error: OrderError.invalidItemIndex)
                        .eraseToAnyPublisher()
                }

                let result = order.updateItemQuantity(at: itemIndex, quantity: quantity)
                switch result {
                case .success(let updatedOrder):
                    return self.repository.updateOrder(updatedOrder)
                case .failure(let error):
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func getOrders(from startDate: Date, to endDate: Date) -> AnyPublisher<[Order], OrderError> {
        return repository.getOrders(from: startDate, to: endDate)
    }

    func searchOrders(query: String) -> AnyPublisher<[Order], OrderError> {
        return repository.searchOrders(query: query)
    }

    private func loadSampleOrdersIfNeeded() {
        repository.getOrdersCount()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] count in
                    if count == 0 {
                        self?.loadSampleOrders()
                    }
                }
            )
            .store(in: &cancellables)
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

        _ = repository.createOrder(order1)
        _ = repository.createOrder(order2)
        _ = repository.createOrder(order3)
    }

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Mock Database Service for Testing
private class MockDatabaseService: DatabaseServiceProtocol {
    private let coreDataStack: CoreDataStack

    init() {
        coreDataStack = CoreDataStack(inMemory: true)
    }

    var mainContext: NSManagedObjectContext {
        return coreDataStack.mainContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        return coreDataStack.newBackgroundContext()
    }

    func saveContext(_ context: NSManagedObjectContext) throws {
        try coreDataStack.saveContext(context)
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) throws {
        try coreDataStack.performBackgroundTask(block)
    }
}