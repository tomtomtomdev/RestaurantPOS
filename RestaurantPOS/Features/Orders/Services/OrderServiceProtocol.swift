import Foundation
import Combine

protocol OrderServiceProtocol {
    func createOrder() -> AnyPublisher<Order, OrderError>
    func getOrder(id: UUID) -> AnyPublisher<Order?, OrderError>
    func getAllOrders() -> AnyPublisher<[Order], OrderError>
    func getOrdersWithStatus(_ status: OrderStatus) -> AnyPublisher<[Order], OrderError>
    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError>
    func updateOrderStatus(id: UUID, status: OrderStatus) -> AnyPublisher<Order, OrderError>
    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError>
    func addItemToOrder(orderId: UUID, item: OrderItem) -> AnyPublisher<Order, OrderError>
    func removeItemFromOrder(orderId: UUID, itemIndex: Int) -> AnyPublisher<Order, OrderError>
    func updateItemQuantity(orderId: UUID, itemIndex: Int, quantity: Int) -> AnyPublisher<Order, OrderError>
    func getOrders(from startDate: Date, to endDate: Date) -> AnyPublisher<[Order], OrderError>
    func searchOrders(query: String) -> AnyPublisher<[Order], OrderError>
}