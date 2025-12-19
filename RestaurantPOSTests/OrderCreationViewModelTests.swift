//
//  OrderCreationViewModelTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import RestaurantPOS

final class OrderCreationViewModelTests: XCTestCase {

    // MARK: - System Under Test

    private var sut: OrderCreationViewModel!
    private var mockMenuRepository: MockMenuRepository!
    private var mockOrderRepository: MockOrderRepository!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        mockMenuRepository = MockMenuRepository()
        mockOrderRepository = MockOrderRepository()
        cancellables = Set<AnyCancellable>()
        sut = OrderCreationViewModel(
            menuRepository: mockMenuRepository,
            orderRepository: mockOrderRepository
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        mockMenuRepository = nil
        mockOrderRepository = nil
        super.tearDown()
    }

    // MARK: - Cart Management Tests

    func testAddToCart_WithValidItem_ShouldAddItem() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        let initialItemCount = sut.itemCount

        // When
        sut.addToCart(menuItem: menuItem, quantity: 2)

        // Then
        XCTAssertEqual(sut.cartItems.count, 1)
        XCTAssertEqual(sut.itemCount, initialItemCount + 2)
        XCTAssertEqual(sut.cartItems.first?.menuItem.id, menuItem.id)
        XCTAssertEqual(sut.cartItems.first?.quantity, 2)
        XCTAssertGreaterThan(sut.subtotal, 0)
        XCTAssertGreaterThan(sut.totalAmount, 0)
    }

    func testAddToCart_WithZeroQuantity_ShouldSetError() {
        // Given
        let menuItem = MenuItem.sampleItems[0]

        // When
        sut.addToCart(menuItem: menuItem, quantity: 0)

        // Then
        XCTAssertTrue(sut.cartItems.isEmpty)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error?.type, .validationError)
    }

    func testAddToCart_WithSameItemAndModifiers_ShouldUpdateQuantity() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        let modifiers = [MenuItemModifier(name: "Extra Cheese", price: 1.50)]

        sut.addToCart(menuItem: menuItem, quantity: 2, modifiers: modifiers)
        let initialCount = sut.cartItems.first?.quantity

        // When
        sut.addToCart(menuItem: menuItem, quantity: 3, modifiers: modifiers)

        // Then
        XCTAssertEqual(sut.cartItems.count, 1)
        XCTAssertEqual(sut.cartItems.first?.quantity, initialCount! + 3)
    }

    func testAddToCart_WithSameItemDifferentModifiers_ShouldAddSeparateItem() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        let modifiers1 = [MenuItemModifier(name: "Extra Cheese", price: 1.50)]
        let modifiers2 = [MenuItemModifier(name: "Bacon", price: 2.00)]

        sut.addToCart(menuItem: menuItem, quantity: 1, modifiers: modifiers1)

        // When
        sut.addToCart(menuItem: menuItem, quantity: 1, modifiers: modifiers2)

        // Then
        XCTAssertEqual(sut.cartItems.count, 2)
        XCTAssertEqual(sut.itemCount, 2)
    }

    func testRemoveFromCart_WithValidIndex_ShouldRemoveItem() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 1)
        XCTAssertEqual(sut.cartItems.count, 1)

        // When
        sut.removeFromCart(at: 0)

        // Then
        XCTAssertTrue(sut.cartItems.isEmpty)
        XCTAssertEqual(sut.itemCount, 0)
        XCTAssertEqual(sut.subtotal, 0)
        XCTAssertEqual(sut.totalAmount, 0)
    }

    func testRemoveFromCart_WithInvalidIndex_ShouldSetError() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 1)

        // When
        sut.removeFromCart(at: 5)

        // Then
        XCTAssertEqual(sut.cartItems.count, 1)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error?.type, .validationError)
    }

    func testUpdateItemQuantity_WithValidIndexAndQuantity_ShouldUpdateItem() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 2)
        XCTAssertEqual(sut.itemCount, 2)

        // When
        sut.updateItemQuantity(at: 0, quantity: 5)

        // Then
        XCTAssertEqual(sut.cartItems.first?.quantity, 5)
        XCTAssertEqual(sut.itemCount, 5)
        XCTAssertGreaterThan(sut.subtotal, menuItem.price * 2) // Should be higher now
    }

    func testUpdateItemQuantity_WithZeroQuantity_ShouldSetError() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 2)

        // When
        sut.updateItemQuantity(at: 0, quantity: 0)

        // Then
        XCTAssertEqual(sut.cartItems.first?.quantity, 2) // Should remain unchanged
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error?.type, .validationError)
    }

    func testUpdateItemQuantity_WithInvalidIndex_ShouldSetError() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 2)

        // When
        sut.updateItemQuantity(at: 5, quantity: 3)

        // Then
        XCTAssertEqual(sut.cartItems.first?.quantity, 2) // Should remain unchanged
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error?.type, .validationError)
    }

    func testClearCart_ShouldRemoveAllItems() {
        // Given
        sut.addToCart(menuItem: MenuItem.sampleItems[0], quantity: 1)
        sut.addToCart(menuItem: MenuItem.sampleItems[1], quantity: 2)
        XCTAssertFalse(sut.cartItems.isEmpty)

        // When
        sut.clearCart()

        // Then
        XCTAssertTrue(sut.cartItems.isEmpty)
        XCTAssertEqual(sut.itemCount, 0)
        XCTAssertEqual(sut.subtotal, 0)
        XCTAssertEqual(sut.totalAmount, 0)
    }

    // MARK: - Calculation Tests

    func testCalculation_WithMultipleItems_ShouldCalculateCorrectTotals() {
        // Given
        let item1 = MenuItem.sampleItems[0] // $12.99
        let item2 = MenuItem.sampleItems[1] // $13.49

        // When
        sut.addToCart(menuItem: item1, quantity: 2)
        sut.addToCart(menuItem: item2, quantity: 1)

        // Then
        let expectedSubtotal = (item1.price * 2) + item2.price
        let expectedTax = expectedSubtotal * Decimal(0.0825)
        let expectedTotal = expectedSubtotal + expectedTax

        XCTAssertEqual(sut.subtotal, expectedSubtotal)
        XCTAssertEqual(sut.tax, expectedTax)
        XCTAssertEqual(sut.totalAmount, expectedTotal)
        XCTAssertEqual(sut.itemCount, 3)
    }

    func testCalculation_WithModifiers_ShouldIncludeModifierPrices() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        let modifiers = [
            MenuItemModifier(name: "Extra Cheese", price: 1.50),
            MenuItemModifier(name: "Bacon", price: 2.00)
        ]

        // When
        sut.addToCart(menuItem: menuItem, quantity: 1, modifiers: modifiers)

        // Then
        let expectedUnitPrice = menuItem.price + 1.50 + 2.00
        let expectedSubtotal = expectedUnitPrice
        let expectedTax = expectedSubtotal * Decimal(0.0825)
        let expectedTotal = expectedSubtotal + expectedTax

        XCTAssertEqual(sut.subtotal, expectedSubtotal)
        XCTAssertEqual(sut.tax, expectedTax)
        XCTAssertEqual(sut.totalAmount, expectedTotal)
    }

    // MARK: - Menu Loading Tests

    func testLoadMenu_WithSuccess_ShouldPopulateCategoriesAndItems() {
        // Given
        let expectedCategories = MenuCategory.sampleCategories
        let expectedItems = MenuItem.sampleItems
        mockMenuRepository.categoriesToReturn = expectedCategories
        mockMenuRepository.itemsToReturn = expectedItems

        // When
        sut.loadMenu()

        // Then
        XCTAssertEqual(sut.menuCategories.count, expectedCategories.count)
        XCTAssertEqual(sut.menuItems.count, expectedItems.count)
        XCTAssertEqual(sut.filteredMenuItems.count, expectedItems.count)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }

    func testLoadMenu_WithError_ShouldSetError() {
        // Given
        let expectedError = NSError(domain: "TestError", code: 1, userInfo: nil)
        mockMenuRepository.shouldReturnError = expectedError

        // When
        sut.loadMenu()

        // Then
        XCTAssertTrue(sut.menuCategories.isEmpty)
        XCTAssertTrue(sut.menuItems.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.error)
        XCTAssertEqual(sut.error?.type, .networkError)
    }

    // MARK: - Filtering Tests

    func testFilterByCategory_ShouldFilterItemsCorrectly() {
        // Given
        sut.menuItems = MenuItem.sampleItems
        sut.filteredMenuItems = MenuItem.sampleItems
        let targetCategory = MenuCategory.sampleCategories[0] // Burgers
        let expectedItems = MenuItem.sampleItems.filter { $0.categoryID == targetCategory.id }

        // When
        sut.filterByCategory(targetCategory)

        // Then
        XCTAssertEqual(sut.selectedCategory, targetCategory)
        XCTAssertEqual(sut.filteredMenuItems.count, expectedItems.count)
        XCTAssertTrue(sut.filteredMenuItems.allSatisfy { $0.categoryID == targetCategory.id })
    }

    func testFilterByCategory_Nil_ShouldShowAllItems() {
        // Given
        let targetCategory = MenuCategory.sampleCategories[0]
        sut.filterByCategory(targetCategory)
        XCTAssertNotEqual(sut.filteredMenuItems.count, sut.menuItems.count)

        // When
        sut.filterByCategory(nil)

        // Then
        XCTAssertNil(sut.selectedCategory)
        XCTAssertEqual(sut.filteredMenuItems.count, sut.menuItems.count)
    }

    func testSearchItems_WithValidText_ShouldFilterItems() {
        // Given
        sut.menuItems = MenuItem.sampleItems
        sut.filteredMenuItems = MenuItem.sampleItems
        let searchText = "Burger"

        // When
        sut.searchItems(searchText)

        // Then
        XCTAssertEqual(sut.searchText, searchText)
        XCTAssertTrue(sut.filteredMenuItems.allSatisfy { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.description?.localizedCaseInsensitiveContains(searchText) == true
        })
    }

    func testSearchItems_WithEmptyText_ShouldShowAllItems() {
        // Given
        sut.searchItems("Burger")
        XCTAssertNotEqual(sut.filteredMenuItems.count, sut.menuItems.count)

        // When
        sut.searchItems("")

        // Then
        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.filteredMenuItems.count, sut.menuItems.count)
    }

    func testSearchAndCategoryFilter_Together_ShouldApplyBothFilters() {
        // Given
        sut.menuItems = MenuItem.sampleItems
        sut.filteredMenuItems = MenuItem.sampleItems
        let targetCategory = MenuCategory.sampleCategories[0] // Burgers
        let searchText = "Classic"

        // When
        sut.filterByCategory(targetCategory)
        sut.searchItems(searchText)

        // Then
        XCTAssertTrue(sut.filteredMenuItems.allSatisfy { item in
            item.categoryID == targetCategory.id &&
            (item.name.localizedCaseInsensitiveContains(searchText) ||
             item.description?.localizedCaseInsensitiveContains(searchText) == true)
        })
    }

    // MARK: - Order Creation Tests

    func testCreateOrder_WithValidCart_ShouldCreateOrderSuccessfully() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 2)
        let expectedOrder = Order(items: [
            OrderItem(
                menuItemID: menuItem.id,
                name: menuItem.name,
                price: menuItem.price,
                quantity: 2
            )
        ], tax: Decimal(0.0825))
        mockOrderRepository.orderToReturn = expectedOrder

        var result: Result<Order, OrderError>?
        let expectation = XCTestExpectation(description: "Order creation completes")

        // When
        sut.createOrder()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        result = .failure(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { order in
                    result = .success(order)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(result)
        switch result {
        case .success(let order):
            XCTAssertEqual(order.orderNumber, expectedOrder.orderNumber)
            XCTAssertEqual(order.items.count, 1)
            XCTAssertEqual(order.items.first?.quantity, 2)
            XCTAssertTrue(sut.cartItems.isEmpty) // Cart should be cleared
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testCreateOrder_WithEmptyCart_ShouldReturnError() {
        // Given
        XCTAssertTrue(sut.cartItems.isEmpty)

        var result: Result<Order, OrderError>?
        let expectation = XCTestExpectation(description: "Order creation completes")

        // When
        sut.createOrder()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        result = .failure(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(result)
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, OrderError.emptyOrder)
        }
    }

    func testCreateOrder_WithRepositoryError_ShouldPropagateError() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 1)
        let expectedError = OrderError.invalidItemIndex
        mockOrderRepository.errorToReturn = expectedError

        var result: Result<Order, OrderError>?
        let expectation = XCTestExpectation(description: "Order creation completes")

        // When
        sut.createOrder()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        result = .failure(error)
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)

        // Then
        XCTAssertNotNil(result)
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, expectedError)
        }
    }

    // MARK: - Property Tests

    func testIsEmpty_WhenCartEmpty_ShouldReturnTrue() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertFalse(sut.hasItems)
    }

    func testIsEmpty_WhenCartHasItems_ShouldReturnFalse() {
        // Given
        sut.addToCart(menuItem: MenuItem.sampleItems[0], quantity: 1)

        // Then
        XCTAssertFalse(sut.isEmpty)
        XCTAssertTrue(sut.hasItems)
    }

    func testIsSearching_WhenSearchTextEmpty_ShouldReturnFalse() {
        XCTAssertFalse(sut.isSearching)
    }

    func testIsSearching_WhenSearchTextNotEmpty_ShouldReturnTrue() {
        // When
        sut.searchItems("Burger")

        // Then
        XCTAssertTrue(sut.isSearching)
    }

    func testFormattedProperties_ShouldReturnValidStrings() {
        // Given
        let menuItem = MenuItem.sampleItems[0]
        sut.addToCart(menuItem: menuItem, quantity: 2)

        // Then
        XCTAssertNotNil(sut.formattedSubtotal)
        XCTAssertNotNil(sut.formattedTax)
        XCTAssertNotNil(sut.formattedTotal)
        XCTAssertTrue(sut.formattedSubtotal.hasPrefix("$"))
        XCTAssertTrue(sut.formattedTax.hasPrefix("$"))
        XCTAssertTrue(sut.formattedTotal.hasPrefix("$"))
    }
}

