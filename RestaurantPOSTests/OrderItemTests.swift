import XCTest
@testable import RestaurantPOS

final class OrderItemTests: XCTestCase {

    func testOrderItemInitialization() {
        let item = OrderItem(
            name: "Test Item",
            quantity: 2,
            unitPrice: 10.99,
            modifiers: ["Extra Cheese"],
            specialInstructions: "No onions"
        )

        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.quantity, 2)
        XCTAssertEqual(item.unitPrice, 10.99)
        XCTAssertEqual(item.modifiers, ["Extra Cheese"])
        XCTAssertEqual(item.specialInstructions, "No onions")
    }

    func testOrderItemWithoutModifiers() {
        let item = OrderItem(
            name: "Simple Item",
            quantity: 1,
            unitPrice: 5.99
        )

        XCTAssertTrue(item.modifiers.isEmpty)
        XCTAssertNil(item.specialInstructions)
    }

    func testTotalPriceCalculation() {
        // Item without modifiers
        let item1 = OrderItem(
            name: "Burger",
            quantity: 2,
            unitPrice: 10.00
        )
        XCTAssertEqual(item1.totalPrice, 20.00)

        // Item with modifiers ($0.50 each)
        let item2 = OrderItem(
            name: "Burger",
            quantity: 2,
            unitPrice: 10.00,
            modifiers: ["Cheese", "Bacon"]
        )
        XCTAssertEqual(item2.modifierPrice, 1.00) // 2 modifiers * $0.50
        XCTAssertEqual(item2.totalPrice, 22.00) // (10.00 + 1.00) * 2
    }

    func testDisplayName() {
        // Item without modifiers
        let item1 = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )
        XCTAssertEqual(item1.displayName, "Burger")

        // Item with modifiers
        let item2 = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00,
            modifiers: ["Cheese", "Bacon"]
        )
        XCTAssertEqual(item2.displayName, "Burger (Cheese, Bacon)")
    }

    func testWithQuantity() {
        let item = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )

        let updatedItem = item.withQuantity(3)
        XCTAssertEqual(updatedItem.name, item.name)
        XCTAssertEqual(updatedItem.quantity, 3)
        XCTAssertEqual(updatedItem.unitPrice, item.unitPrice)
        XCTAssertEqual(updatedItem.modifiers, item.modifiers)
        XCTAssertEqual(updatedItem.id, item.id)
    }

    func testWithModifiers() {
        let item = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )

        let newModifiers = ["Cheese", "Lettuce", "Tomato"]
        let updatedItem = item.withModifiers(newModifiers)
        XCTAssertEqual(updatedItem.name, item.name)
        XCTAssertEqual(updatedItem.quantity, item.quantity)
        XCTAssertEqual(updatedItem.unitPrice, item.unitPrice)
        XCTAssertEqual(updatedItem.modifiers, newModifiers)
        XCTAssertEqual(updatedItem.id, item.id)
    }

    func testWithSpecialInstructions() {
        let item = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )

        let updatedItem = item.withSpecialInstructions("No pickles")
        XCTAssertEqual(updatedItem.name, item.name)
        XCTAssertEqual(updatedItem.quantity, item.quantity)
        XCTAssertEqual(updatedItem.unitPrice, item.unitPrice)
        XCTAssertEqual(updatedItem.modifiers, item.modifiers)
        XCTAssertEqual(updatedItem.specialInstructions, "No pickles")
        XCTAssertEqual(updatedItem.id, item.id)
    }

    func testEquality() {
        let item1 = OrderItem(
            id: UUID(),
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00,
            modifiers: ["Cheese"]
        )

        let item2 = OrderItem(
            id: UUID(),
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00,
            modifiers: ["Cheese"]
        )

        // Should be equal even with different IDs because all other properties match
        XCTAssertEqual(item1, item2)

        // Different items
        let item3 = OrderItem(
            name: "Pizza",
            quantity: 1,
            unitPrice: 12.00,
            modifiers: ["Extra Cheese"]
        )
        XCTAssertNotEqual(item1, item3)

        // Same item but different quantity
        let item4 = OrderItem(
            name: "Burger",
            quantity: 2,
            unitPrice: 10.00,
            modifiers: ["Cheese"]
        )
        XCTAssertNotEqual(item1, item4)
    }

    func testEqualityWithSameID() {
        let id = UUID()
        let item1 = OrderItem(
            id: id,
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )

        let item2 = OrderItem(
            id: id,
            name: "Pizza",
            quantity: 2,
            unitPrice: 12.00
        )

        // Should be equal because they have the same ID
        XCTAssertEqual(item1, item2)
    }

    func testModifierPrice() {
        // No modifiers
        let item1 = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00
        )
        XCTAssertEqual(item1.modifierPrice, 0.00)

        // One modifier
        let item2 = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00,
            modifiers: ["Cheese"]
        )
        XCTAssertEqual(item2.modifierPrice, 0.50)

        // Multiple modifiers
        let item3 = OrderItem(
            name: "Burger",
            quantity: 1,
            unitPrice: 10.00,
            modifiers: ["Cheese", "Bacon", "Avocado"]
        )
        XCTAssertEqual(item3.modifierPrice, 1.50)
    }
}