import Foundation
import CoreData

class OrderMapper {

    static func toDomain(_ entity: OrderEntity) -> Order {
        let items = entity.items?.compactMap { $0 as? OrderItemEntity }
            .map { toItemDomain($0) } ?? []

        return Order(
            id: entity.id ?? UUID(),
            orderNumber: entity.orderNumber ?? "",
            status: OrderStatus(rawValue: entity.status ?? "pending") ?? .pending,
            items: items,
            tax: 0.0825, // Default tax rate - not stored in Core Data
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            completedAt: nil // Not in Core Data model
        )
    }

    static func toEntity(_ order: Order, in context: NSManagedObjectContext) -> OrderEntity {
        let entity = OrderEntity(context: context)
        entity.id = order.id
        entity.orderNumber = order.orderNumber
        entity.status = order.status.rawValue
        entity.totalAmount = order.totalAmount as NSDecimalNumber
        entity.createdAt = order.createdAt
        entity.updatedAt = order.updatedAt

        // Add items to the order
        let itemEntities = order.items.map { toItemEntity($0, in: context) }
        entity.items = NSSet(array: itemEntities)

        return entity
    }

    static func toItemDomain(_ entity: OrderItemEntity) -> OrderItem {
        return OrderItem(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            quantity: Int(entity.quantity),
            unitPrice: entity.unitPrice as Decimal? ?? 0,
            modifiers: entity.modifiers?.components(separatedBy: ",") ?? [],
            specialInstructions: nil // Not in Core Data model
        )
    }

    static func toItemEntity(_ item: OrderItem, in context: NSManagedObjectContext) -> OrderItemEntity {
        let entity = OrderItemEntity(context: context)
        entity.id = item.id
        entity.name = item.name
        entity.quantity = Int32(item.quantity)
        entity.unitPrice = item.unitPrice as NSDecimalNumber
        entity.modifiers = item.modifiers.joined(separator: ",")

        return entity
    }

    static func updateEntity(_ entity: OrderEntity, with order: Order) {
        entity.orderNumber = order.orderNumber
        entity.status = order.status.rawValue
        entity.totalAmount = order.totalAmount as NSDecimalNumber
        entity.updatedAt = order.updatedAt

        // Update items relationship
        let currentItems = entity.items?.compactMap { $0 as? OrderItemEntity } ?? []
        let newItems = order.items

        // Create a set of existing item IDs
        _ = Set(currentItems.compactMap { $0.id })

        // Remove items that are no longer present
        for currentItem in currentItems {
            if !newItems.contains(where: { $0.id == currentItem.id }) {
                entity.removeFromItems(currentItem)
            }
        }

        // Add or update items
        for newItem in newItems {
            if let existingItem = currentItems.first(where: { $0.id == newItem.id }) {
                updateItemEntity(existingItem, with: newItem)
            } else {
                let itemEntity = toItemEntity(newItem, in: entity.managedObjectContext!)
                entity.addToItems(itemEntity)
            }
        }
    }

    private static func updateItemEntity(_ entity: OrderItemEntity, with item: OrderItem) {
        entity.name = item.name
        entity.quantity = Int32(item.quantity)
        entity.unitPrice = item.unitPrice as NSDecimalNumber
        entity.modifiers = item.modifiers.joined(separator: ",")
    }
}