// MARK: - Mock Classes

class MockMenuRepository: MenuRepositoryProtocol {
    var categoriesToReturn: [MenuCategory] = []
    var itemsToReturn: [MenuItem] = []
    var shouldReturnError: Error?

    func getCategories() async throws -> [MenuCategory] {
        if let error = shouldReturnError {
            throw error
        }
        return categoriesToReturn
    }

    func getMenuItems() async throws -> [MenuItem] {
        if let error = shouldReturnError {
            throw error
        }
        return itemsToReturn
    }

    func getMenuItems(for categoryID: UUID) async throws -> [MenuItem] {
        if let error = shouldReturnError {
            throw error
        }
        return itemsToReturn.filter { $0.categoryID == categoryID }
    }
}

class MockOrderRepository: OrderRepositoryProtocol {
    var orderToReturn: Order?
    var errorToReturn: OrderError?

    func createOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        if let error = errorToReturn {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }

        if let order = orderToReturn {
            return Just(order)
                .setFailureType(to: OrderError.self)
                .eraseToAnyPublisher()
        }

        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func getOrder(id: UUID) -> AnyPublisher<Order, OrderError> {
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func getAllOrders() -> AnyPublisher<[Order], OrderError> {
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }

    func deleteOrder(id: UUID) -> AnyPublisher<Bool, OrderError> {
        return Fail(error: OrderError.invalidItemIndex)
            .eraseToAnyPublisher()
    }
}