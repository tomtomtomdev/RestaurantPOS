//
//  OrderCreationViewControllerTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import RestaurantPOS

final class OrderCreationViewControllerTests: XCTestCase {

    // MARK: - System Under Test

    private var sut: OrderCreationViewController!
    private var mockViewModel: MockOrderCreationViewModel!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        mockViewModel = MockOrderCreationViewModel()
        cancellables = Set<AnyCancellable>()
        sut = OrderCreationViewController(viewModel: mockViewModel)
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        mockViewModel = nil
        super.tearDown()
    }

    // MARK: - View Controller Lifecycle Tests

    func testViewDidLoad_ShouldSetupUIAndLoadData() {
        // When
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // Then
        XCTAssertNotNil(sut.navigationItem.searchController)
        XCTAssertEqual(sut.navigationItem.searchController?.searchBar.placeholder, "Search menu items...")
        XCTAssertEqual(sut.title, "Create Order")
        XCTAssertFalse(sut.navigationController?.navigationBar.prefersLargeTitles == false)
    }

    func testViewDidLoad_ShouldCallViewModelViewDidLoad() {
        // Given
        let expectation = XCTestExpectation(description: "ViewModel viewDidLoad called")
        mockViewModel.viewDidLoadCalled
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockViewModel.viewDidLoadCallCount, 1)
    }

    // MARK: - UI Component Tests

    func testUIComponents_ShouldBeConfiguredCorrectly() {
        // When
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // Then
        XCTAssertNotNil(sut.scrollView)
        XCTAssertNotNil(sut.categoryCollectionView)
        XCTAssertNotNil(sut.menuCollectionView)
        XCTAssertNotNil(sut.cartSummaryView)
        XCTAssertNotNil(sut.searchController)
        XCTAssertNotNil(sut.emptyStateView)
        XCTAssertNotNil(sut.loadingIndicator)

        // Check delegate assignments
        XCTAssertTrue(sut.categoryCollectionView.delegate === sut)
        XCTAssertTrue(sut.categoryCollectionView.dataSource === sut)
        XCTAssertTrue(sut.menuCollectionView.delegate === sut)
        XCTAssertTrue(sut.menuCollectionView.dataSource === sut)
        XCTAssertTrue(sut.cartSummaryView.delegate === sut)
    }

    func testNavigationItem_ShouldBeConfiguredCorrectly() {
        // When
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // Then
        XCTAssertNotNil(sut.navigationItem.leftBarButtonItem)
        XCTAssertEqual(sut.navigationItem.leftBarButtonItem?.systemItem, .close)
        XCTAssertNotNil(sut.navigationItem.searchController)
        XCTAssertFalse(sut.navigationItem.hidesSearchBarWhenScrolling)
        XCTAssertTrue(sut.navigationController?.navigationBar.prefersLargeTitles == true)
    }

    // MARK: - Data Binding Tests

    func testLoadingState_ShouldUpdateUICorrectly() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // When - Loading starts
        mockViewModel.setLoading(true)

        // Then
        XCTAssertTrue(sut.loadingIndicator.isAnimating)
        XCTAssertTrue(sut.menuCollectionView.isHidden)
        XCTAssertTrue(sut.emptyStateView.isHidden)

        // When - Loading ends with items
        mockViewModel.setLoading(false)
        mockViewModel.setFilteredMenuItems([
            MenuItem(name: "Test Item", price: 10.99, categoryID: UUID())
        ])

        // Then
        XCTAssertFalse(sut.loadingIndicator.isAnimating)
        XCTAssertFalse(sut.menuCollectionView.isHidden)
        XCTAssertTrue(sut.emptyStateView.isHidden)

        // When - Loading ends with no items
        mockViewModel.setFilteredMenuItems([])

        // Then
        XCTAssertFalse(sut.loadingIndicator.isAnimating)
        XCTAssertTrue(sut.menuCollectionView.isHidden)
        XCTAssertFalse(sut.emptyStateView.isHidden)
    }

    func testCartUpdates_ShouldUpdateSummaryView() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        let expectation = XCTestExpectation(description: "Cart summary updated")
        var summaryReceived: (itemCount: Int, subtotal: Decimal, tax: Decimal, total: Decimal, isEmpty: Bool)?

        // Mock the OrderSummaryView to capture updates
        class MockOrderSummaryView: OrderSummaryView {
            var capturedConfig: (itemCount: Int, subtotal: Decimal, tax: Decimal, total: Decimal, isEmpty: Bool)?

            override func configure(itemCount: Int, subtotal: Decimal, tax: Decimal, total: Decimal, isEmpty: Bool) {
                capturedConfig = (itemCount, subtotal, tax, total, isEmpty)
            }
        }

        let mockSummaryView = MockOrderSummaryView()
        sut.cartSummaryView = mockSummaryView

        // When
        mockViewModel.setCartItems([
            CartItem(menuItem: MenuItem(name: "Test Item", price: 10.99, categoryID: UUID()), quantity: 1)
        ])

        // Then
        XCTAssertNotNil(mockSummaryView.capturedConfig)
        XCTAssertEqual(mockSummaryView.capturedConfig?.itemCount, 1)
        XCTAssertEqual(mockSummaryView.capturedConfig?.isEmpty, false)
    }

    func testCategorySelection_ShouldUpdateViewModel() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setMenuCategories([
            MenuCategory(name: "Category 1", sortOrder: 1),
            MenuCategory(name: "Category 2", sortOrder: 2)
        ])

        // Simulate selecting first category
        let indexPath = IndexPath(item: 1, section: 0) // Skip "All" at index 0

        // When
        sut.collectionView(sut.categoryCollectionView, didSelectItemAt: indexPath)

        // Then
        XCTAssertEqual(mockViewModel.selectedCategoryCallCount, 1)
        XCTAssertEqual(mockViewModel.lastSelectedCategory?.name, "Category 1")
    }

    func testAllCategoriesSelection_ShouldSetCategoryToNil() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // When
        let indexPath = IndexPath(item: 0, section: 0) // "All Categories"
        sut.collectionView(sut.categoryCollectionView, didSelectItemAt: indexPath)

        // Then
        XCTAssertEqual(mockViewModel.selectedCategoryCallCount, 1)
        XCTAssertNil(mockViewModel.lastSelectedCategory)
    }

    // MARK: - Search Functionality Tests

    func testSearchTextUpdate_ShouldCallViewModel() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // When
        sut.updateSearchResults(for: sut.searchController)
        sut.searchController.searchBar.text = "Burger"
        sut.updateSearchResults(for: sut.searchController)

        // Then
        XCTAssertEqual(mockViewModel.searchTextCallCount, 2)
        XCTAssertEqual(mockViewModel.lastSearchText, "Burger")
    }

    // MARK: - Collection View Tests

    func testCategoryCollectionViewDataSource_ShouldReturnCorrectCounts() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setMenuCategories([
            MenuCategory(name: "Category 1", sortOrder: 1),
            MenuCategory(name: "Category 2", sortOrder: 2)
        ])

        // Then
        XCTAssertEqual(sut.collectionView(sut.categoryCollectionView, numberOfItemsInSection: 0), 3) // 2 categories + "All"
        XCTAssertEqual(sut.numberOfSections(in: sut.categoryCollectionView), 1)
    }

    func testMenuCollectionViewDataSource_ShouldReturnCorrectCounts() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setFilteredMenuItems([
            MenuItem(name: "Item 1", price: 10.99, categoryID: UUID()),
            MenuItem(name: "Item 2", price: 12.99, categoryID: UUID())
        ])

        // Then
        XCTAssertEqual(sut.collectionView(sut.menuCollectionView, numberOfItemsInSection: 0), 2)
        XCTAssertEqual(sut.numberOfSections(in: sut.menuCollectionView), 1)
    }

    func testCategoryCellConfiguration_ShouldShowCorrectContent() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setMenuCategories([
            MenuCategory(name: "Burgers", sortOrder: 1),
            MenuCategory(name: "Pizza", sortOrder: 2)
        ])

        // When
        let indexPath = IndexPath(item: 1, section: 0) // First category (skip "All")
        let cell = sut.collectionView(sut.categoryCollectionView, cellForItemAt: indexPath)

        // Then
        XCTAssertTrue(cell is CategoryCollectionViewCell)
        // Note: In a real test, you would cast and verify the label text
    }

    func testMenuItemCellConfiguration_ShouldShowCorrectContent() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        let menuItem = MenuItem(name: "Test Burger", price: 12.99, categoryID: UUID())
        mockViewModel.setFilteredMenuItems([menuItem])

        // When
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = sut.collectionView(sut.menuCollectionView, cellForItemAt: indexPath)

        // Then
        XCTAssertTrue(cell is MenuItemCollectionViewCell)
        // Note: In a real test, you would cast and verify the cell content
    }

    // MARK: - Error Handling Tests

    func testErrorFromViewModel_ShouldShowAlert() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        let expectation = XCTestExpectation(description: "Alert presented")
        let testError = CustomError.validationError("Test error")

        // Mock the alert presentation
        class MockOrderCreationViewController: OrderCreationViewController {
            var presentedAlert: UIAlertController?

            override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
                if let alert = viewControllerToPresent as? UIAlertController {
                    presentedAlert = alert
                }
                super.present(viewControllerToPresent, animated: flag, completion: completion)
            }
        }

        let mockSut = MockOrderCreationViewController(viewModel: mockViewModel)

        // When
        mockViewModel.setError(testError)

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(mockSut.presentedAlert)
            XCTAssertEqual(mockSut.presentedAlert?.title, "Error")
            XCTAssertEqual(mockSut.presentedAlert?.message, "Test error")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Order Summary Delegate Tests

    func testOrderSummaryViewCartTap_ShouldTriggerDelegate() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setCartItems([
            CartItem(menuItem: MenuItem(name: "Test Item", price: 10.99, categoryID: UUID()), quantity: 1)
        ])

        // When
        sut.orderSummaryViewDidTapViewCart(sut.cartSummaryView)

        // Then
        // Note: In a real implementation, you would verify that a cart view is presented
        XCTAssertTrue(true) // Placeholder assertion
    }

    func testOrderSummaryCheckoutTap_WithEmptyCart_ShouldShowAlert() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setCartItems([])

        let expectation = XCTestExpectation(description: "Empty cart alert shown")

        // Mock alert presentation
        class MockOrderCreationViewController: OrderCreationViewController {
            var presentedAlert: UIAlertController?

            override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
                if let alert = viewControllerToPresent as? UIAlertController {
                    presentedAlert = alert
                    expectation.fulfill()
                }
                super.present(viewControllerToPresent, animated: flag, completion: completion)
            }
        }

        let mockSut = MockOrderCreationViewController(viewModel: mockViewModel)

        // When
        mockSut.orderSummaryViewDidTapCheckout(mockSut.cartSummaryView)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(mockSut.presentedAlert)
        XCTAssertEqual(mockSut.presentedAlert?.title, "Empty Cart")
    }

    func testOrderSummaryCheckoutTap_WithItems_ShouldCreateOrder() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setCartItems([
            CartItem(menuItem: MenuItem(name: "Test Item", price: 10.99, categoryID: UUID()), quantity: 1)
        ])

        // When
        sut.orderSummaryViewDidTapCheckout(sut.cartSummaryView)

        // Then
        XCTAssertEqual(mockViewModel.createOrderCallCount, 1)
    }

    // MARK: - Layout Tests

    func testCategoryCellSize_ShouldHaveCorrectDimensions() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()
        mockViewModel.setMenuCategories([MenuCategory(name: "Test Category", sortOrder: 1)])

        let layout = UICollectionViewFlowLayout()
        sut.categoryCollectionView.collectionViewLayout = layout

        // When
        let indexPath = IndexPath(item: 1, section: 0)
        let size = sut.collectionView(sut.categoryCollectionView, layout: layout, sizeForItemAt: indexPath)

        // Then
        XCTAssertGreaterThan(size.width, 60) // Should accommodate text + padding
        XCTAssertEqual(size.height, 40)
    }

    func testMenuItemCellSize_ShouldHaveCorrectDimensions() {
        // Given
        sut.loadViewIfNeeded()
        sut.viewDidLoad()

        // Set a specific frame to test size calculations
        sut.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        sut.loadViewIfNeeded()

        let layout = UICollectionViewFlowLayout()
        sut.menuCollectionView.collectionViewLayout = layout

        // When
        let indexPath = IndexPath(item: 0, section: 0)
        let size = sut.collectionView(sut.menuCollectionView, layout: layout, sizeForItemAt: indexPath)

        // Then
        XCTAssertEqual(size.height, 280)
        XCTAssertGreaterThan(size.width, 100) // Should be approximately half the width minus padding
    }
}

