//
//  Payment.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation

// MARK: - Payment Model

public struct Payment: Identifiable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let orderID: UUID
    public let amount: Decimal
    public let paymentType: PaymentType
    public let status: PaymentStatus
    public let transactionID: String?
    public let lastFourDigits: String?
    public let processor: PaymentProcessor?
    public let createdAt: Date
    public var processedAt: Date?
    public var failedAt: Date?
    public var failureReason: String?
    public var metadata: [String: Any]

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        orderID: UUID,
        amount: Decimal,
        paymentType: PaymentType,
        status: PaymentStatus = .pending,
        transactionID: String? = nil,
        lastFourDigits: String? = nil,
        processor: PaymentProcessor? = nil,
        createdAt: Date = Date(),
        processedAt: Date? = nil,
        failedAt: Date? = nil,
        failureReason: String? = nil,
        metadata: [String: Any] = [:]
    ) {
        self.id = id
        self.orderID = orderID
        self.amount = amount
        self.paymentType = paymentType
        self.status = status
        self.transactionID = transactionID
        self.lastFourDigits = lastFourDigits
        self.processor = processor
        self.createdAt = createdAt
        self.processedAt = processedAt
        self.failedAt = failedAt
        self.failureReason = failureReason
        self.metadata = metadata
    }
}

// MARK: - Payment Status

public enum PaymentStatus: String, CaseIterable, Equatable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    case partiallyRefunded = "partially_refunded"
    case voided = "voided"

    // MARK: - Display Properties

    public var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .refunded:
            return "Refunded"
        case .partiallyRefunded:
            return "Partially Refunded"
        case .voided:
            return "Voided"
        }
    }

    public var systemImageName: String {
        switch self {
        case .pending:
            return "clock"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .refunded:
            return "arrow.counterclockwise"
        case .partiallyRefunded:
            return "arrow.left.arrow.right"
        case .voided:
            return "minus.circle.fill"
        }
    }

    public var color: String {
        switch self {
        case .pending:
            return "systemOrange"
        case .processing:
            return "systemBlue"
        case .completed:
            return "systemGreen"
        case .failed:
            return "systemRed"
        case .refunded:
            return "systemPurple"
        case .partiallyRefunded:
            return "systemYellow"
        case .voided:
            return "systemGray"
        }
    }

    // MARK: - State Transitions

    public var canTransitionTo: [PaymentStatus] {
        switch self {
        case .pending:
            return [.processing, .failed, .voided]
        case .processing:
            return [.completed, .failed]
        case .completed:
            return [.refunded, .partiallyRefunded, .voided]
        case .failed:
            return [.pending, .voided]
        case .refunded:
            return []
        case .partiallyRefunded:
            return [.refunded]
        case .voided:
            return []
        }
    }

    public func canTransition(to newStatus: PaymentStatus) -> Bool {
        return canTransitionTo.contains(newStatus)
    }
}

// MARK: - Payment Type

public enum PaymentType: String, CaseIterable, Equatable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case cash = "cash"
    case mobilePay = "mobile_pay"
    case giftCard = "gift_card"
    case check = "check"
    case other = "other"

    // MARK: - Display Properties

    public var displayName: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .debitCard:
            return "Debit Card"
        case .cash:
            return "Cash"
        case .mobilePay:
            return "Mobile Pay"
        case .giftCard:
            return "Gift Card"
        case .check:
            return "Check"
        case .other:
            return "Other"
        }
    }

    public var systemImageName: String {
        switch self {
        case .creditCard:
            return "creditcard"
        case .debitCard:
            return "creditcard"
        case .cash:
            return "banknote"
        case .mobilePay:
            return "iphone"
        case .giftCard:
            return "giftcard"
        case .check:
            return "list.bullet.rectangle"
        case .other:
            return "questionmark.circle"
        }
    }

    public var requiresCardDetails: Bool {
        switch self {
        case .creditCard, .debitCard:
            return true
        case .cash, .mobilePay, .giftCard, .check, .other:
            return false
        }
    }
}

// MARK: - Payment Processor

public enum PaymentProcessor: String, CaseIterable, Equatable {
    case stripe = "stripe"
    case square = "square"
    case paypal = "paypal"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case internal = "internal"
    case manual = "manual"

    public var displayName: String {
        switch self {
        case .stripe:
            return "Stripe"
        case .square:
            return "Square"
        case .paypal:
            return "PayPal"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .internal:
            return "Internal"
        case .manual:
            return "Manual"
        }
    }

    public var supportedPaymentTypes: [PaymentType] {
        switch self {
        case .stripe, .square:
            return [.creditCard, .debitCard, .mobilePay]
        case .paypal:
            return [.creditCard, .debitCard]
        case .applePay:
            return [.mobilePay]
        case .googlePay:
            return [.mobilePay]
        case .internal, .manual:
            return PaymentType.allCases
        }
    }
}

// MARK: - Payment Methods

