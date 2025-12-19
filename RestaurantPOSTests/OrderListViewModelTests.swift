import XCTest
import CoreData
import Combine
@testable import RestaurantPOS

final class OrderListViewModelTests: XCTestCase {
    var viewModel: OrderListViewModel!
    var mockOrderService: MockOrderService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockOrderService = MockOrderService()
        viewModel = OrderListViewModel(orderService: mockOrderService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        viewModel = nil
        mockOrderService = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertTrue(viewModel.orders.isEmpty)
        XCTAssertTrue(viewModel.filteredOrders.isEmpty)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.totalOrdersCount, 0)
        XCTAssertEqual(viewModel.filteredOrdersCount, 0)
    }

    func testLoadOrders() {
        let expectation = XCTestExpectation(description: "Orders loaded")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        let order2 = Order(
            orderNumber: "ORD-002",
            status: .completed,
            items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 15.0)]
        )

        mockOrderService.orders = [order1, order2]

        viewModel.$orders
            .dropFirst()
            .sink { orders in
                if orders.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.orders.count, 2)
        XCTAssertEqual(viewModel.filteredOrders.count, 2)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertTrue(viewModel.hasOrders)
    }

    func testSearchFilter() {
        let expectation = XCTestExpectation(description: "Search applied")

        let order1 = Order(
            orderNumber: "ORD-BURGER",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        let order2 = Order(
            orderNumber: "ORD-PIZZA",
            status: .completed,
            items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 15.0)]
        )

        mockOrderService.orders = [order1, order2]

        viewModel.$filteredOrders
            .dropFirst()
            .sink { orders in
                if orders.count == 1 && orders.first?.orderNumber == "ORD-BURGER" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()
        viewModel.searchText = "BURGER"

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.filteredOrders.count, 1)
        XCTAssertEqual(viewModel.filteredOrders.first?.orderNumber, "ORD-BURGER")
    }

    func testStatusFilter() {
        let expectation = XCTestExpectation(description: "Status filter applied")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        let order2 = Order(
            orderNumber: "ORD-002",
            status: .completed,
            items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 15.0)]
        )

        mockOrderService.orders = [order1, order2]

        viewModel.$filteredOrders
            .dropFirst()
            .sink { orders in
                if orders.count == 1 && orders.first?.status == .pending {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()
        viewModel.selectedStatuses.insert(.pending)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.filteredOrders.count, 1)
        XCTAssertEqual(viewModel.filteredOrders.first?.status, .pending)
    }

    func testSorting() {
        let expectation = XCTestExpectation(description: "Sorting applied")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        let order2 = Order(
            orderNumber: "ORD-002",
            status: .completed,
            items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 15.0)]
        )

        mockOrderService.orders = [order1, order2]

        viewModel.$filteredOrders
            .dropFirst()
            .sink { orders in
                if orders.count == 2 && orders.first?.totalAmount == 30.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()
        viewModel.selectedSortOption = .highestAmount

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.filteredOrders.count, 2)
        XCTAssertEqual(viewModel.filteredOrders.first?.totalAmount, 30.0)
        XCTAssertEqual(viewModel.filteredOrders.last?.totalAmount, 10.0)
    }

    func testStatistics() {
        let expectation = XCTestExpectation(description: "Statistics calculated")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        let order2 = Order(
            orderNumber: "ORD-002",
            status: .completed,
            items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 15.0)]
        )

        mockOrderService.orders = [order1, order2]

        viewModel.$orders
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(viewModel.totalOrdersCount, 2)
        XCTAssertEqual(viewModel.pendingOrdersCount, 1)
        XCTAssertEqual(viewModel.completedOrdersCount, 1)
        XCTAssertEqual(viewModel.totalRevenue, 30.0)
        XCTAssertEqual(viewModel.formattedTotalRevenue, "$30.00")
    }

    func testUpdateOrderStatus() {
        let expectation = XCTestExpectation(description: "Order status updated")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        mockOrderService.orders = [order1]

        var statusUpdateCalled = false
        mockOrderService.onUpdateStatus = { id, status in
            statusUpdateCalled = true
            XCTAssertEqual(id, order1.id)
            XCTAssertEqual(status, .inProgress)
        }

        viewModel.refreshOrders()
        viewModel.updateOrderStatus(id: order1.id, to: .inProgress)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(statusUpdateCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteOrder() {
        let expectation = XCTestExpectation(description: "Order deleted")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        mockOrderService.orders = [order1]

        var deleteCalled = false
        mockOrderService.onDelete = { id in
            deleteCalled = true
            XCTAssertEqual(id, order1.id)
        }

        viewModel.refreshOrders()
        viewModel.deleteOrder(id: order1.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(deleteCalled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testClearFilters() {
        let expectation = XCTestExpectation(description: "Filters cleared")

        let order1 = Order(
            orderNumber: "ORD-001",
            status: .pending,
            items: [OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)]
        )

        mockOrderService.orders = [order1]

        viewModel.$filteredOrders
            .dropFirst()
            .sink { orders in
                // After loading
                self.viewModel.searchText = "test"
                self.viewModel.selectedStatuses.insert(.completed)

                // After clearing filters
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.viewModel.clearFilters()
                    if self.viewModel.filteredOrders.count == 1 &&
                       self.viewModel.searchText.isEmpty &&
                       self.viewModel.selectedStatuses.isEmpty {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)

        viewModel.refreshOrders()

        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock Order Service
class MockOrderService: OrderServiceProtocol {
    var orders: [Order] = []
    var onUpdateStatus: ((UUID, OrderStatus) -> Void)?
    var onDelete: ((UUID) -> Void)?

    func createOrder() -> AnyPublisher<Order, OrderError> {
        let newOrder = Order()
        orders.append(newOrder)
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
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
        }
        return Just(order)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func updateOrderStatus(id: UUID, status: OrderStatus) -> AnyPublisher<Order, OrderError> {
        onUpdateStatus?(id, status)

        if let index = orders.firstIndex(where: { $0.id == id }) {
            let result = orders[index].updateStatus(status)
            switch result {
            case .success(let updatedOrder):
                orders[index] = updatedOrder
                return Just(updatedOrder)
                    .setFailureType(to: OrderError.self)
                    .eraseToAnyPublisher()
            case .failure(let error):
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError> {
        onDelete?(id)

        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders.remove(at: index)
        }
        return Just(())
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func addItemToOrder(orderId: UUID, item: OrderItem) -> AnyPublisher<Order, OrderError> {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            orders[index] = orders[index].addItem(item)
        }
        return Just(orders.first { $0.id == orderId }!)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    func removeItemFromOrder(orderId: UUID, itemIndex: Int) -> AnyPublisher<Order, OrderError> {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            let result = orders[index].removeItem(at: itemIndex)
            switch result {
            case .success(let updatedOrder):
                orders[index] = updatedOrder
                return Just(updatedOrder)
                    .setFailureType(to: OrderError.self)
                    .eraseToAnyPublisher()
            case .failure(let error):
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func updateItemQuantity(orderId: UUID, itemIndex: Int, quantity: Int) -> AnyPublisher<Order, OrderError> {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            let result = orders[index].updateItemQuantity(at: itemIndex, quantity: quantity)
            switch result {
            case .success(let updatedOrder):
                orders[index] = updatedOrder
                return Just(updatedOrder)
                    .setFailureType(to: OrderError.self)
                    .eraseToAnyPublisher()
            case .failure(let error):
                return Fail(error: error)
                    .eraseToAnyPublisher()
            }
        }
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
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
}