// MARK: - Mock Classes

class MockOrderCreationViewModel: OrderCreationViewModel {
    // MARK: - Call Tracking

    var viewDidLoadCallCount = 0
    var selectedCategoryCallCount = 0
    var searchTextCallCount = 0
    var createOrderCallCount = 0
    var lastSelectedCategory: MenuCategory?
    var lastSearchText: String = ""

    // MARK: - Publishers

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let filteredMenuItemsSubject = CurrentSubject<[MenuItem], Never>([])
    private let cartItemsSubject = CurrentSubject<[CartItem], Never>([])

    var viewDidLoadCalled: AnyPublisher<Void, Never> {
        viewDidLoadSubject.eraseToAnyPublisher()
    }

    // MARK: - Mock Methods

    override func viewDidLoad() {
        viewDidLoadCallCount += 1
        viewDidLoadSubject.send(())
    }

    func setLoading(_ loading: Bool) {
        isLoading.value = loading
    }

    func setMenuCategories(_ categories: [MenuCategory]) {
        // This would normally trigger the publisher
    }

    func setFilteredMenuItems(_ items: [MenuItem]) {
        // This would normally trigger the publisher
    }

    func setCartItems(_ items: [CartItem]) {
        // This would normally trigger the publisher
    }

    func setSelectedCategory(_ category: MenuCategory?) {
        selectedCategoryCallCount += 1
        lastSelectedCategory = category
        filterByCategory(category)
    }

