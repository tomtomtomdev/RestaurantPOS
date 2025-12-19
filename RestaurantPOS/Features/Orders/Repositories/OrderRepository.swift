import Foundation
import CoreData
import Combine

class OrderRepository: OrderRepositoryProtocol {
    private let databaseService: DatabaseServiceProtocol

    init(databaseService: DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    func createOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let entity = OrderMapper.toEntity(order, in: context)

                    // Check if order number already exists
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "orderNumber == %@", order.orderNumber)
                    let existingOrders = try context.fetch(fetchRequest)

                    if !existingOrders.isEmpty {
                        promise(.failure(.invalidItemIndex))
                        return
                    }

                    try context.save()

                    // Fetch the saved order to get the complete entity
                    fetchRequest.predicate = NSPredicate(format: "id == %@", order.id as CVarArg)
                    let savedEntities = try context.fetch(fetchRequest)

                    if let savedEntity = savedEntities.first {
                        let savedOrder = OrderMapper.toDomain(savedEntity)
                        promise(.success(savedOrder))
                    } else {
                        promise(.failure(.invalidItemIndex))
                    }
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getOrder(id: UUID) -> AnyPublisher<Order?, OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    fetchRequest.fetchLimit = 1

                    let entities = try context.fetch(fetchRequest)
                    let order = entities.first.map { OrderMapper.toDomain($0) }
                    promise(.success(order))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getAllOrders() -> AnyPublisher<[Order], OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

                    let entities = try context.fetch(fetchRequest)
                    let orders = entities.map { OrderMapper.toDomain($0) }
                    promise(.success(orders))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getOrdersWithStatus(_ status: OrderStatus) -> AnyPublisher<[Order], OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "status == %@", status.rawValue)
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

                    let entities = try context.fetch(fetchRequest)
                    let orders = entities.map { OrderMapper.toDomain($0) }
                    promise(.success(orders))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", order.id as CVarArg)
                    fetchRequest.fetchLimit = 1

                    let entities = try context.fetch(fetchRequest)

                    guard let entity = entities.first else {
                        promise(.failure(.invalidItemIndex))
                        return
                    }

                    OrderMapper.updateEntity(entity, with: order)
                    try context.save()

                    let updatedOrder = OrderMapper.toDomain(entity)
                    promise(.success(updatedOrder))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    fetchRequest.fetchLimit = 1

                    let entities = try context.fetch(fetchRequest)

                    guard let entity = entities.first else {
                        promise(.failure(.invalidItemIndex))
                        return
                    }

                    context.delete(entity)
                    try context.save()
                    promise(.success(()))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getOrders(from startDate: Date, to endDate: Date) -> AnyPublisher<[Order], OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(
                        format: "createdAt >= %@ AND createdAt <= %@",
                        startDate as NSDate,
                        endDate as NSDate
                    )
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

                    let entities = try context.fetch(fetchRequest)
                    let orders = entities.map { OrderMapper.toDomain($0) }
                    promise(.success(orders))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func searchOrders(query: String) -> AnyPublisher<[Order], OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

                    if trimmedQuery.isEmpty {
                        // Return all orders if query is empty
                        let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                        let entities = try context.fetch(fetchRequest)
                        let orders = entities.map { OrderMapper.toDomain($0) }
                        promise(.success(orders))
                        return
                    }

                    // Search by order number or item name
                    let orderNumberPredicate = NSPredicate(format: "orderNumber CONTAINS[cd] %@", trimmedQuery)
                    let itemPredicate = NSPredicate(format: "ANY items.name CONTAINS[cd] %@", trimmedQuery)
                    let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [orderNumberPredicate, itemPredicate])

                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    fetchRequest.predicate = searchPredicate
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

                    let entities = try context.fetch(fetchRequest)
                    let orders = entities.map { OrderMapper.toDomain($0) }
                    promise(.success(orders))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getOrdersCount() -> AnyPublisher<Int, OrderError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.invalidItemIndex))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
                    let count = try context.count(for: fetchRequest)
                    promise(.success(count))
                } catch {
                    promise(.failure(.invalidItemIndex))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}