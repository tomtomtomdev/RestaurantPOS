import XCTest
import Combine
@testable import RestaurantPOS

final class OrderServiceTests: XCTestCase {
    var orderService: OrderService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let coreDataStack = CoreDataStack(inMemory: true)
        orderService = OrderService(databaseService: coreDataStack)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        orderService = nil
        cancellables = nil
        super.tearDown()
    }

    func testCreateOrder() {
        let expectation = XCTestExpectation(description: "Create order")

        orderService.createOrder()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertEqual(order.status, .pending)
                    XCTAssertTrue(order.items.isEmpty)
                    XCTAssertFalse(order.orderNumber.isEmpty)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrder() {
        let expectation = XCTestExpectation(description: "Get order")

        // First create an order
        orderService.createOrder()
            .flatMap { order in
                self.orderService.getOrder(id: order.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertNotNil(order)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetAllOrders() {
        let expectation = XCTestExpectation(description: "Get all orders")

        orderService.getAllOrders()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertTrue(orders.count >= 3) // Sample orders are loaded
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersWithStatus() {
        let expectation = XCTestExpectation(description: "Get orders with status")

        orderService.getOrdersWithStatus(.completed)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertTrue(orders.allSatisfy { $0.status == .completed })
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateOrderStatus() {
        let expectation = XCTestExpectation(description: "Update order status")

        // Get first order and update its status
        orderService.getAllOrders()
            .flatMap { orders -> AnyPublisher<Order, OrderError> in
                guard let firstOrder = orders.first else {
                    return Fail(error: OrderError.invalidItemIndex)
                        .eraseToAnyPublisher()
                }
                return self.orderService.updateOrderStatus(id: firstOrder.id, status: .inProgress)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertEqual(order.status, .inProgress)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateOrderStatusInvalidTransition() {
        let expectation = XCTestExpectation(description: "Update order status with invalid transition")

        // Create a new order and try to complete it directly
        orderService.createOrder()
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.updateOrderStatus(id: order.id, status: .completed)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error.localizedDescription, "Cannot transition order from Pending to Completed")
                    } else {
                        XCTFail("Expected failure")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive a value")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testAddItemToOrder() {
        let expectation = XCTestExpectation(description: "Add item to order")

        let item = OrderItem(name: "Test Item", quantity: 2, unitPrice: 10.0)

        orderService.createOrder()
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.addItemToOrder(orderId: order.id, item: item)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertEqual(order.items.count, 1)
                    XCTAssertEqual(order.items[0].name, "Test Item")
                    XCTAssertEqual(order.subtotal, 20.0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testRemoveItemFromOrder() {
        let expectation = XCTestExpectation(description: "Remove item from order")

        // Create order with an item first
        let item = OrderItem(name: "Test Item", quantity: 1, unitPrice: 10.0)

        orderService.createOrder()
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.addItemToOrder(orderId: order.id, item: item)
            }
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.removeItemFromOrder(orderId: order.id, itemIndex: 0)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertTrue(order.items.isEmpty)
                    XCTAssertEqual(order.subtotal, 0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateItemQuantity() {
        let expectation = XCTestExpectation(description: "Update item quantity")

        let item = OrderItem(name: "Test Item", quantity: 1, unitPrice: 10.0)

        orderService.createOrder()
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.addItemToOrder(orderId: order.id, item: item)
            }
            .flatMap { order -> AnyPublisher<Order, OrderError> in
                self.orderService.updateItemQuantity(orderId: order.id, itemIndex: 0, quantity: 5)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    XCTAssertEqual(order.items[0].quantity, 5)
                    XCTAssertEqual(order.subtotal, 50.0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteOrder() {
        let expectation = XCTestExpectation(description: "Delete order")

        orderService.createOrder()
            .flatMap { order -> AnyPublisher<Void, OrderError> in
                self.orderService.deleteOrder(id: order.id)
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: {
                    // Void value, just expect completion
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testSearchOrders() {
        let expectation = XCTestExpectation(description: "Search orders")

        orderService.searchOrders(query: "Burger")
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertTrue(orders.contains { order in
                        order.items.contains { $0.name.lowercased().contains("burger") }
                    })
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOrdersByDateRange() {
        let expectation = XCTestExpectation(description: "Get orders by date range")

        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        orderService.getOrders(from: today, to: tomorrow)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { orders in
                    XCTAssertTrue(orders.allSatisfy { order in
                        order.createdAt >= today && order.createdAt <= tomorrow
                    })
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}