import XCTest
@testable import RestaurantPOS

final class OrderListViewControllerTests: XCTestCase {
    var viewController: OrderListViewController!
    var mockViewModel: MockOrderListViewModel!

    override func setUp() {
        super.setUp()
        mockViewModel = MockOrderListViewModel()
        viewController = OrderListViewController(viewModel: mockViewModel)

        // Load the view hierarchy
        viewController.loadViewIfNeeded()
        viewController.viewDidLoad()
    }

    override func tearDown() {
        viewController = nil
        mockViewModel = nil
        super.tearDown()
    }

    func testViewControllerSetup() {
        XCTAssertNotNil(viewController.tableView)
        XCTAssertNotNil(viewController.searchController)
        XCTAssertEqual(viewController.title, "Orders")
        XCTAssertFalse(viewController.isEmpty)
    }

    func testTableViewDataSource() {
        // Set up mock orders
        let order1 = createMockOrderListItem(orderNumber: "ORD-001", itemCount: 2)
        let order2 = createMockOrderListItem(orderNumber: "ORD-002", itemCount: 3)
        mockViewModel.filteredOrders = [order1, order2]

        // Test data source methods
        XCTAssertEqual(viewController.tableView(viewController.tableView, numberOfRowsInSection: 0), 2)

        let cell = viewController.tableView(viewController.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is OrderListTableViewCell)
    }

    func testTableViewDelegate() {
        // Set up mock orders
        let order1 = createMockOrderListItem(orderNumber: "ORD-001", itemCount: 2)
        mockViewModel.filteredOrders = [order1]

        // Test row height
        XCTAssertEqual(viewController.tableView(viewController.tableView, heightForRowAt: IndexPath(row: 0, section: 0)), 100)

        // Test selection
        let indexPath = IndexPath(row: 0, section: 0)
        viewController.tableView(viewController.tableView, didSelectRowAt: indexPath)

        // Verify selection behavior (print statement in didSelectRowAt)
        // In a real app, this would navigate to order details
    }

    func testSearchController() {
        XCTAssertNotNil(viewController.searchController)
        XCTAssertFalse(viewController.searchController.obscuresBackgroundDuringPresentation)
        XCTAssertEqual(viewController.searchController.searchBar.placeholder, "Search orders...")
    }

    func testBarButtons() {
        XCTAssertNotNil(viewController.filterBarButtonItem)
        XCTAssertNotNil(viewController.sortBarButtonItem)
        XCTAssertEqual(viewController.navigationItem.rightBarButtonItems?.count, 2)
    }

    func testEmptyStateVisibility() {
        // Initially, empty state should be visible if no orders
        mockViewModel.isEmpty = true
        viewController.updateEmptyState()

        // In a real test, we'd verify the empty state view is visible
        // This would require accessing private properties or adding test accessors
    }

    func testStatisticsDisplay() {
        // Set up mock orders with different statuses
        let order1 = createMockOrderListItem(orderNumber: "ORD-001", status: .completed)
        let order2 = createMockOrderListItem(orderNumber: "ORD-002", status: .pending)
        mockViewModel.orders = [order1, order2]

        viewController.updateStatistics()

        // Verify statistics are updated
        // In a real test, we'd verify the revenue label text
    }

    func testRefreshControl() {
        let refreshControl = viewController.tableView.refreshControl
        XCTAssertNotNil(refreshControl)

        // Simulate refresh
        refreshControl?.sendActions(for: .valueChanged)

        // Verify refresh was triggered
        XCTAssertTrue(mockViewModel.refreshCalled)
    }

    func testLoadingState() {
        // Simulate loading state
        mockViewModel.isLoading = true

        // Verify loading indicator is shown
        XCTAssertTrue(viewController.loadingIndicator.isAnimating)
        XCTAssertTrue(viewController.tableView.isHidden)
    }

    func testErrorHandling() {
        let error = OrderError.invalidItemIndex
        mockViewModel.error = error

        // In a real test, we'd verify an alert is shown
        // This would require mocking UIAlertController
    }

    // MARK: - Helper Methods

    private func createMockOrderListItem(
        orderNumber: String = "ORD-001",
        status: OrderStatus = .pending,
        itemCount: Int = 1,
        totalAmount: Decimal = 10.99,
        createdAt: Date = Date()
    ) -> OrderListItem {
        let items = [OrderItem(name: "Test Item", quantity: itemCount, unitPrice: totalAmount)]
        return OrderListItem(
            orderNumber: orderNumber,
            status: status,
            itemCount: itemCount,
            totalAmount: totalAmount,
            createdAt: createdAt,
            items: items
        )
    }
}

// MARK: - Mock OrderListViewModel for Testing

class MockOrderListViewModel: OrderListViewModel {
    // Test-accessible properties
    var isEmpty: Bool = false {
        didSet { objectWillChange.send() }
    }

    var filteredOrders: [OrderListItem] = [] {
        didSet { objectWillChange.send() }
    }

    var orders: [OrderListItem] = [] {
        didSet { objectWillChange.send() }
    }

    var isLoading: Bool = false {
        didSet { objectWillChange.send() }
    }

    var error: OrderError? {
        didSet { objectWillChange.send() }
    }

    var searchText: String = ""
    var selectedStatuses: Set<OrderStatus> = []
    var selectedSortOption: OrderListSortOption = .newestFirst

    // Test tracking
    var refreshCalled = false
    var updateOrderStatusCalled = false
    var deleteOrderCalled = false

    // Override computed properties for testing
    override var filteredOrdersCount: Int {
        return filteredOrders.count
    }

    override var totalOrdersCount: Int {
        return orders.count
    }

    override var completedOrdersCount: Int {
        return orders.filter { $0.status == .completed }.count
    }

    // Override methods for testing
    override func refresh() {
        refreshCalled = true
    }

    override func updateOrderStatus(id: UUID, to status: OrderStatus) {
        updateOrderStatusCalled = true
    }

    override func deleteOrder(id: UUID) {
        deleteOrderCalled = true
    }

    // Make objectWillChange.send() available
    private let objectWillChange = PassthroughSubject<Void, Never>()
}