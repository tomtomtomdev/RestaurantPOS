//
//  PaymentTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
@testable import RestaurantPOS

final class PaymentTests: XCTestCase {

    // MARK: - Payment Model Tests

    func testPaymentInitialization() {
        // Given
        let orderID = UUID()
        let amount: Decimal = 25.50
        let paymentType = PaymentType.creditCard
        let status = PaymentStatus.pending

        // When
        let payment = Payment(
            orderID: orderID,
            amount: amount,
            paymentType: paymentType,
            status: status
        )

        // Then
        XCTAssertEqual(payment.orderID, orderID)
        XCTAssertEqual(payment.amount, amount)
        XCTAssertEqual(payment.paymentType, paymentType)
        XCTAssertEqual(payment.status, status)
        XCTAssertNotNil(payment.id)
        XCTAssertNotNil(payment.createdAt)
    }

    func testPaymentStatusTransitions() {
        // Given
        let payment = Payment(orderID: UUID(), amount: 10.0, paymentType: .creditCard, status: .pending)

        // When/Then - Valid transitions
        var result = payment.withStatus(.processing)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try? result.get().status, .processing)

        result = payment.withStatus(.failed)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try? result.get().status, .failed)

        result = payment.withStatus(.voided)
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(try? result.get().status, .voided)

        // When/Then - Invalid transitions
        result = payment.withStatus(.completed)
        XCTAssertFalse(result.isSuccess)
        XCTAssertEqual(result.error as? PaymentError, .invalidStatusTransition(from: .pending, to: .completed))
    }

    func testPaymentValidation() {
        // Given
        let validPayment = Payment(
            orderID: UUID(),
            amount: 10.0,
            paymentType: .creditCard,
            lastFourDigits: "4242"
        )

        let invalidAmountPayment = Payment(
            orderID: UUID(),
            amount: 0,
            paymentType: .creditCard
        )

        let invalidCardPayment = Payment(
            orderID: UUID(),
            amount: 10.0,
            paymentType: .creditCard,
            lastFourDigits: "123"
        )

        let cashPayment = Payment(
            orderID: UUID(),
            amount: 10.0,
            paymentType: .cash
        )

        // When/Then
        XCTAssertTrue(validPayment.validate().isSuccess)
        XCTAssertFalse(invalidAmountPayment.validate().isSuccess)
        XCTAssertEqual(invalidAmountPayment.validate().error as? PaymentError, .invalidAmount)
        XCTAssertFalse(invalidCardPayment.validate().isSuccess)
        XCTAssertEqual(invalidCardPayment.validate().error as? PaymentError, .invalidCardDetails)
        XCTAssertTrue(cashPayment.validate().isSuccess)
    }

    func testPaymentStatusDisplayProperties() {
        // Test all payment statuses have display properties
        let statuses: [PaymentStatus] = [.pending, .processing, .completed, .failed, .refunded, .partiallyRefunded, .voided]

        for status in statuses {
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.systemImageName.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
            XCTAssertFalse(status.canTransitionTo.isEmpty)
        }
    }

    func testPaymentTypeProperties() {
        // Test credit card requires card details
        XCTAssertTrue(PaymentType.creditCard.requiresCardDetails)
        XCTAssertTrue(PaymentType.debitCard.requiresCardDetails)

        // Test cash doesn't require card details
        XCTAssertFalse(PaymentType.cash.requiresCardDetails)
        XCTAssertFalse(PaymentType.mobilePay.requiresCardDetails)

        // Test display properties
        for paymentType in PaymentType.allCases {
            XCTAssertFalse(paymentType.displayName.isEmpty)
            XCTAssertFalse(paymentType.systemImageName.isEmpty)
        }
    }

    func testPaymentProcessorProperties() {
        // Test processor display properties
        for processor in PaymentProcessor.allCases {
            XCTAssertFalse(processor.displayName.isEmpty)
            XCTAssertFalse(processor.supportedPaymentTypes.isEmpty)
        }
    }

    func testPaymentMethodProperties() {
        // Given
        let cardMethod = PaymentMethod(
            type: .creditCard,
            lastFourDigits: "4242",
            brand: "Visa",
            expirationMonth: 12,
            expirationYear: 25
        )

        // When/Then
        XCTAssertEqual(cardMethod.maskedNumber, "**** **** **** 4242")
        XCTAssertEqual(cardMethod.displayText, "Visa ending in 4242")
        XCTAssertFalse(cardMethod.isExpired)

        // Given - Expired card
        let expiredCard = PaymentMethod(
            type: .creditCard,
            lastFourDigits: "1234",
            expirationMonth: 1,
            expirationYear: 20
        )

        // When/Then
        XCTAssertTrue(expiredCard.isExpired)
    }

    func testPaymentAmountFormatting() {
        let amounts: [Decimal] = [0, 10, 10.50, 99.99, 1000]

        for amount in amounts {
            let payment = Payment(orderID: UUID(), amount: amount, paymentType: .cash)
            let formatted = payment.formattedAmount
            XCTAssertTrue(formatted.hasPrefix("$"))
            XCTAssertTrue(formatted.contains("."))
        }
    }

    // MARK: - Payment Error Tests

    func testPaymentErrorDescriptions() {
        let errors: [PaymentError] = [
            .invalidAmount,
            .invalidPaymentType,
            .invalidCardDetails,
            .processorError("Test error"),
            .networkError,
            .invalidStatusTransition(from: .pending, to: .completed),
            .paymentNotFound,
            .duplicatePayment,
            .insufficientFunds,
            .cardExpired,
            .cardDeclined
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testPaymentErrorEquality() {
        XCTAssertEqual(PaymentError.invalidAmount, PaymentError.invalidAmount)
        XCTAssertEqual(PaymentError.processorError("Test"), PaymentError.processorError("Test"))
        XCTAssertNotEqual(PaymentError.invalidAmount, PaymentError.invalidPaymentType)
    }
}

// MARK: - PaymentMethod Tests

final class PaymentMethodTests: XCTestCase {

    func testPaymentMethodInitialization() {
        // Given
        let id = UUID()
        let type = PaymentType.creditCard
        let lastFour = "4242"
        let brand = "Visa"
        let expMonth = 12
        let expYear = 2025

        // When
        let method = PaymentMethod(
            id: id,
            type: type,
            lastFourDigits: lastFour,
            brand: brand,
            expirationMonth: expMonth,
            expirationYear: expYear
        )

        // Then
        XCTAssertEqual(method.id, id)
        XCTAssertEqual(method.type, type)
        XCTAssertEqual(method.lastFourDigits, lastFour)
        XCTAssertEqual(method.brand, brand)
        XCTAssertEqual(method.expirationMonth, expMonth)
        XCTAssertEqual(method.expirationYear, expYear)
    }

    func testPaymentMethodDisplayText() {
        // Test credit card with brand
        let creditCard = PaymentMethod(
            type: .creditCard,
            lastFourDigits: "4242",
            brand: "Visa"
        )
        XCTAssertEqual(creditCard.displayText, "Visa ending in 4242")

        // Test credit card without brand
        let noBrandCard = PaymentMethod(
            type: .creditCard,
            lastFourDigits: "1234"
        )
        XCTAssertEqual(noBrandCard.displayText, "Card ending in 1234")

        // Test cash payment
        let cash = PaymentMethod(type: .cash)
        XCTAssertEqual(cash.displayText, "Cash")
    }

    func testPaymentMethodExpiration() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())

        // Test current card (not expired)
        let currentCard = PaymentMethod(
            type: .creditCard,
            expirationMonth: currentMonth,
            expirationYear: currentYear
        )
        XCTAssertFalse(currentCard.isExpired)

        // Test expired card
        let expiredCard = PaymentMethod(
            type: .creditCard,
            expirationMonth: currentMonth,
            expirationYear: currentYear - 1
        )
        XCTAssertTrue(expiredCard.isExpired)

        // Test future card
        let futureCard = PaymentMethod(
            type: .creditCard,
            expirationMonth: currentMonth,
            expirationYear: currentYear + 1
        )
        XCTAssertFalse(futureCard.isExpired)
    }
}