public struct PaymentMethod: Identifiable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let type: PaymentType
    public let processor: PaymentProcessor?
    public let lastFourDigits: String?
    public let brand: String?
    public let expirationMonth: Int?
    public let expirationYear: Int?
    public let cardholderName: String?
    public let isDefault: Bool
    public let isActive: Bool
    public let createdAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        type: PaymentType,
        processor: PaymentProcessor? = nil,
        lastFourDigits: String? = nil,
        brand: String? = nil,
        expirationMonth: Int? = nil,
        expirationYear: Int? = nil,
        cardholderName: String? = nil,
        isDefault: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.processor = processor
        self.lastFourDigits = lastFourDigits
        self.brand = brand
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.cardholderName = cardholderName
        self.isDefault = isDefault
        self.isActive = isActive
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    public var maskedNumber: String? {
        guard let lastFourDigits = lastFourDigits else { return nil }
        return "**** **** **** \(lastFourDigits)"
    }

    public var displayText: String {
        switch type {
        case .creditCard, .debitCard:
            if let brand = brand, let lastFour = lastFourDigits {
                return "\(brand) ending in \(lastFour)"
            } else if let lastFour = lastFourDigits {
                return "Card ending in \(lastFour)"
            } else {
                return type.displayName
            }
        case .cash, .mobilePay, .giftCard, .check, .other:
            return type.displayName
        }
    }

    public var isExpired: Bool {
        guard let month = expirationMonth,
              let year = expirationYear else { return false }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        return year < currentYear || (year == currentYear && month < currentMonth)
    }
}

// MARK: - Payment Extensions

extension Payment {

    // MARK: - Status Management

    public func withStatus(_ newStatus: PaymentStatus) -> Result<Payment, PaymentError> {
        guard status.canTransition(to: newStatus) else {
            return .failure(.invalidStatusTransition(from: status, to: newStatus))
        }

        var updatedPayment = self
        updatedPayment.status = newStatus

        switch newStatus {
        case .completed:
            updatedPayment.processedAt = Date()
            updatedPayment.failedAt = nil
            updatedPayment.failureReason = nil
        case .failed:
            updatedPayment.failedAt = Date()
            updatedPayment.processedAt = nil
        case .refunded, .partiallyRefunded, .voided:
            updatedPayment.processedAt = Date()
        default:
            break
        }

        return .success(updatedPayment)
    }

    public func withFailureReason(_ reason: String) -> Payment {
        var updatedPayment = self
        updatedPayment.failureReason = reason
        return updatedPayment
    }

    public func withTransactionID(_ transactionID: String) -> Payment {
        var updatedPayment = self
        updatedPayment.transactionID = transactionID
        return updatedPayment
    }

    // MARK: - Validation

    public func validate() -> Result<Void, PaymentError> {
        guard amount > 0 else {
            return .failure(.invalidAmount)
        }

        if paymentType.requiresCardDetails {
            guard let lastFour = lastFourDigits, lastFour.count == 4 else {
                return .failure(.invalidCardDetails)
            }
        }

        return .success(())
    }

    // MARK: - Display Properties

    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    public var statusDisplayText: String {
        switch status {
        case .pending:
            return "Payment pending"
        case .processing:
            return "Processing payment"
        case .completed:
            return "Payment completed"
        case .failed:
            if let reason = failureReason {
                return "Payment failed: \(reason)"
            } else {
                return "Payment failed"
            }
        case .refunded:
            return "Payment refunded"
        case .partiallyRefunded:
            return "Payment partially refunded"
        case .voided:
            return "Payment voided"
        }
    }
}

// MARK: - Payment Error

public enum PaymentError: Error, Equatable, LocalizedError {
    case invalidAmount
    case invalidPaymentType
    case invalidCardDetails
    case processorError(String)
    case networkError
    case invalidStatusTransition(from: PaymentStatus, to: PaymentStatus)
    case paymentNotFound
    case duplicatePayment
    case insufficientFunds
    case cardExpired
    case cardDeclined
    case processorUnavailable
    case invalidOrder
    case refundExceededAmount
    case paymentAlreadyCompleted
    case paymentAlreadyRefunded

    public var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidPaymentType:
            return "Invalid payment type"
        case .invalidCardDetails:
            return "Invalid card details"
        case .processorError(let message):
            return "Payment processor error: \(message)"
        case .networkError:
            return "Network error occurred"
        case .invalidStatusTransition(let from, let to):
            return "Cannot transition payment from \(from.displayName) to \(to.displayName)"
        case .paymentNotFound:
            return "Payment not found"
        case .duplicatePayment:
            return "Duplicate payment detected"
        case .insufficientFunds:
            return "Insufficient funds"
        case .cardExpired:
            return "Card has expired"
        case .cardDeclined:
            return "Card was declined"
        case .processorUnavailable:
            return "Payment processor is unavailable"
        case .invalidOrder:
            return "Invalid order"
        case .refundExceededAmount:
            return "Refund amount exceeds payment amount"
        case .paymentAlreadyCompleted:
            return "Payment has already been completed"
        case .paymentAlreadyRefunded:
            return "Payment has already been refunded"
        }
    }
}