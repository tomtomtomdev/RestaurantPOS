//
//  PaymentMapper.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation
import CoreData

// MARK: - Payment Mapper

public struct PaymentMapper {

    // MARK: - Domain to Entity Mapping

    public func map(_ payment: Payment, to paymentEntity: PaymentEntity, in context: NSManagedObjectContext) {
        paymentEntity.id = payment.id
        paymentEntity.amount = NSDecimalNumber(decimal: payment.amount)
        paymentEntity.paymentType = payment.paymentType.rawValue
        paymentEntity.status = payment.status.rawValue
        paymentEntity.timestamp = payment.createdAt

        // Set the order relationship if available
        if let orderEntity = try? context.fetch(OrderEntity.fetchRequest()).first(where: { $0.id == payment.orderID }) {
            paymentEntity.order = orderEntity
        }
    }

    public func map(_ payment: Payment, to paymentEntity: PaymentEntity) {
        paymentEntity.id = payment.id
        paymentEntity.amount = NSDecimalNumber(decimal: payment.amount)
        paymentEntity.paymentType = payment.paymentType.rawValue
        paymentEntity.status = payment.status.rawValue
        paymentEntity.timestamp = payment.createdAt
    }

    // MARK: - Entity to Domain Mapping

    public func map(from paymentEntity: PaymentEntity) -> Payment {
        return Payment(
            id: paymentEntity.id ?? UUID(),
            orderID: paymentEntity.order?.id ?? UUID(),
            amount: paymentEntity.amount?.decimalValue ?? 0,
            paymentType: PaymentType(rawValue: paymentEntity.paymentType ?? "") ?? .creditCard,
            status: PaymentStatus(rawValue: paymentEntity.status ?? "") ?? .pending,
            transactionID: nil,
            lastFourDigits: nil,
            processor: nil,
            createdAt: paymentEntity.timestamp ?? Date(),
            processedAt: nil,
            failedAt: nil,
            failureReason: nil,
            metadata: [:]
        )
    }
}