// MARK: - PaymentStatus Tests

final class PaymentStatusTests: XCTestCase {

    func testPaymentStatusTransitions() {
        // Test pending can transition to valid states
        let pending = PaymentStatus.pending
        let validTransitions = pending.canTransitionTo
        XCTAssertTrue(validTransitions.contains(.processing))
        XCTAssertTrue(validTransitions.contains(.failed))
        XCTAssertTrue(validTransitions.contains(.voided))
        XCTAssertFalse(validTransitions.contains(.completed))
        XCTAssertFalse(validTransitions.contains(.refunded))

        // Test completed can only be refunded or voided
        let completed = PaymentStatus.completed
        let completedTransitions = completed.canTransitionTo
        XCTAssertTrue(completedTransitions.contains(.refunded))
        XCTAssertTrue(completedTransitions.contains(.partiallyRefunded))
        XCTAssertTrue(completedTransitions.contains(.voided))
        XCTAssertFalse(completedTransitions.contains(.processing))
        XCTAssertFalse(completedTransitions.contains(.failed))

        // Test refund can only transition to full refund
        let partiallyRefunded = PaymentStatus.partiallyRefunded
        let refundTransitions = partiallyRefunded.canTransitionTo
        XCTAssertTrue(refundTransitions.contains(.refunded))
        XCTAssertFalse(refundTransitions.contains(.processing))
        XCTAssertFalse(refundTransitions.contains(.completed))
    }

