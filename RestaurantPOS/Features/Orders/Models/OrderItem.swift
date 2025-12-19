import Foundation

struct OrderItem: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    var quantity: Int
    let unitPrice: Decimal
    var modifiers: [String]
    var specialInstructions: String?

    init(
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

    var totalPrice: Decimal {
        let modifierPrice = Decimal(modifiers.count) * 0.50
        return (unitPrice + modifierPrice) * Decimal(quantity)
    }

    var modifierPrice: Decimal {
        Decimal(modifiers.count) * 0.50
    }

    var displayName: String {
        if modifiers.isEmpty {
            return name
        }
        return "\(name) (\(modifiers.joined(separator: ", ")))"
    }

    func withQuantity(_ quantity: Int) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: specialInstructions
        )
    }

    func withModifiers(_ modifiers: [String]) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: specialInstructions
        )
    }

    func withSpecialInstructions(_ instructions: String?) -> OrderItem {
        return OrderItem(
            id: id,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            modifiers: modifiers,
            specialInstructions: instructions
        )
    }

    static func == (lhs: OrderItem, rhs: OrderItem) -> Bool {
        return lhs.id == rhs.id ||
               (lhs.name == rhs.name &&
                lhs.unitPrice == rhs.unitPrice &&
                lhs.modifiers == rhs.modifiers &&
                lhs.specialInstructions == rhs.specialInstructions)
    }
}

extension OrderItem {
    init(
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