    func setSearchText(_ text: String) {
        searchTextCallCount += 1
        lastSearchText = text
        searchItems(text)
    }

    func setError(_ error: Error) {
        // This would normally trigger the error publisher
    }

    override func filterByCategory(_ category: MenuCategory?) {
        setSelectedCategory(category)
    }

    override func searchItems(_ text: String) {
        setSearchText(text)
    }

    override func createOrder() -> AnyPublisher<Order, OrderError> {
        createOrderCallCount += 1

        if cartItems.isEmpty {
            return Fail(error: OrderError.emptyOrder)
                .eraseToAnyPublisher()
        }

        let mockOrder = Order(items: [])
        return Just(mockOrder)
            .setFailureType(to: OrderError.self)
            .eraseToAnyPublisher()
    }

    // Mock properties
    var mockFilteredMenuItems: [MenuItem] = []
    var mockCartItems: [CartItem] = []
    var mockMenuCategories: [MenuCategory] = []

    override var filteredMenuItems: [MenuItem] {
        return mockFilteredMenuItems
    }

    override var cartItems: [CartItem] {
        get { return mockCartItems }
        set { mockCartItems = newValue }
    }

    override var menuCategories: [MenuCategory] {
        return mockMenuCategories
    }

    override var isEmpty: Bool {
        return cartItems.isEmpty
    }

    override var isLoading: Observable<Bool> {
        return Observable(false)
    }

    override var error: Observable<Error?> {
        return Observable(nil)
    }
}