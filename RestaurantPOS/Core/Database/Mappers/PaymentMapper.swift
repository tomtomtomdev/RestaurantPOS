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

    public func map(_ payment: Payment, to paymentEntity: PaymentEntity) {
        paymentEntity.id = payment.id
        paymentEntity.orderID = payment.orderID
        paymentEntity.amount = NSDecimalNumber(decimal: payment.amount)
        paymentEntity.paymentType = payment.paymentType.rawValue
        paymentEntity.status = payment.status.rawValue
        paymentEntity.transactionID = payment.transactionID
        paymentEntity.lastFourDigits = payment.lastFourDigits
        paymentEntity.processor = payment.processor?.rawValue
        paymentEntity.createdAt = payment.createdAt
        paymentEntity.processedAt = payment.processedAt
        paymentEntity.failedAt = payment.failedAt
        paymentEntity.failureReason = payment.failureReason

        // Convert metadata dictionary to Data for Core Data storage
        if !payment.metadata.isEmpty {
            do {
                let data = try JSONSerialization.data(withJSONObject: payment.metadata)
                paymentEntity.metadata = data
            } catch {
                // Log error in production, for now we'll skip metadata
                print("Failed to serialize payment metadata: \(error)")
            }
        }
    }

    // MARK: - Entity to Domain Mapping

    public func map(from paymentEntity: PaymentEntity) -> Payment {
        var metadata: [String: Any] = [:]

        // Convert Data back to metadata dictionary
        if let data = paymentEntity.metadata {
            do {
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    metadata = dict
                }
            } catch {
                print("Failed to deserialize payment metadata: \(error)")
            }
        }

        return Payment(
            id: paymentEntity.id ?? UUID(),
            orderID: paymentEntity.orderID ?? UUID(),
            amount: paymentEntity.amount?.decimalValue ?? 0,
            paymentType: PaymentType(rawValue: paymentEntity.paymentType ?? "") ?? .creditCard,
            status: PaymentStatus(rawValue: paymentEntity.status ?? "") ?? .pending,
            transactionID: paymentEntity.transactionID,
            lastFourDigits: paymentEntity.lastFourDigits,
            processor: paymentEntity.processor != nil ? PaymentProcessor(rawValue: paymentEntity.processor!) : nil,
            createdAt: paymentEntity.createdAt ?? Date(),
            processedAt: paymentEntity.processedAt,
            failedAt: paymentEntity.failedAt,
            failureReason: paymentEntity.failureReason,
            metadata: metadata
        )
    }
}