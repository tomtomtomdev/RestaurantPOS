//
//  OrderCreationViewModel.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation
import Combine

// MARK: - Custom Error

enum CustomError: Error, LocalizedError {
    case networkError(String)
    case validationError(String)
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Cart Item

public struct CartItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let menuItem: MenuItem
    public let quantity: Int
    public let selectedModifiers: [MenuItemModifier]
    public let specialInstructions: String?

    public init(
        id: UUID = UUID(),
        menuItem: MenuItem,
        quantity: Int = 1,
        selectedModifiers: [MenuItemModifier] = [],
        specialInstructions: String? = nil
    ) {
        self.id = id
        self.menuItem = menuItem
        self.quantity = quantity
        self.selectedModifiers = selectedModifiers
        self.specialInstructions = specialInstructions
    }

    public var unitPrice: Decimal {
        menuItem.price + selectedModifiers.reduce(0) { $0 + $1.price }
    }

    public var totalPrice: Decimal {
        unitPrice * Decimal(quantity)
    }

    public var name: String {
        menuItem.name
    }

    public var description: String? {
        menuItem.description
    }
}

// MARK: - Order Creation ViewModel

@MainActor
open class OrderCreationViewModel: BaseViewModel {

    // MARK: - Published Properties

    @Published public private(set) var cartItems: [CartItem] = []
    @Published public private(set) var menuCategories: [MenuCategory] = []
    @Published public private(set) var menuItems: [MenuItem] = []
    @Published public private(set) var filteredMenuItems: [MenuItem] = []
    @Published public var selectedCategory: MenuCategory?
    @Published public var searchText: String = ""
    @Published public private(set) var subtotal: Decimal = 0
    @Published public private(set) var tax: Decimal = 0
    @Published public private(set) var totalAmount: Decimal = 0
    @Published public private(set) var itemCount: Int = 0

    // MARK: - Configuration

    private let taxRate: Decimal = 0.0825 // 8.25% tax rate
    private let menuRepository: MenuRepositoryProtocol
    private let orderRepository: OrderRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    public var isEmpty: Bool {
        cartItems.isEmpty
    }

    public var hasItems: Bool {
        !cartItems.isEmpty
    }

    public var formattedSubtotal: String {
        formatCurrency(subtotal)
    }

    public var formattedTax: String {
        formatCurrency(tax)
    }

    public var formattedTotal: String {
        formatCurrency(totalAmount)
    }

    public var isSearching: Bool {
        !searchText.isEmpty
    }

    // MARK: - Initialization

    public init(
        menuRepository: MenuRepositoryProtocol = MenuRepository(),
        orderRepository: OrderRepositoryProtocol = OrderRepository(databaseService: CoreDataStack.shared)
    ) {
        self.menuRepository = menuRepository
        self.orderRepository = orderRepository
        super.init()
        setupBindings()
    }

    // MARK: - Public Methods

    /// Load menu categories and items
    public func loadMenu() {
        setLoading(true)
        clearError()

        Task {
            do {
                async let categoriesTask = menuRepository.getCategories()
                async let itemsTask = menuRepository.getMenuItems()

                let (categories, items) = try await (categoriesTask, itemsTask)

                await MainActor.run {
                    self.menuCategories = categories.sorted { $0.sortOrder < $1.sortOrder }
                    self.menuItems = items
                    self.filteredMenuItems = items
                    self.setLoading(false)
                }
            } catch {
                await MainActor.run {
                    self.setError(CustomError.networkError(error.localizedDescription))
                    self.setLoading(false)
                }
            }
        }
    }

    /// Add an item to the cart
    public func addToCart(
        menuItem: MenuItem,
        quantity: Int = 1,
        modifiers: [MenuItemModifier] = [],
        specialInstructions: String? = nil
    ) {
        guard quantity > 0 else {
            setError(CustomError.validationError("Quantity must be greater than 0"))
            return
        }

        let cartItem = CartItem(
            menuItem: menuItem,
            quantity: quantity,
            selectedModifiers: modifiers,
            specialInstructions: specialInstructions
        )

        // Check if item already exists with same modifiers
        if let existingIndex = cartItems.firstIndex(where: { item in
            item.menuItem.id == menuItem.id &&
            item.selectedModifiers == modifiers &&
            item.specialInstructions == specialInstructions
        }) {
            // Update quantity of existing item
            let existingItem = cartItems[existingIndex]
            let newQuantity = existingItem.quantity + quantity
            cartItems[existingIndex] = CartItem(
                id: existingItem.id,
                menuItem: existingItem.menuItem,
                quantity: newQuantity,
                selectedModifiers: existingItem.selectedModifiers,
                specialInstructions: existingItem.specialInstructions
            )
        } else {
            // Add new item
            cartItems.append(cartItem)
        }

        recalculateTotals()
    }

