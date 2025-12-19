import XCTest
@testable import RestaurantPOS

final class OrderTests: XCTestCase {

    func testOrderInitialization() {
        let order = Order()

        XCTAssertNotNil(order.id)
        XCTAssertFalse(order.orderNumber.isEmpty)
        XCTAssertEqual(order.status, .pending)
        XCTAssertTrue(order.items.isEmpty)
        XCTAssertEqual(order.subtotal, 0)
        XCTAssertEqual(order.totalAmount, 0)
        XCTAssertNotNil(order.createdAt)
        XCTAssertNotNil(order.updatedAt)
        XCTAssertNil(order.completedAt)
    }

    func testOrderWithItems() {
        let item = OrderItem(name: "Test Item", quantity: 2, unitPrice: 10.0)
        let order = Order(items: [item])

        XCTAssertEqual(order.items.count, 1)
        XCTAssertEqual(order.subtotal, 20.0)
        XCTAssertEqual(order.totalAmount, 21.65) // 20.0 * (1 + 0.0825)
        XCTAssertEqual(order.itemCount, 2)
    }

    func testOrderNumberGeneration() {
        let order1 = Order()
        let order2 = Order()

        XCTAssertNotEqual(order1.orderNumber, order2.orderNumber)
        XCTAssertTrue(order1.orderNumber.hasPrefix("ORD-"))
    }

    func testStatusTransitions() {
        var order = Order()

        // Valid transitions
        let inProgressResult = order.updateStatus(.inProgress)
        XCTAssertNotNil(try? inProgressResult.get())
        if case .success(let updatedOrder) = inProgressResult {
            XCTAssertEqual(updatedOrder.status, .inProgress)
            order = updatedOrder
        }

        let readyResult = order.updateStatus(.ready)
        XCTAssertNotNil(try? readyResult.get())
        if case .success(let updatedOrder) = readyResult {
            XCTAssertEqual(updatedOrder.status, .ready)
            XCTAssertNotNil(updatedOrder.completedAt)
            order = updatedOrder
        }

        let completedResult = order.updateStatus(.completed)
        XCTAssertNotNil(try? completedResult.get())
        if case .success(let updatedOrder) = completedResult {
            XCTAssertEqual(updatedOrder.status, .completed)
            XCTAssertNotNil(updatedOrder.completedAt)
        }
    }

    func testInvalidStatusTransitions() {
        let order = Order()

        // Invalid transition: pending -> completed
        let invalidResult = order.updateStatus(.completed)
        XCTAssertThrowsError(try invalidResult.get()) { error in
            if case OrderError.invalidStatusTransition(let from, let to) = error {
                XCTAssertEqual(from, .pending)
                XCTAssertEqual(to, .completed)
            } else {
                XCTFail("Expected invalidStatusTransition error")
            }
        }
    }

    func testAddItem() {
        var order = Order()
        let item1 = OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)
        let item2 = OrderItem(name: "Fries", quantity: 2, unitPrice: 3.0)

        order = order.addItem(item1)
        XCTAssertEqual(order.items.count, 1)
        XCTAssertEqual(order.subtotal, 10.0)

        order = order.addItem(item2)
        XCTAssertEqual(order.items.count, 2)
        XCTAssertEqual(order.subtotal, 16.0) // 10.0 + 6.0

        // Add same item again - should combine quantities
        let item3 = OrderItem(name: "Burger", quantity: 2, unitPrice: 10.0)
        order = order.addItem(item3)
        XCTAssertEqual(order.items.count, 2)
        XCTAssertEqual(order.items[0].quantity, 3) // 1 + 2
        XCTAssertEqual(order.subtotal, 36.0) // 30.0 + 6.0
    }

    func testRemoveItem() {
        let item1 = OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)
        let item2 = OrderItem(name: "Fries", quantity: 2, unitPrice: 3.0)
        var order = Order(items: [item1, item2])

        let result = order.removeItem(at: 0)
        XCTAssertNotNil(try? result.get())
        if case .success(let updatedOrder) = result {
            XCTAssertEqual(updatedOrder.items.count, 1)
            XCTAssertEqual(updatedOrder.items[0].name, "Fries")
            XCTAssertEqual(updatedOrder.subtotal, 6.0)
        }
    }

    func testRemoveInvalidItemIndex() {
        let item = OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)
        let order = Order(items: [item])

        let result = order.removeItem(at: 5)
        XCTAssertThrowsError(try result.get()) { error in
            if let orderError = error as? OrderError {
                XCTAssertEqual(orderError, OrderError.invalidItemIndex)
            } else {
                XCTFail("Expected OrderError, got \(error)")
            }
        }
    }

    func testUpdateItemQuantity() {
        let item = OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)
        var order = Order(items: [item])

        let result = order.updateItemQuantity(at: 0, quantity: 3)
        XCTAssertNotNil(try? result.get())
        if case .success(let updatedOrder) = result {
            XCTAssertEqual(updatedOrder.items[0].quantity, 3)
            XCTAssertEqual(updatedOrder.subtotal, 30.0)
        }
    }

    func testUpdateInvalidItemQuantity() {
        let item = OrderItem(name: "Burger", quantity: 1, unitPrice: 10.0)
        let order = Order(items: [item])

        let result = order.updateItemQuantity(at: 0, quantity: 0)
        XCTAssertThrowsError(try result.get()) { error in
            if let orderError = error as? OrderError {
                XCTAssertEqual(orderError, OrderError.invalidQuantity)
            } else {
                XCTFail("Expected OrderError, got \(error)")
            }
        }
    }

    func testRecalculateTotals() {
        let item1 = OrderItem(name: "Burger", quantity: 2, unitPrice: 10.0)
        let item2 = OrderItem(name: "Fries", quantity: 1, unitPrice: 3.0)
        let order = Order(items: [item1, item2])

        XCTAssertEqual(order.subtotal, 23.0) // 20.0 + 3.0
        XCTAssertEqual(order.totalAmount, 24.8975) // 23.0 * 1.0825
    }
}