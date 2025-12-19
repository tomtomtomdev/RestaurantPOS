import XCTest
import CoreData
import Combine
@testable import RestaurantPOS

final class OrderRepositoryTests: XCTestCase {
    var repository: OrderRepository!
    var databaseService: DatabaseServiceProtocol!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let coreDataStack = CoreDataStack(inMemory: true)
        databaseService = coreDataStack
        repository = OrderRepository(databaseService: databaseService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        repository = nil
        databaseService = nil
        cancellables = nil
        super.tearDown()
    }

    func testCreateOrder() {
        let expectation = XCTestExpectation(description: "Create order")

        let order = Order(
            orderNumber: "ORD-TEST-001",
            status: .pending,
            items: [
                OrderItem(name: "Test Item", quantity: 1, unitPrice: 10.00)
            ]
        )

        repository.createOrder(order)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { createdOrder in
                    XCTAssertEqual(createdOrder.orderNumber, "ORD-TEST-001")
                    XCTAssertEqual(createdOrder.status, .pending)
                    XCTAssertEqual(createdOrder.items.count, 1)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrder() {
        let expectation = XCTestExpectation(description: "Get order")

        let order = Order(
            orderNumber: "ORD-TEST-002",
            items: [OrderItem(name: "Test Item", quantity: 2, unitPrice: 5.00)]
        )

        repository.createOrder(order)
            .flatMap { createdOrder in
                self.repository.getOrder(id: createdOrder.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { retrievedOrder in
                    XCTAssertNotNil(retrievedOrder)
                    XCTAssertEqual(retrievedOrder?.orderNumber, "ORD-TEST-002")
                    XCTAssertEqual(retrievedOrder?.items.count, 1)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetNonExistentOrder() {
        let expectation = XCTestExpectation(description: "Get non-existent order")

        repository.getOrder(id: UUID())
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertNil(order)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetAllOrders() {
        let expectation = XCTestExpectation(description: "Get all orders")

        let order1 = Order(orderNumber: "ORD-001", items: [])
        let order2 = Order(orderNumber: "ORD-002", items: [])

        repository.createOrder(order1)
            .flatMap { _ in self.repository.createOrder(order2) }
            .flatMap { _ in self.repository.getAllOrders() }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 2)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersWithStatus() {
        let expectation = XCTestExpectation(description: "Get orders with status")

        let pendingOrder = Order(orderNumber: "ORD-PENDING", status: .pending, items: [])
        let completedOrder = Order(orderNumber: "ORD-COMPLETED", status: .completed, items: [])

        repository.createOrder(pendingOrder)
            .flatMap { _ in self.repository.createOrder(completedOrder) }
            .flatMap { _ in self.repository.getOrdersWithStatus(.pending) }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 1)
                    XCTAssertEqual(orders.first?.status, .pending)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateOrder() {
        let expectation = XCTestExpectation(description: "Update order")

        let order = Order(
            orderNumber: "ORD-UPDATE",
            status: .pending,
            items: [OrderItem(name: "Item", quantity: 1, unitPrice: 10.00)]
        )

        repository.createOrder(order)
            .flatMap { createdOrder in
                var updatedOrder = createdOrder
                updatedOrder = updatedOrder.updateStatus(.inProgress).get()!
                return self.repository.updateOrder(updatedOrder)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { updatedOrder in
                    XCTAssertEqual(updatedOrder.status, .inProgress)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteOrder() {
        let expectation = XCTestExpectation(description: "Delete order")

        let order = Order(orderNumber: "ORD-DELETE", items: [])

        repository.createOrder(order)
            .flatMap { createdOrder in
                self.repository.deleteOrder(id: createdOrder.id)
            }
            .flatMap {
                self.repository.getAllOrders()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testSearchOrdersByOrderNumber() {
        let expectation = XCTestExpectation(description: "Search orders by order number")

        let order1 = Order(orderNumber: "ORD-BURGER-001", items: [])
        let order2 = Order(orderNumber: "ORD-PIZZA-002", items: [])

        repository.createOrder(order1)
            .flatMap { _ in self.repository.createOrder(order2) }
            .flatMap { _ in self.repository.searchOrders(query: "BURGER") }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 1)
                    XCTAssertEqual(orders.first?.orderNumber, "ORD-BURGER-001")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testSearchOrdersByItemName() {
        let expectation = XCTestExpectation(description: "Search orders by item name")

        let order1 = Order(
            orderNumber: "ORD-001",
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.00)]
        )
        let order2 = Order(
            orderNumber: "ORD-002",
            items: [OrderItem(name: "Pizza", quantity: 1, unitPrice: 15.00)]
        )

        repository.createOrder(order1)
            .flatMap { _ in self.repository.createOrder(order2) }
            .flatMap { _ in self.repository.searchOrders(query: "pizza") }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 1)
                    XCTAssertEqual(orders.first?.items.first?.name, "Pizza")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testSearchOrdersEmptyQuery() {
        let expectation = XCTestExpectation(description: "Search orders with empty query")

        let order = Order(orderNumber: "ORD-001", items: [])

        repository.createOrder(order)
            .flatMap { _ in self.repository.searchOrders(query: "") }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 1)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersByDateRange() {
        let expectation = XCTestExpectation(description: "Get orders by date range")

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        let order = Order(orderNumber: "ORD-TODAY", items: [])

        repository.createOrder(order)
            .flatMap { _ in self.repository.getOrders(from: yesterday, to: tomorrow) }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertEqual(orders.count, 1)
                    XCTAssertEqual(orders.first?.orderNumber, "ORD-TODAY")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersCount() {
        let expectation = XCTestExpectation(description: "Get orders count")

        let order1 = Order(orderNumber: "ORD-001", items: [])
        let order2 = Order(orderNumber: "ORD-002", items: [])

        repository.createOrder(order1)
            .flatMap { _ in self.repository.createOrder(order2) }
            .flatMap { _ in self.repository.getOrdersCount() }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { count in
                    XCTAssertEqual(count, 2)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}