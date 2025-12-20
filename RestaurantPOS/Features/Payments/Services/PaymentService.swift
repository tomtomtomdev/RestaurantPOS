//
//  PaymentService.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation
import Combine

// MARK: - Payment Service Protocol

public protocol PaymentServiceProtocol {
    func processPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError>
    func refundPayment(_ payment: Payment, amount: Decimal) -> AnyPublisher<Payment, PaymentError>
    func voidPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError>
    func getPaymentMethods(for processor: PaymentProcessor) -> AnyPublisher<[PaymentMethod], PaymentError>
    func validatePayment(_ payment: Payment) -> AnyPublisher<Void, PaymentError>
    func calculateFees(for payment: Payment, processor: PaymentProcessor) -> AnyPublisher<Decimal, PaymentError>
}

// MARK: - Payment Service Implementation

public class PaymentService: PaymentServiceProtocol {

    // MARK: - Properties

    private let paymentRepository: PaymentRepositoryProtocol
    private let orderRepository: OrderRepositoryProtocol

    // MARK: - Initialization

    public init(
        paymentRepository: PaymentRepositoryProtocol,
        orderRepository: OrderRepositoryProtocol
    ) {
        self.paymentRepository = paymentRepository
        self.orderRepository = orderRepository
    }

    // MARK: - Payment Processing

    public func processPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        // Validate payment first
        let validationResult = payment.validate()
        switch validationResult {
        case .success:
            break
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }

        // Check if order is in a valid state for payment
        return orderRepository.getOrder(id: payment.orderID)
            .tryMap { order -> Order in
                guard let order = order else {
                    throw PaymentError.invalidOrder
                }

                // Validate order status allows payment
                guard order.status.canTransition(to: .completed) else {
                    throw PaymentError.invalidOrder
                }

                // Validate payment amount matches order total
                if abs(order.totalAmount - payment.amount) > 0.01 {
                    throw PaymentError.invalidAmount
                }

                return order
            }
            .mapError { error in
                if let paymentError = error as? PaymentError {
                    return paymentError
                } else {
                    return PaymentError.processorError(error.localizedDescription)
                }
            }
            .flatMap { [weak self] order -> AnyPublisher<Payment, PaymentError> in
                self?.processPaymentForOrder(payment, order: order) ?? Fail(error: PaymentError.processorUnavailable)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func processPaymentForOrder(_ payment: Payment, order: Order) -> AnyPublisher<Payment, PaymentError> {
        // Update payment status to processing
        let processingPayment = payment.withStatus(.processing)
        switch processingPayment {
        case .success(let updatedPayment):
            return paymentRepository.createPayment(updatedPayment)
                .flatMap { [weak self] savedPayment -> AnyPublisher<Payment, PaymentError> in
                    // Simulate payment processing
                    return self?.simulatePaymentProcessing(savedPayment) ?? Fail(error: PaymentError.processorUnavailable)
                        .eraseToAnyPublisher()
                }
                .flatMap { [weak self] processedPayment -> AnyPublisher<Payment, PaymentError> in
                    // Update order status to completed
                    let completedOrder = order.updateStatus(.completed)
                    switch completedOrder {
                    case .success(let updatedOrder):
                        guard let self = self else {
                            return Fail(error: PaymentError.processorUnavailable).eraseToAnyPublisher()
                        }
                        return self.orderRepository.updateOrder(updatedOrder)
                            .map { _ in processedPayment }
                            .mapError { _ in PaymentError.processorUnavailable }
                            .eraseToAnyPublisher()
                    case .failure(_):
                        // If order update fails, we should still return the successful payment
                        // but log this situation in a real implementation
                        return Just(processedPayment)
                            .setFailureType(to: PaymentError.self)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    private func simulatePaymentProcessing(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        // Simulate network delay and processing
        return Just(payment)
            .delay(for: .seconds(1.5), scheduler: DispatchQueue.global(qos: .userInitiated))
            .tryMap { payment -> Payment in
                // Simulate payment processor response
                let isSuccess = Bool.random() // In real implementation, this would be based on processor response

                if isSuccess {
                    // Generate transaction ID
                    let transactionID = "txn_\(UUID().uuidString.lowercased().prefix(8))"
                    _ = payment.lastFourDigits ?? "1234"

                    let statusResult = payment.withStatus(.completed)

                    switch statusResult {
                    case .success(let statusPayment):
                        let completedPayment = statusPayment.withTransactionID(transactionID)
                        return completedPayment
                    case .failure(let error):
                        throw error
                    }
                } else {
                    // Simulate various failure scenarios
                    let failureReasons = [
                        "Insufficient funds",
                        "Card declined",
                        "Expired card",
                        "Processor error"
                    ]

                    let failureReason = failureReasons.randomElement() ?? "Unknown error"
                    let statusResult = payment.withStatus(.failed)

                    switch statusResult {
                    case .success(let statusPayment):
                        let failedPayment = statusPayment.withFailureReason(failureReason)
                        return failedPayment
                    case .failure(let error):
                        throw error
                    }
                }
            }
            .mapError { error in
                if let paymentError = error as? PaymentError {
                    return paymentError
                } else {
                    return PaymentError.processorError(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Refund Processing

    public func refundPayment(_ payment: Payment, amount: Decimal) -> AnyPublisher<Payment, PaymentError> {
        // Validate payment can be refunded
        guard payment.status == .completed else {
            return Fail(error: PaymentError.paymentAlreadyCompleted)
                .eraseToAnyPublisher()
        }

        // Validate refund amount
        guard amount <= payment.amount && amount > 0 else {
            return Fail(error: PaymentError.refundExceededAmount)
                .eraseToAnyPublisher()
        }

        // Determine refund status
        let newStatus: PaymentStatus = amount == payment.amount ? .refunded : .partiallyRefunded

        // First update the payment status
        switch payment.withStatus(newStatus) {
        case .success(let updatedPayment):
            // Update payment in repository
            return paymentRepository.updatePayment(updatedPayment)
                .flatMap { [weak self] updatedPayment -> AnyPublisher<Payment, PaymentError> in
                    // Update order status if fully refunded
                    if newStatus == .refunded {
                        guard let self = self else {
                            return Just(updatedPayment)
                                .setFailureType(to: PaymentError.self)
                                .eraseToAnyPublisher()
                        }

                        // Get the order and try to cancel it
                        return self.orderRepository.getOrder(id: payment.orderID)
                            .mapError { _ in PaymentError.processorUnavailable }
                            .compactMap { $0 }
                            .map { order in
                                // Try to update order status
                                switch order.updateStatus(.cancelled) {
                                case .success(let cancelledOrder):
                                    return cancelledOrder
                                case .failure(_):
                                    // If order update fails, return original order (payment still succeeds)
                                    return order
                                }
                            }
                            .flatMap { cancelledOrder -> AnyPublisher<Payment, PaymentError> in
                                // Update the order in repository
                                return self.orderRepository.updateOrder(cancelledOrder)
                                    .map { _ in updatedPayment }
                                    .mapError { _ in PaymentError.processorUnavailable }
                                    .eraseToAnyPublisher()
                            }
                            .catch { _ -> AnyPublisher<Payment, PaymentError> in
                                // If order operations fail, still return the successful payment
                                return Just(updatedPayment)
                                    .setFailureType(to: PaymentError.self)
                                    .eraseToAnyPublisher()
                            }
                            .eraseToAnyPublisher()
                    } else {
                        // Partial refund, no order status change needed
                        return Just(updatedPayment)
                            .setFailureType(to: PaymentError.self)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    // MARK: - Void Payment

    public func voidPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        // Validate payment can be voided
        guard payment.status.canTransition(to: .voided) else {
            return Fail(error: PaymentError.invalidStatusTransition(from: payment.status, to: .voided))
                .eraseToAnyPublisher()
        }

        switch payment.withStatus(.voided) {
        case .success(let voidedPayment):
            // Update payment in repository first
            return paymentRepository.updatePayment(voidedPayment)
                .flatMap { [weak self] voidedPayment -> AnyPublisher<Payment, PaymentError> in
                    // Update order status back to pending if payment was voided
                    guard let self = self else {
                        return Just(voidedPayment)
                            .setFailureType(to: PaymentError.self)
                            .eraseToAnyPublisher()
                    }

                    // Get the order and try to set it back to pending
                    return self.orderRepository.getOrder(id: payment.orderID)
                        .mapError { _ in PaymentError.processorUnavailable }
                        .compactMap { $0 }
                        .map { order in
                            // Try to update order status
                            switch order.updateStatus(.pending) {
                            case .success(let pendingOrder):
                                return pendingOrder
                            case .failure(_):
                                // If order update fails, return original order (payment still succeeds)
                                return order
                            }
                        }
                        .flatMap { pendingOrder -> AnyPublisher<Payment, PaymentError> in
                            // Update the order in repository
                            return self.orderRepository.updateOrder(pendingOrder)
                                .map { _ in voidedPayment }
                                .mapError { _ in PaymentError.processorUnavailable }
                                .eraseToAnyPublisher()
                        }
                        .catch { _ -> AnyPublisher<Payment, PaymentError> in
                            // If order operations fail, still return the successful voided payment
                            return Just(voidedPayment)
                                .setFailureType(to: PaymentError.self)
                                .eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    // MARK: - Payment Methods

    public func getPaymentMethods(for processor: PaymentProcessor) -> AnyPublisher<[PaymentMethod], PaymentError> {
        // In a real implementation, this would fetch from the payment processor
        // For now, return sample payment methods
        let sampleMethods = createSamplePaymentMethods(for: processor)
        return Just(sampleMethods)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    private func createSamplePaymentMethods(for processor: PaymentProcessor) -> [PaymentMethod] {
        switch processor {
        case .stripe, .square:
            return [
                PaymentMethod(
                    type: .creditCard,
                    processor: processor,
                    lastFourDigits: "4242",
                    brand: "Visa",
                    expirationMonth: 12,
                    expirationYear: 25,
                    cardholderName: "John Doe",
                    isDefault: true
                ),
                PaymentMethod(
                    type: .creditCard,
                    processor: processor,
                    lastFourDigits: "5555",
                    brand: "Mastercard",
                    expirationMonth: 8,
                    expirationYear: 24,
                    cardholderName: "John Doe"
                )
            ]
        case .applePay:
            return [
                PaymentMethod(type: .mobilePay, processor: processor, isDefault: true)
            ]
        case .internal, .manual:
            return [
                PaymentMethod(type: .cash, processor: processor),
                PaymentMethod(type: .creditCard, processor: processor, lastFourDigits: "1234", brand: "Visa")
            ]
        default:
            return []
        }
    }

    // MARK: - Validation

    public func validatePayment(_ payment: Payment) -> AnyPublisher<Void, PaymentError> {
        let validationResult = payment.validate()
        switch validationResult {
        case .success:
            return Just(())
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    // MARK: - Fee Calculation

    public func calculateFees(for payment: Payment, processor: PaymentProcessor) -> AnyPublisher<Decimal, PaymentError> {
        let feeRate: Decimal
        let fixedFee: Decimal

        switch processor {
        case .stripe:
            feeRate = 0.029 // 2.9%
            fixedFee = 0.30 // $0.30
        case .square:
            feeRate = 0.026 // 2.6%
            fixedFee = 0.10 // $0.10
        case .paypal:
            feeRate = 0.029 // 2.9%
            fixedFee = 0.30 // $0.30
        case .applePay:
            feeRate = 0.015 // 1.5%
            fixedFee = 0.00 // No fixed fee
        default:
            feeRate = 0.00 // No fees for internal/manual processing
            fixedFee = 0.00
        }

        let totalFee = (payment.amount * feeRate) + fixedFee
        return Just(totalFee)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Helper Methods

    public func generateTransactionID() -> String {
        return "txn_\(UUID().uuidString.lowercased())"
    }

    public func isPaymentComplete(for orderID: UUID) -> AnyPublisher<Bool, PaymentError> {
        return paymentRepository.getPayments(for: orderID)
            .map { payments in
                payments.contains { $0.status == .completed }
            }
            .eraseToAnyPublisher()
    }

    public func getTotalPaid(for orderID: UUID) -> AnyPublisher<Decimal, PaymentError> {
        return paymentRepository.getPayments(for: orderID)
            .map { payments in
                payments
                    .filter { $0.status == .completed }
                    .reduce(0) { $0 + $1.amount }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Payment Processing Result

public struct PaymentProcessingResult {
    public let payment: Payment
    public let order: Order?
    public let success: Bool
    public let error: PaymentError?

    public init(payment: Payment, order: Order? = nil, success: Bool, error: PaymentError? = nil) {
        self.payment = payment
        self.order = order
        self.success = success
        self.error = error
    }
}
