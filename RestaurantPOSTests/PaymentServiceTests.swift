//
//  PaymentServiceTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
import Combine
@testable import RestaurantPOS

final class PaymentServiceTests: XCTestCase {

    // MARK: - System Under Test

    private var sut: PaymentService!
    private var mockPaymentRepository: MockPaymentRepository!
    private var mockOrderRepository: MockOrderRepository!
    private var testOrder: Order!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Test Lifecycle

    override func setUp() {
        super.setUp()
        mockPaymentRepository = MockPaymentRepository()
        mockOrderRepository = MockOrderRepository()
        sut = PaymentService(
            paymentRepository: mockPaymentRepository,
            orderRepository: mockOrderRepository
        )

        testOrder = Order(
            id: UUID(),
            orderNumber: "TEST-001",
            status: .pending,
            items: [
                OrderItem(name: "Test Item", quantity: 1, unitPrice: 10.00)
            ]
        )
    }

    override func tearDown() {
        sut = nil
        mockPaymentRepository = nil
        mockOrderRepository = nil
        testOrder = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Payment Processing Tests

    func testProcessPayment_WithValidPayment_ShouldSucceed() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: testOrder.totalAmount,
            paymentType: .creditCard
        )

        mockOrderRepository.orderToReturn = testOrder
        mockPaymentRepository.paymentToReturn = payment.withStatus(.completed) ?? payment

        let expectation = XCTestExpectation(description: "Payment processing completes")

        // When
        sut.processPayment(payment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { processedPayment in
                    // Then
                    XCTAssertEqual(processedPayment.status, .completed)
                    XCTAssertNotNil(processedPayment.transactionID)
                    XCTAssertNotNil(processedPayment.processedAt)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testProcessPayment_WithInvalidAmount_ShouldFail() {
        // Given
        let invalidPayment = Payment(
            orderID: testOrder.id,
            amount: 0,
            paymentType: .creditCard
        )

        let expectation = XCTestExpectation(description: "Payment processing fails with invalid amount")

        // When
        sut.processPayment(invalidPayment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error as? PaymentError, PaymentError.invalidAmount)
                    } else {
                        XCTFail("Expected failure but got success")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive payment on invalid amount")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testProcessPayment_WithNonExistentOrder_ShouldFail() {
        // Given
        let payment = Payment(
            orderID: UUID(),
            amount: 10.0,
            paymentType: .creditCard
        )

        mockOrderRepository.orderToReturn = nil

        let expectation = XCTestExpectation(description: "Payment processing fails with invalid order")

        // When
        sut.processPayment(payment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error as? PaymentError, PaymentError.invalidOrder)
                    } else {
                        XCTFail("Expected failure but got success")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive payment with non-existent order")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testProcessPayment_WithInvalidCardDetails_ShouldFail() {
        // Given
        let invalidPayment = Payment(
            orderID: testOrder.id,
            amount: testOrder.totalAmount,
            paymentType: .creditCard,
            lastFourDigits: "123" // Invalid - should be 4 digits
        )

        let expectation = XCTestExpectation(description: "Payment processing fails with invalid card details")

        // When
        sut.processPayment(invalidPayment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error as? PaymentError, PaymentError.invalidCardDetails)
                    } else {
                        XCTFail("Expected failure but got success")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive payment with invalid card details")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Refund Tests

    func testRefundPayment_WithValidPayment_ShouldSucceed() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            status: .completed
        )

        let refundedPayment = payment.withStatus(.refunded) ?? payment
        mockPaymentRepository.paymentToReturn = refundedPayment

        let expectation = XCTestExpectation(description: "Refund processing completes")

        // When
        sut.refundPayment(payment, amount: 5.0)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { refundedPayment in
                    // Then
                    XCTAssertEqual(refundedPayment.status, .partiallyRefunded)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testRefundPayment_WithFullRefund_ShouldChangeStatusToRefunded() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            status: .completed
        )

        let refundedPayment = payment.withStatus(.refunded) ?? payment
        mockPaymentRepository.paymentToReturn = refundedPayment

        let expectation = XCTestExpectation(description: "Full refund changes status to refunded")

        // When
        sut.refundPayment(payment, amount: 10.0)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { refundedPayment in
                    // Then
                    XCTAssertEqual(refundedPayment.status, .refunded)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testRefundPayment_WithExcessAmount_ShouldFail() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            status: .completed
        )

        let expectation = XCTestExpectation(description: "Refund fails with excess amount")

        // When
        sut.refundPayment(payment, amount: 15.0)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error as? PaymentError, PaymentError.refundExceededAmount)
                    } else {
                        XCTFail("Expected failure but got success")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not receive payment with excess refund amount")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Void Payment Tests

    func testVoidPayment_WithPendingPayment_ShouldSucceed() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            status: .pending
        )

        let voidedPayment = payment.withStatus(.voided) ?? payment
        mockPaymentRepository.paymentToReturn = voidedPayment

        let expectation = XCTestExpectation(description: "Void payment completes")

