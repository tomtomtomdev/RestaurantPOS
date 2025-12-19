import Foundation
import Combine

protocol OrderRepositoryProtocol {
    func createOrder(_ order: Order) -> AnyPublisher<Order, OrderError>
    func getOrder(id: UUID) -> AnyPublisher<Order?, OrderError>
    func getAllOrders() -> AnyPublisher<[Order], OrderError>
    func getOrdersWithStatus(_ status: OrderStatus) -> AnyPublisher<[Order], OrderError>
    func updateOrder(_ order: Order) -> AnyPublisher<Order, OrderError>
    func deleteOrder(id: UUID) -> AnyPublisher<Void, OrderError>
    func getOrders(from startDate: Date, to endDate: Date) -> AnyPublisher<[Order], OrderError>
    func searchOrders(query: String) -> AnyPublisher<[Order], OrderError>
    func getOrdersCount() -> AnyPublisher<Int, OrderError>
}