    func testPaymentStatusCanTransitionMethod() {
        let pending = PaymentStatus.pending

        XCTAssertTrue(pending.canTransition(to: .processing))
        XCTAssertTrue(pending.canTransition(to: .failed))
        XCTAssertFalse(pending.canTransition(to: .completed))
        XCTAssertFalse(pending.canTransition(to: .refunded))

        let completed = PaymentStatus.completed
        XCTAssertTrue(completed.canTransition(to: .refunded))
        XCTAssertFalse(completed.canTransition(to: .processing))
        XCTAssertFalse(completed.canTransition(to: .pending))
    }

    func testPaymentStatusDisplayProperties() {
        for status in PaymentStatus.allCases {
            XCTAssertFalse(status.displayName.isEmpty)
            XCTAssertFalse(status.systemImageName.isEmpty)
            XCTAssertFalse(status.color.isEmpty)
        }
    }
}

// MARK: - PaymentType Tests

final class PaymentTypeTests: XCTestCase {

    func testPaymentTypeRequiresCardDetails() {
        XCTAssertTrue(PaymentType.creditCard.requiresCardDetails)
        XCTAssertTrue(PaymentType.debitCard.requiresCardDetails)
        XCTAssertFalse(PaymentType.cash.requiresCardDetails)
        XCTAssertFalse(PaymentType.mobilePay.requiresCardDetails)
        XCTAssertFalse(PaymentType.giftCard.requiresCardDetails)
        XCTAssertFalse(PaymentType.check.requiresCardDetails)
        XCTAssertFalse(PaymentType.other.requiresCardDetails)
    }

    func testPaymentTypeDisplayProperties() {
        for type in PaymentType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.systemImageName.isEmpty)
        }
    }
}

// MARK: - PaymentProcessor Tests

final class PaymentProcessorTests: XCTestCase {

    func testPaymentProcessorSupportsPaymentTypes() {
        for processor in PaymentProcessor.allCases {
            XCTAssertFalse(processor.supportedPaymentTypes.isEmpty)
        }
    }

    func testStripeSupportsCreditAndDebit() {
        let stripe = PaymentProcessor.stripe
        XCTAssertTrue(stripe.supportedPaymentTypes.contains(.creditCard))
        XCTAssertTrue(stripe.supportedPaymentTypes.contains(.debitCard))
        XCTAssertTrue(stripe.supportedPaymentTypes.contains(.mobilePay))
        XCTAssertFalse(stripe.supportedPaymentTypes.contains(.cash))
    }

    func testApplePaySupportsMobilePayOnly() {
        let applePay = PaymentProcessor.applePay
        XCTAssertTrue(applePay.supportedPaymentTypes.contains(.mobilePay))
        XCTAssertFalse(applePay.supportedPaymentTypes.contains(.creditCard))
        XCTAssertFalse(applePay.supportedPaymentTypes.contains(.cash))
    }

    func testInternalSupportsAllTypes() {
        let internalProcessor = PaymentProcessor.internal
        XCTAssertEqual(Set(internalProcessor.supportedPaymentTypes), Set(PaymentType.allCases))
    }
}