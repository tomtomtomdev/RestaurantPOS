//
//  PaymentRepository.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation
import CoreData
import Combine

// MARK: - Payment Repository Protocol

public protocol PaymentRepositoryProtocol {
    func createPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError>
    func getPayment(id: UUID) -> AnyPublisher<Payment?, PaymentError>
    func getPayments(for orderID: UUID) -> AnyPublisher<[Payment], PaymentError>
    func getAllPayments() -> AnyPublisher<[Payment], PaymentError>
    func updatePayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError>
    func deletePayment(id: UUID) -> AnyPublisher<Void, PaymentError>
    func getPaymentsWithStatus(_ status: PaymentStatus) -> AnyPublisher<[Payment], PaymentError>
    func getPayments(from startDate: Date, to endDate: Date) -> AnyPublisher<[Payment], PaymentError>
    func getPaymentsCount() -> AnyPublisher<Int, PaymentError>
    func searchPayments(query: String) -> AnyPublisher<[Payment], PaymentError>
}

// MARK: - Payment Repository Implementation

public class PaymentRepository: PaymentRepositoryProtocol {

    // MARK: - Properties

    private let databaseService: DatabaseServiceProtocol
    private let paymentMapper = PaymentMapper()

    // MARK: - Initialization

    public init(databaseService: DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - CRUD Operations

    public func createPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    // Check for duplicate payments
                    let existingPayments = try self.fetchPayments(for: payment.orderID, in: context)
                    if existingPayments.contains(where: { $0.status == .completed }) {
                        promise(.failure(.duplicatePayment))
                        return
                    }

                    // Create new payment entity
                    let paymentEntity = PaymentEntity(context: context)
                    self.paymentMapper.map(payment, to: paymentEntity)

                    try context.save()

                    // Return the created payment with generated ID
                    let createdPayment = self.paymentMapper.map(from: paymentEntity)
                    promise(.success(createdPayment))

                } catch {
                    context.rollback()
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getPayment(id: UUID) -> AnyPublisher<Payment?, PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1

                    let results = try context.fetch(request)
                    let payment = results.first.map { self.paymentMapper.map(from: $0) }
                    promise(.success(payment))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getPayments(for orderID: UUID) -> AnyPublisher<[Payment], PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let payments = try self.fetchPayments(for: orderID, in: context)
                    let paymentModels = payments.map { self.paymentMapper.map(from: $0) }
                    promise(.success(paymentModels))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getAllPayments() -> AnyPublisher<[Payment], PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentEntity.createdAt, ascending: false)]

                    let results = try context.fetch(request)
                    let payments = results.map { self.paymentMapper.map(from: $0) }
                    promise(.success(payments))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func updatePayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", payment.id as CVarArg)
                    request.fetchLimit = 1

                    let results = try context.fetch(request)
                    guard let paymentEntity = results.first else {
                        promise(.failure(.paymentNotFound))
                        return
                    }

                    self.paymentMapper.map(payment, to: paymentEntity)
                    try context.save()

                    let updatedPayment = self.paymentMapper.map(from: paymentEntity)
                    promise(.success(updatedPayment))

                } catch {
                    context.rollback()
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func deletePayment(id: UUID) -> AnyPublisher<Void, PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                    request.fetchLimit = 1

                    let results = try context.fetch(request)
                    guard let paymentEntity = results.first else {
                        promise(.failure(.paymentNotFound))
                        return
                    }

                    context.delete(paymentEntity)
                    try context.save()
                    promise(.success(()))

                } catch {
                    context.rollback()
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Query Operations

    public func getPaymentsWithStatus(_ status: PaymentStatus) -> AnyPublisher<[Payment], PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.predicate = NSPredicate(format: "status == %@", status.rawValue)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentEntity.createdAt, ascending: false)]

                    let results = try context.fetch(request)
                    let payments = results.map { self.paymentMapper.map(from: $0) }
                    promise(.success(payments))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getPayments(from startDate: Date, to endDate: Date) -> AnyPublisher<[Payment], PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "createdAt >= %@ AND createdAt <= %@",
                        startDate as CVarArg,
                        endDate as CVarArg
                    )
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentEntity.createdAt, ascending: false)]

                    let results = try context.fetch(request)
                    let payments = results.map { self.paymentMapper.map(from: $0) }
                    promise(.success(payments))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func getPaymentsCount() -> AnyPublisher<Int, PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
                    let count = try context.count(for: request)
                    promise(.success(count))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    public func searchPayments(query: String) -> AnyPublisher<[Payment], PaymentError> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(.paymentNotFound))
                return
            }

            let context = self.databaseService.newBackgroundContext()
            context.perform {
                do {
                    let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()

                    // Search in transaction ID, last four digits, and processor
                    let searchPredicates = [
                        NSPredicate(format: "transactionID CONTAINS[cd] %@", query),
                        NSPredicate(format: "lastFourDigits CONTAINS[cd] %@", query),
                        NSPredicate(format: "processor CONTAINS[cd] %@", query)
                    ]

                    request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: searchPredicates)
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentEntity.createdAt, ascending: false)]

                    let results = try context.fetch(request)
                    let payments = results.map { self.paymentMapper.map(from: $0) }
                    promise(.success(payments))

                } catch {
                    promise(.failure(.processorError(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Helper Methods

    private func fetchPayments(for orderID: UUID, in context: NSManagedObjectContext) throws -> [PaymentEntity] {
        let request: NSFetchRequest<PaymentEntity> = PaymentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "orderID == %@", orderID as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentEntity.createdAt, ascending: false)]
        return try context.fetch(request)
    }

    // MARK: - Statistics and Analytics

    public func getTotalRevenue(from startDate: Date, to endDate: Date) -> AnyPublisher<Decimal, PaymentError> {
        return getPayments(from: startDate, to: endDate)
            .map { payments in
                payments
                    .filter { $0.status == .completed }
                    .reduce(0) { $0 + $1.amount }
            }
            .eraseToAnyPublisher()
    }

    public func getPaymentTypeDistribution(from startDate: Date, to endDate: Date) -> AnyPublisher<[PaymentType: Int], PaymentError> {
        return getPayments(from: startDate, to: endDate)
            .map { payments in
                let completedPayments = payments.filter { $0.status == .completed }
                return Dictionary(grouping: completedPayments, by: { $0.paymentType })
                    .mapValues { $0.count }
            }
            .eraseToAnyPublisher()
    }

    public func getRefundTotal(from startDate: Date, to endDate: Date) -> AnyPublisher<Decimal, PaymentError> {
        return getPayments(from: startDate, to: endDate)
            .map { payments in
                payments
                    .filter { $0.status == .refunded || $0.status == .partiallyRefunded }
                    .reduce(0) { $0 + $1.amount }
            }
            .eraseToAnyPublisher()
    }
}