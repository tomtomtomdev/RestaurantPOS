import Foundation
import Combine

@MainActor
open class OrderListViewModel: BaseViewModel {
    // MARK: - Dependencies
    private let orderService: OrderServiceProtocol

    // MARK: - Published Properties
    @Published open private(set) var orders: [OrderListItem] = []
    @Published open private(set) var filteredOrders: [OrderListItem] = []

    // MARK: - Filter and Sort Properties
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }

    @Published var selectedStatuses: Set<OrderStatus> = [] {
        didSet { applyFilters() }
    }

    @Published var selectedSortOption: OrderListSortOption = .newestFirst {
        didSet { applyFilters() }
    }

    @Published var filter: OrderListFilter = OrderListFilter() {
        didSet { applyFilters() }
    }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    open var hasOrders: Bool {
        !orders.isEmpty
    }

    open var hasFilteredOrders: Bool {
        !filteredOrders.isEmpty
    }

    open var isEmpty: Bool {
        orders.isEmpty
    }

    open var noResultsFound: Bool {
        !filteredOrders.isEmpty && !searchText.isEmpty
    }

    // MARK: - Statistics
    open var totalOrdersCount: Int {
        orders.count
    }

    open var filteredOrdersCount: Int {
        filteredOrders.count
    }

    open var pendingOrdersCount: Int {
        orders.filter { $0.status == .pending }.count
    }

    open var inProgressOrdersCount: Int {
        orders.filter { $0.status == .inProgress }.count
    }

    open var completedOrdersCount: Int {
        orders.filter { $0.status == .completed }.count
    }

    open var totalRevenue: Decimal {
        orders
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var formattedTotalRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: totalRevenue)) ?? "$0.00"
    }

    // MARK: - Status Options
    var statusOptions: [OrderStatus] {
        OrderStatus.allCases
    }

    var sortOptions: [OrderListSortOption] {
        OrderListSortOption.allCases
    }

    // MARK: - Initialization
    init(orderService: OrderServiceProtocol) {
        self.orderService = orderService
        super.init()
        loadOrders()
        setupBindings()
    }

    // MARK: - Public Methods
    open func refreshOrders() {
        loadOrders()
    }

    open func updateOrderStatus(id: UUID, to status: OrderStatus) {
        setLoading(true)
        clearError()

        orderService.updateOrderStatus(id: id, status: status)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.setError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadOrders()
                }
            )
            .store(in: &cancellables)
    }

    open func deleteOrder(id: UUID) {
        setLoading(true)
        clearError()

        orderService.deleteOrder(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.setError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadOrders()
                }
            )
            .store(in: &cancellables)
    }

    func toggleStatus(_ status: OrderStatus) {
        if selectedStatuses.contains(status) {
            selectedStatuses.remove(status)
        } else {
            selectedStatuses.insert(status)
        }
    }

    func clearFilters() {
        searchText = ""
        selectedStatuses = []
        filter = OrderListFilter()
    }

    func selectAllStatuses() {
        selectedStatuses = Set(OrderStatus.allCases)
    }

    func deselectAllStatuses() {
        selectedStatuses = []
    }

    // MARK: - Private Methods
    private func loadOrders() {
        setLoading(true)
        clearError()

        orderService.getAllOrders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.setError(error)
                    }
                },
                receiveValue: { [weak self] orders in
                    self?.orders = orders.map { OrderListItem.from($0) }
                    self?.applyFilters()
                }
            )
            .store(in: &cancellables)
    }

    private func setupBindings() {
        // Search with debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = orders

        // Apply status filter
        if !selectedStatuses.isEmpty {
            result = result.filter { selectedStatuses.contains($0.status) }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { item in
                item.orderNumber.localizedCaseInsensitiveContains(searchText) ||
                item.itemsSummary.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply custom filter
        if filter.isActive {
            if !filter.statuses.isEmpty {
                result = result.filter { filter.statuses.contains($0.status) }
            }

            if !filter.searchText.isEmpty {
                result = result.filter { item in
                    item.orderNumber.localizedCaseInsensitiveContains(filter.searchText) ||
                    item.itemsSummary.localizedCaseInsensitiveContains(filter.searchText)
                }
            }

            if let dateRange = filter.dateRange {
                result = result.filter { item in
                    item.createdAt >= dateRange.startDate && item.createdAt <= dateRange.endDate
                }
            }
        }

        // Apply sorting
        filteredOrders = selectedSortOption.sort(result)
    }
}