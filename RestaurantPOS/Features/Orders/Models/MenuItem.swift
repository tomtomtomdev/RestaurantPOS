import Foundation

public struct MenuItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let price: Decimal
    public let categoryID: UUID
    public let imageURL: String?
    public let isAvailable: Bool
    public let preparationTime: TimeInterval // in seconds
    public let ingredients: [String]
    public let allergens: [String]
    public let modifiers: [MenuItemModifier]
    public let nutritionalInfo: NutritionalInfo?

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        price: Decimal,
        categoryID: UUID,
        imageURL: String? = nil,
        isAvailable: Bool = true,
        preparationTime: TimeInterval = 0,
        ingredients: [String] = [],
        allergens: [String] = [],
        modifiers: [MenuItemModifier] = [],
        nutritionalInfo: NutritionalInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.categoryID = categoryID
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.preparationTime = preparationTime
        self.ingredients = ingredients
        self.allergens = allergens
        self.modifiers = modifiers
        self.nutritionalInfo = nutritionalInfo
    }
}

// MARK: - Supporting Types

public struct MenuItemModifier: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let price: Decimal
    public let options: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        price: Decimal,
        options: [String] = []
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.options = options
    }
}

public struct NutritionalInfo: Codable, Equatable {
    public let calories: Int
    public let protein: Decimal
    public let carbs: Decimal
    public let fat: Decimal
    public let sodium: Int
    public let sugar: Int

    public init(
        calories: Int = 0,
        protein: Decimal = 0,
        carbs: Decimal = 0,
        fat: Decimal = 0,
        sodium: Int = 0,
        sugar: Int = 0
    ) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
    }
}

// MARK: - Helper Extensions

extension MenuItem {
    public var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: price)) ?? "$0.00"
    }

    public var formattedPreparationTime: String {
        if preparationTime <= 0 {
            return "Ready"
        } else if preparationTime < 60 {
            return "\(Int(preparationTime)) sec"
        } else if preparationTime < 3600 {
            let minutes = Int(preparationTime / 60)
            return "\(minutes) min"
        } else {
            let hours = Int(preparationTime / 3600)
            let minutes = Int((preparationTime.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h")"
        }
    }

    public var hasAllergens: Bool {
        !allergens.isEmpty
    }

    public var hasModifiers: Bool {
        !modifiers.isEmpty
    }

    public var hasImage: Bool {
        imageURL != nil && !imageURL!.isEmpty
    }

    public var estimatedTotalPrice: Decimal {
        let basePrice = price
        let modifierPrice = modifiers.reduce(0) { $0 + $1.price }
        return basePrice + modifierPrice
    }
}

// MARK: - Menu Item Builder

public class MenuItemBuilder {
    private var id: UUID = UUID()
    private var name: String = ""
    private var description: String? = nil
    private var price: Decimal = 0.0
    private var categoryID: UUID = UUID()
    private var imageURL: String? = nil
    private var isAvailable: Bool = true
    private var preparationTime: TimeInterval = 0
    private var ingredients: [String] = []
    private var allergens: [String] = []
    private var modifiers: [MenuItemModifier] = []
    private var nutritionalInfo: NutritionalInfo? = nil

    public init(name: String, price: Decimal) {
        self.name = name
        self.price = price
    }

    @discardableResult
    public func withID(_ id: UUID) -> MenuItemBuilder {
        self.id = id
        return self
    }

    @discardableResult
    public func withDescription(_ description: String) -> MenuItemBuilder {
        self.description = description
        return self
    }

    @discardableResult
    public func withCategoryID(_ categoryID: UUID) -> MenuItemBuilder {
        self.categoryID = categoryID
        return self
    }

    @discardableResult
    public func withImageURL(_ imageURL: String?) -> MenuItemBuilder {
        self.imageURL = imageURL
        return self
    }

    @discardableResult
    public func withAvailability(_ isAvailable: Bool) -> MenuItemBuilder {
        self.isAvailable = isAvailable
        return self
    }

    @discardableResult
    public func withPreparationTime(_ preparationTime: TimeInterval) -> MenuItemBuilder {
        self.preparationTime = preparationTime
        return self
    }

    @discardableResult
    public func withIngredients(_ ingredients: [String]) -> MenuItemBuilder {
        self.ingredients = ingredients
        return self
    }

    @discardableResult
    public func withAllergens(_ allergens: [String]) -> MenuItemBuilder {
        self.allergens = allergens
        return self
    }

    @discardableResult
    public func withModifiers(_ modifiers: [MenuItemModifier]) -> MenuItemBuilder {
        self.modifiers = modifiers
        return self
    }

    @discardableResult
    public func withNutritionalInfo(_ nutritionalInfo: NutritionalInfo) -> MenuItemBuilder {
        self.nutritionalInfo = nutritionalInfo
        return self
    }

    public func build() -> MenuItem {
        return MenuItem(
            id: id,
            name: name,
            description: description,
            price: price,
            categoryID: categoryID,
            imageURL: imageURL,
            isAvailable: isAvailable,
            preparationTime: preparationTime,
            ingredients: ingredients,
            allergens: allergens,
            modifiers: modifiers,
            nutritionalInfo: nutritionalInfo
        )
    }
}