import XCTest
import CoreData
@testable import RestaurantPOS

final class OrderMapperTests: XCTestCase {
    var managedObjectContext: NSManagedObjectContext!
    var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        managedObjectContext = coreDataStack.viewContext
    }

    override func tearDown() {
        managedObjectContext = nil
        coreDataStack = nil
        super.tearDown()
    }

    func testToDomain() {
        // Create OrderEntity with items
        let orderEntity = OrderEntity(context: managedObjectContext)
        orderEntity.id = UUID()
        orderEntity.orderNumber = "ORD-123"
        orderEntity.status = "in_progress"
        orderEntity.subtotal = 20.00
        orderEntity.tax = 0.0825
        orderEntity.totalAmount = 21.65
        orderEntity.createdAt = Date()
        orderEntity.updatedAt = Date()

        // Create OrderItemEntity
        let itemEntity = OrderItemEntity(context: managedObjectContext)
        itemEntity.id = UUID()
        itemEntity.name = "Test Item"
        itemEntity.quantity = 2
        itemEntity.unitPrice = 10.00
        itemEntity.modifiers = "Cheese,Bacon"

        orderEntity.addToItems(itemEntity)

        // Convert to domain
        let order = OrderMapper.toDomain(orderEntity)

        XCTAssertEqual(order.orderNumber, "ORD-123")
        XCTAssertEqual(order.status, .inProgress)
        XCTAssertEqual(order.subtotal, 20.00)
        XCTAssertEqual(order.items.count, 1)
        XCTAssertEqual(order.items[0].name, "Test Item")
        XCTAssertEqual(order.items[0].quantity, 2)
        XCTAssertEqual(order.items[0].modifiers, ["Cheese", "Bacon"])
    }

    func testToEntity() {
        // Create Order domain model
        let item = OrderItem(
            name: "Test Item",
            quantity: 2,
            unitPrice: 10.00,
            modifiers: ["Cheese", "Bacon"]
        )

        let order = Order(
            orderNumber: "ORD-123",
            status: .inProgress,
            items: [item]
        )

        // Convert to entity
        let entity = OrderMapper.toEntity(order, in: managedObjectContext)

        XCTAssertEqual(entity.orderNumber, "ORD-123")
        XCTAssertEqual(entity.status, "in_progress")
        XCTAssertEqual(entity.subtotal, 20.00)
        XCTAssertEqual(entity.items?.count, 1)

        if let itemEntity = entity.items?.firstObject as? OrderItemEntity {
            XCTAssertEqual(itemEntity.name, "Test Item")
            XCTAssertEqual(itemEntity.quantity, 2)
            XCTAssertEqual(itemEntity.modifiers, "Cheese,Bacon")
        }
    }

    func testToItemDomain() {
        let itemEntity = OrderItemEntity(context: managedObjectContext)
        itemEntity.id = UUID()
        itemEntity.name = "Test Item"
        itemEntity.quantity = 2
        itemEntity.unitPrice = 10.00
        itemEntity.modifiers = "Cheese,Bacon"
        itemEntity.specialInstructions = "No onions"

        let item = OrderMapper.toItemDomain(itemEntity)

        XCTAssertEqual(item.name, "Test Item")
        XCTAssertEqual(item.quantity, 2)
        XCTAssertEqual(item.unitPrice, 10.00)
        XCTAssertEqual(item.modifiers, ["Cheese", "Bacon"])
        XCTAssertEqual(item.specialInstructions, "No onions")
    }

    func testToItemEntity() {
        let item = OrderItem(
            name: "Test Item",
            quantity: 2,
            unitPrice: 10.00,
            modifiers: ["Cheese", "Bacon"],
            specialInstructions: "No onions"
        )

        let itemEntity = OrderMapper.toItemEntity(item, in: managedObjectContext)

        XCTAssertEqual(itemEntity.name, "Test Item")
        XCTAssertEqual(itemEntity.quantity, 2)
        XCTAssertEqual(itemEntity.unitPrice, 10.00)
        XCTAssertEqual(itemEntity.modifiers, "Cheese,Bacon")
        XCTAssertEqual(itemEntity.specialInstructions, "No onions")
    }

    func testUpdateEntity() {
        // Create original entity
        let entity = OrderEntity(context: managedObjectContext)
        entity.id = UUID()
        entity.orderNumber = "ORD-123"
        entity.status = "pending"
        entity.subtotal = 10.00

        // Create updated order
        let item = OrderItem(name: "Updated Item", quantity: 3, unitPrice: 15.00)
        let updatedOrder = Order(
            id: entity.id!,
            orderNumber: "ORD-456",
            status: .completed,
            items: [item]
        )

        // Update entity
        OrderMapper.updateEntity(entity, with: updatedOrder)

        XCTAssertEqual(entity.orderNumber, "ORD-456")
        XCTAssertEqual(entity.status, "completed")
        XCTAssertEqual(entity.subtotal, 45.00)
        XCTAssertEqual(entity.items?.count, 1)

        if let itemEntity = entity.items?.firstObject as? OrderItemEntity {
            XCTAssertEqual(itemEntity.name, "Updated Item")
            XCTAssertEqual(itemEntity.quantity, 3)
            XCTAssertEqual(itemEntity.unitPrice, 15.00)
        }
    }

    func testUpdateEntityWithNewItem() {
        // Create original entity with one item
        let originalItem = OrderItem(name: "Original", quantity: 1, unitPrice: 10.00)
        let entity = OrderMapper.toEntity(
            Order(orderNumber: "ORD-123", items: [originalItem]),
            in: managedObjectContext
        )

        // Create updated order with two items
        let newItem = OrderItem(name: "New", quantity: 2, unitPrice: 20.00)
        let updatedOrder = Order(
            orderNumber: "ORD-123",
            items: [originalItem, newItem]
        )

        // Update entity
        OrderMapper.updateEntity(entity, with: updatedOrder)

        XCTAssertEqual(entity.items?.count, 2)
    }

    func testUpdateEntityWithRemovedItem() {
        // Create original entity with two items
        let item1 = OrderItem(name: "Item 1", quantity: 1, unitPrice: 10.00)
        let item2 = OrderItem(name: "Item 2", quantity: 2, unitPrice: 20.00)
        let entity = OrderMapper.toEntity(
            Order(orderNumber: "ORD-123", items: [item1, item2]),
            in: managedObjectContext
        )

        // Create updated order with only first item
        let updatedOrder = Order(
            orderNumber: "ORD-123",
            items: [item1]
        )

        // Update entity
        OrderMapper.updateEntity(entity, with: updatedOrder)

        XCTAssertEqual(entity.items?.count, 1)

        if let itemEntity = entity.items?.firstObject as? OrderItemEntity {
            XCTAssertEqual(itemEntity.name, "Item 1")
        }
    }

    func testEmptyModifiers() {
        let item = OrderItem(
            name: "Simple Item",
            quantity: 1,
            unitPrice: 5.00,
            modifiers: []
        )

        let itemEntity = OrderMapper.toItemEntity(item, in: managedObjectContext)
        XCTAssertEqual(itemEntity.modifiers, "")

        let convertedItem = OrderMapper.toItemDomain(itemEntity)
        XCTAssertTrue(convertedItem.modifiers.isEmpty)
    }

    func testNilSpecialInstructions() {
        let item = OrderItem(
            name: "Simple Item",
            quantity: 1,
            unitPrice: 5.00,
            specialInstructions: nil
        )

        let itemEntity = OrderMapper.toItemEntity(item, in: managedObjectContext)
        XCTAssertNil(itemEntity.specialInstructions)

        let convertedItem = OrderMapper.toItemDomain(itemEntity)
        XCTAssertNil(convertedItem.specialInstructions)
    }
}