    /// Remove an item from the cart
    public func removeFromCart(at index: Int) {
        guard index >= 0 && index < cartItems.count else {
            setError(CustomError.validationError("Invalid item index"))
            return
        }

        cartItems.remove(at: index)
        recalculateTotals()
    }

    /// Update quantity of a cart item
    public func updateItemQuantity(at index: Int, quantity: Int) {
        guard index >= 0 && index < cartItems.count else {
            setError(CustomError.validationError("Invalid item index"))
            return
        }

        guard quantity > 0 else {
            setError(CustomError.validationError("Quantity must be greater than 0"))
            return
        }

        let existingItem = cartItems[index]
        cartItems[index] = CartItem(
            id: existingItem.id,
            menuItem: existingItem.menuItem,
            quantity: quantity,
            selectedModifiers: existingItem.selectedModifiers,
            specialInstructions: existingItem.specialInstructions
        )

        recalculateTotals()
    }

    /// Clear all items from the cart
    public func clearCart() {
        cartItems.removeAll()
        recalculateTotals()
    }

    /// Filter menu items by selected category
    public func filterByCategory(_ category: MenuCategory?) {
        selectedCategory = category

        if let category = category {
            filteredMenuItems = menuItems.filter { $0.categoryID == category.id }
        } else {
            filteredMenuItems = menuItems
        }

        applySearchFilter()
    }

    /// Search menu items by text
    public func searchItems(_ text: String) {
        searchText = text
        applySearchFilter()
    }

    /// Create an order from the current cart
    public func createOrder() -> AnyPublisher<Order, OrderError> {
        guard !cartItems.isEmpty else {
            return Fail(error: OrderError.emptyOrder)
                .eraseToAnyPublisher()
        }

        let orderItems = cartItems.map { cartItem in
            OrderItem(
                name: cartItem.name,
                quantity: cartItem.quantity,
                unitPrice: cartItem.unitPrice,
                modifiers: cartItem.selectedModifiers.map { $0.name },
                specialInstructions: cartItem.specialInstructions
            )
        }

        let order = Order(
            items: orderItems,
            tax: taxRate
        )

        setLoading(true)

        return orderRepository.createOrder(order)
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.clearCart()
                },
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.setError(CustomError.custom(error.localizedDescription))
                    }
                }
            )
            .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Filter items when search text changes
        $searchText
            .sink { [weak self] _ in
                self?.applySearchFilter()
            }
            .store(in: &cancellables)
    }

    private func applySearchFilter() {
        var items = filteredMenuItems

        if let selectedCategory = selectedCategory {
            items = items.filter { $0.categoryID == selectedCategory.id }
        }

        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        self.filteredMenuItems = items
    }

    private func recalculateTotals() {
        subtotal = cartItems.reduce(0) { $0 + $1.totalPrice }
        tax = subtotal * taxRate
        totalAmount = subtotal + tax
        itemCount = cartItems.reduce(0) { $0 + $1.quantity }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Menu Repository Protocol

public protocol MenuRepositoryProtocol {
    func getCategories() async throws -> [MenuCategory]
    func getMenuItems() async throws -> [MenuItem]
    func getMenuItems(for categoryID: UUID) async throws -> [MenuItem]
}

// MARK: - Menu Repository Implementation

public class MenuRepository: MenuRepositoryProtocol {
    private let databaseService: DatabaseServiceProtocol

    public init(databaseService: DatabaseServiceProtocol = CoreDataStack.shared) {
        self.databaseService = databaseService
    }

    public func getCategories() async throws -> [MenuCategory] {
        // For now, return sample data
        // In a real app, this would fetch from Core Data or API
        return MenuCategory.sampleCategories
    }

    public func getMenuItems() async throws -> [MenuItem] {
        // For now, return sample data
        // In a real app, this would fetch from Core Data or API
        return MenuItem.sampleItems
    }

    public func getMenuItems(for categoryID: UUID) async throws -> [MenuItem] {
        let allItems = try await getMenuItems()
        return allItems.filter { $0.categoryID == categoryID }
    }
}