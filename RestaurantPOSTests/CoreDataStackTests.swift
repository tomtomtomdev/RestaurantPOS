//
//  CoreDataStackTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
import CoreData
@testable import RestaurantPOS

final class CoreDataStackTests: XCTestCase {

    // MARK: - Properties

    var sut: CoreDataStack!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        // Use in-memory store for testing
        sut = CoreDataStack(inMemory: true)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testCoreDataStackInitialization() {
        // Given/When
        let stack = CoreDataStack(inMemory: true)

        // Then
        XCTAssertNotNil(stack, "Core Data stack should be initialized")
        XCTAssertNotNil(stack.mainContext, "Main context should exist")
    }

    func testMainContextIsOnMainQueue() {
        // Given
        let mainContext = sut.mainContext

        // Then
        XCTAssertEqual(
            mainContext.concurrencyType,
            .mainQueueConcurrencyType,
            "Main context should use main queue concurrency type"
        )
    }

    func testNewBackgroundContextCreation() {
        // When
        let backgroundContext = sut.newBackgroundContext()

        // Then
        XCTAssertNotNil(backgroundContext, "Background context should be created")
        XCTAssertEqual(
            backgroundContext.concurrencyType,
            .privateQueueConcurrencyType,
            "Background context should use private queue concurrency type"
        )
    }

    func testCreateAndFetchEntity() throws {
        // Given
        let context = sut.mainContext
        let orderEntity = OrderEntity(context: context)
        orderEntity.id = UUID()
        orderEntity.orderNumber = "ORD-001"
        orderEntity.status = "new"
        orderEntity.totalAmount = NSDecimalNumber(string: "25.50")
        orderEntity.createdAt = Date()
        orderEntity.updatedAt = Date()

        // When
        try sut.saveContext(context)

        // Then - Fetch the entity
        let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
        let results = try context.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1, "Should fetch exactly one order")
        XCTAssertEqual(results.first?.orderNumber, "ORD-001", "Order number should match")
        XCTAssertEqual(results.first?.status, "new", "Status should match")
    }

    func testSaveContextWithNoChanges() throws {
        // Given
        let context = sut.mainContext

        // When/Then - Should not throw even with no changes
        XCTAssertNoThrow(
            try sut.saveContext(context),
            "Saving context with no changes should not throw"
        )
    }

    func testPerformBackgroundTask() throws {
        // Given
        let expectation = self.expectation(description: "Background task completed")
        var createdOrderID: UUID?

        // When
        try sut.performBackgroundTask { context in
            let orderEntity = OrderEntity(context: context)
            orderEntity.id = UUID()
            orderEntity.orderNumber = "ORD-002"
            orderEntity.status = "inProgress"
            orderEntity.totalAmount = NSDecimalNumber(string: "45.00")
            orderEntity.createdAt = Date()
            orderEntity.updatedAt = Date()

            createdOrderID = orderEntity.id

            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2.0)

        // Verify the entity was saved
        let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", createdOrderID! as CVarArg)

        let results = try sut.mainContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "Should find the order created in background task")
        XCTAssertEqual(results.first?.orderNumber, "ORD-002", "Order number should match")
    }

}
