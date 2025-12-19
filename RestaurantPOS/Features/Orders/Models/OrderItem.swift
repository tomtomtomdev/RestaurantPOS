import Foundation

public struct OrderItem: Codable, Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public var quantity: Int
    public let unitPrice: Decimal
    public var modifiers: [String]
    public var specialInstructions: String?

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        unitPrice: Decimal,
        modifiers: [String] = [],
        specialInstructions: String? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.modifiers = modifiers
        self.specialInstructions = specialInstructions
    }

    public var totalPrice: Decimal {
        let modifierPrice = Decimal(modifiers.count) * 0.50
        return (unitPrice + modifierPrice) * Decimal(quantity)
    }

    public var modifierPrice: Decimal {
        Decimal(modifiers.count) * 0.50
    }

    public var displayName: String {
        if modifiers.isEmpty {
            return name
        }
        return "\(name) (\(modifiers.joined(separator: ", ")))"
    }

    public func withQuantity(_ quantity: Int) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: specialInstructions
        )
    }

    public func withModifiers(_ modifiers: [String]) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: specialInstructions
        )
    }

    public func withSpecialInstructions(_ instructions: String?) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: instructions
        )
    }

    public static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.id == rhs.id ||
               (lhs.name == rhs.name &&
                lhs.unitPrice == rhs.unitPrice &&
                lhs.modifiers == rhs.modifiers &&
                lhs.specialInstructions == rhs.specialInstructions)
    }
}

extension OrderItem {
    public init(
        name: String,
        quantity: Int,
        unitPrice: Decimal,
        modifiers: [String] = [],
        specialInstructions: String? = nil
    ) {
        self.init(
            id: UUID(),
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: specialInstructions
        )
    }
}