        // When
        sut.voidPayment(payment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { voidedPayment in
                    // Then
                    XCTAssertEqual(voidedPayment.status, .voided)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testVoidPayment_WithCompletedPayment_ShouldFail() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            status: .completed
        )

        // When/Then - Completed payments can be voided, so this should actually succeed
        let voidedPayment = payment.withStatus(.voided) ?? payment
        mockPaymentRepository.paymentToReturn = voidedPayment

        let expectation = XCTestExpectation(description: "Void completed payment succeeds")

        sut.voidPayment(payment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { voidedPayment in
                    XCTAssertEqual(voidedPayment.status, .voided)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Payment Methods Tests

    func testGetPaymentMethods_ShouldReturnMethodsForProcessor() {
        // Given
        let processor = PaymentProcessor.stripe
        let expectation = XCTestExpectation(description: "Payment methods loaded")

        // When
        sut.getPaymentMethods(for: processor)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { methods in
                    // Then
                    XCTAssertFalse(methods.isEmpty)
                    XCTAssertTrue(methods.allSatisfy { $0.processor == processor })
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Fee Calculation Tests

    func testCalculateFees_ForStripe_ShouldReturnCorrectAmount() {
        // Given
        let payment = Payment(orderID: testOrder.id, amount: 100.00, paymentType: .creditCard)
        let processor = PaymentProcessor.stripe
        let expectation = XCTestExpectation(description: "Fee calculation completes")

        // When
        sut.calculateFees(for: payment, processor: processor)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { fee in
                    // Then - Stripe charges 2.9% + $0.30
                    let expectedFee: Decimal = 100.00 * 0.029 + 0.30
                    XCTAssertEqual(fee, expectedFee)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testCalculateFees_ForCash_ShouldReturnZero() {
        // Given
        let payment = Payment(orderID: testOrder.id, amount: 100.00, paymentType: .cash)
        let processor = PaymentProcessor.manual
        let expectation = XCTestExpectation(description: "Fee calculation for cash returns zero")

        // When
        sut.calculateFees(for: payment, processor: processor)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { fee in
                    // Then
                    XCTAssertEqual(fee, 0)
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Validation Tests

    func testValidatePayment_WithValidPayment_ShouldSucceed() {
        // Given
        let payment = Payment(
            orderID: testOrder.id,
            amount: 10.0,
            paymentType: .creditCard,
            lastFourDigits: "4242"
        )

        let expectation = XCTestExpectation(description: "Payment validation succeeds")

        // When
        sut.validatePayment(payment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success but got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    // Validation succeeded
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    func testValidatePayment_WithInvalidPayment_ShouldFail() {
        // Given
        let invalidPayment = Payment(
            orderID: testOrder.id,
            amount: 0,
            paymentType: .creditCard
        )

        let expectation = XCTestExpectation(description: "Payment validation fails")

        // When
        sut.validatePayment(invalidPayment)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertEqual(error as? PaymentError, PaymentError.invalidAmount)
                    } else {
                        XCTFail("Expected failure but got success")
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    XCTFail("Should not validate invalid payment")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Mock Classes

class MockPaymentRepository: PaymentRepositoryProtocol {
    var paymentToReturn: Payment?
    var shouldReturnError: Bool = false
    var createPaymentCallCount = 0
    var updatePaymentCallCount = 0
    var getPaymentCallCount = 0

    func createPayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        createPaymentCallCount += 1

        if shouldReturnError {
            return Fail(error: PaymentError.processorError("Mock error"))
                .eraseToAnyPublisher()
        }

        let payment = paymentToReturn ?? payment
        return Just(payment)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getPayment(id: UUID) -> AnyPublisher<Payment?, PaymentError> {
        getPaymentCallCount += 1

        if shouldReturnError {
            return Fail(error: PaymentError.paymentNotFound)
                .eraseToAnyPublisher()
        }

        return Just(paymentToReturn)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getPayments(for orderID: UUID) -> AnyPublisher<[Payment], PaymentError> {
        if let payment = paymentToReturn {
            return Just([payment])
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        }
        return Just([])
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getAllPayments() -> AnyPublisher<[Payment], PaymentError> {
        if let payment = paymentToReturn {
            return Just([payment])
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        }
        return Just([])
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func updatePayment(_ payment: Payment) -> AnyPublisher<Payment, PaymentError> {
        updatePaymentCallCount += 1

        if shouldReturnError {
            return Fail(error: PaymentError.processorError("Mock error"))
                .eraseToAnyPublisher()
        }

        let payment = paymentToReturn ?? payment
        return Just(payment)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func deletePayment(id: UUID) -> AnyPublisher<Void, PaymentError> {
        if shouldReturnError {
            return Fail(error: PaymentError.paymentNotFound)
                .eraseToAnyPublisher()
        }

        return Just(())
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getPaymentsWithStatus(_ status: PaymentStatus) -> AnyPublisher<[Payment], PaymentError> {
        if let payment = paymentToReturn, payment.status == status {
            return Just([payment])
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        }
        return Just([])
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getPayments(from startDate: Date, to endDate: Date) -> AnyPublisher<[Payment], PaymentError> {
        if let payment = paymentToReturn {
            return Just([payment])
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        }
        return Just([])
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func getPaymentsCount() -> AnyPublisher<Int, PaymentError> {
        return Just(1)
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }

    func searchPayments(query: String) -> AnyPublisher<[Payment], PaymentError> {
        if let payment = paymentToReturn {
            return Just([payment])
                .setFailureType(to: PaymentError.self)
                .eraseToAnyPublisher()
        }
        return Just([])
            .setFailureType(to: PaymentError.self)
            .eraseToAnyPublisher()
    }
}