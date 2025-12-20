//
//  PaymentViewModel.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation
import Combine
import SwiftUI

// MARK: - Payment View Model

public class PaymentViewModel: BaseViewModel, ObservableObject {

    // MARK: - Properties

    @Published public var order: Order?
    @Published public var paymentAmount: Decimal = 0
    @Published public var selectedPaymentType: PaymentType = .creditCard
    @Published public var selectedProcessor: PaymentProcessor = .stripe
    @Published public var paymentMethods: [PaymentMethod] = []
    @Published public var selectedPaymentMethod: PaymentMethod?
    @Published public var cardNumber: String = ""
    @Published public var cardholderName: String = ""
    @Published public var expirationMonth: String = ""
    @Published public var expirationYear: String = ""
    @Published public var cvv: String = ""
    @Published public var isProcessing: Bool = false
    @Published public var paymentResult: Payment?
    @Published public var processingFee: Decimal = 0
    @Published public var totalAmount: Decimal = 0
    @Published public var tipAmount: Decimal = 0
    @Published public var tipPercentage: Double = 0
    @Published public var availableProcessors: [PaymentProcessor] = []
    @Published public var paymentHistory: [Payment] = []

    // MARK: - Private Properties

    private let paymentService: PaymentServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    public var isPaymentReady: Bool {
        guard let order = order else { return false }

        // Validate amount
        if paymentAmount <= 0 || paymentAmount > order.totalAmount {
            return false
        }

        // Validate payment method based on type
        if selectedPaymentType.requiresCardDetails {
            return isValidCardInfo
        }

        return true
    }

    public var isValidCardInfo: Bool {
        return cardNumber.count >= 13 &&
               cardNumber.count <= 19 &&
               !cardholderName.isEmpty &&
               !expirationMonth.isEmpty &&
               !expirationYear.isEmpty &&
               cvv.count >= 3 &&
               !isCardExpired
    }

    public var isCardExpired: Bool {
        guard let month = Int(expirationMonth),
              let year = Int(expirationYear) else { return true }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        return year < currentYear || (year == currentYear && month < currentMonth)
    }

    public var formattedPaymentAmount: String {
        formatCurrency(paymentAmount)
    }

    public var formattedTipAmount: String {
        formatCurrency(tipAmount)
    }

    public var formattedProcessingFee: String {
        formatCurrency(processingFee)
    }

    public var formattedTotalAmount: String {
        formatCurrency(totalAmount)
    }

    public var maskedCardNumber: String {
        guard cardNumber.count >= 4 else { return cardNumber }
        let lastFour = String(cardNumber.suffix(4))
        return "**** **** **** \(lastFour)"
    }

    public var paymentTypeIcon: String {
        return selectedPaymentType.systemImageName
    }

    public var processorIcon: String {
        switch selectedProcessor {
        case .stripe:
            return "s.square"
        case .square:
            return "qrcode"
        case .paypal:
            return "p.circle"
        case .applePay:
            return "applelogo"
        default:
            return "creditcard"
        }
    }

    // MARK: - Initialization

    public init(paymentService: PaymentServiceProtocol) {
        self.paymentService = paymentService
        super.init()

        setupBindings()
        loadAvailableProcessors()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Update total amount when payment amount, tip, or fee changes
        Publishers.CombineLatest3(
            $paymentAmount,
            $tipAmount,
            $processingFee
        )
        .map { payment, tip, fee in
            payment + tip + fee
        }
        .assign(to: \.totalAmount, on: self)
        .store(in: &cancellables)

        // Update processing fee when payment type or processor changes
        Publishers.CombineLatest($selectedPaymentType, $selectedProcessor)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] paymentType, processor in
                self?.updateProcessingFee()
            }
            .store(in: &cancellables)

        // Load payment methods when processor changes
        $selectedProcessor
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] processor in
                self?.loadPaymentMethods(for: processor)
            }
            .store(in: &cancellables)

        // Set payment amount when order changes
        $order
            .compactMap { $0 }
            .sink { [weak self] order in
                self?.paymentAmount = order.totalAmount
                self?.loadPaymentHistory(for: order.id)
            }
            .store(in: &cancellables)
    }

    private func loadAvailableProcessors() {
        availableProcessors = PaymentProcessor.allCases.filter { processor in
            processor.supportedPaymentTypes.contains(selectedPaymentType)
        }
    }

    // MARK: - Public Methods

    public func setOrder(_ order: Order) {
        self.order = order
        self.paymentAmount = order.totalAmount
        loadPaymentHistory(for: order.id)
    }

    public func selectPaymentType(_ type: PaymentType) {
        selectedPaymentType = type

        // Update available processors for this payment type
        availableProcessors = PaymentProcessor.allCases.filter { processor in
            processor.supportedPaymentTypes.contains(type)
        }

        // Reset selected processor if it's not supported
        if !availableProcessors.contains(selectedProcessor) {
            selectedProcessor = availableProcessors.first ?? .stripe
        }
    }

    public func selectPaymentMethod(_ method: PaymentMethod) {
        selectedPaymentMethod = method
        selectedPaymentType = method.type

        // Auto-fill card details if available
        if method.type.requiresCardDetails {
            cardholderName = method.cardholderName ?? ""
            if let lastFour = method.lastFourDigits {
                // In a real app, you'd have secure storage for full card numbers
                // For demo purposes, we'll just show the masked version
                cardNumber = "**** **** **** \(lastFour)"
            }
        }
    }

    public func processPayment() {
        guard let order = order, isPaymentReady else {
            handleError(PaymentError.invalidPaymentType)
            return
        }

        isProcessing = true
        isLoading = true

        // Create payment object
        let payment = Payment(
            orderID: order.id,
            amount: paymentAmount,
            paymentType: selectedPaymentType,
            processor: selectedProcessor,
            lastFourDigits: selectedPaymentType.requiresCardDetails ? String(cardNumber.suffix(4)) : nil
        )

        // Add tip to metadata if present
        var metadata: [String: Any] = [:]
        if tipAmount > 0 {
            metadata["tip"] = tipAmount.doubleValue
            metadata["tip_percentage"] = tipPercentage
        }

        // Add card details to metadata (in a real app, this would be tokenized)
        if selectedPaymentType.requiresCardDetails {
            metadata["cardholder_name"] = cardholderName
            metadata["card_last_four"] = String(cardNumber.suffix(4))
            if let month = Int(expirationMonth), let year = Int(expirationYear) {
                metadata["expiration"] = "\(String(format: "%02d", month))/\(String(year.suffix(2)))"
            }
        }

        // Process payment
        paymentService.processPayment(payment)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isProcessing = false
                    self?.isLoading = false

                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] processedPayment in
                    self?.handlePaymentSuccess(processedPayment)
                }
            )
            .store(in: &cancellables)
    }

    public func refundPayment(_ payment: Payment, amount: Decimal? = nil) {
        let refundAmount = amount ?? payment.amount

        paymentService.refundPayment(payment, amount: refundAmount)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] refundedPayment in
                    // Refresh payment history
                    if let orderID = self?.order?.id {
                        self?.loadPaymentHistory(for: orderID)
                    }
                }
            )
            .store(in: &cancellables)
    }

    public func calculateTip(percentage: Double) {
        guard let order = order else { return }

        tipPercentage = percentage
        tipAmount = order.totalAmount * Decimal(percentage) / 100
    }

    public func clearCardDetails() {
        cardNumber = ""
        cardholderName = ""
        expirationMonth = ""
        expirationYear = ""
        cvv = ""
        selectedPaymentMethod = nil
    }

    // MARK: - Private Methods

    private func updateProcessingFee() {
        guard let order = order else { return }

        let payment = Payment(
            orderID: order.id,
            amount: paymentAmount,
            paymentType: selectedPaymentType,
            processor: selectedProcessor
        )

        paymentService.calculateFees(for: payment, processor: selectedProcessor)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error calculating processing fee: \(error)")
                        self?.processingFee = 0
                    }
                },
                receiveValue: { [weak self] fee in
                    self?.processingFee = fee
                }
            )
            .store(in: &cancellables)
    }

    private func loadPaymentMethods(for processor: PaymentProcessor) {
        paymentService.getPaymentMethods(for: processor)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error loading payment methods: \(error)")
                        self?.paymentMethods = []
                    }
                },
                receiveValue: { [weak self] methods in
                    self?.paymentMethods = methods
                }
            )
            .store(in: &cancellables)
    }

    private func loadPaymentHistory(for orderID: UUID) {
        paymentService.getPaymentMethods(for: selectedProcessor)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error loading payment methods: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    // This would typically load from a repository
                    // For now, we'll use a placeholder
                    self?.paymentHistory = []
                }
            )
            .store(in: &cancellables)
    }

    private func handlePaymentSuccess(_ payment: Payment) {
        self.paymentResult = payment
        isProcessing = false
        isLoading = false

        // Refresh payment history
        if let orderID = order?.id {
            loadPaymentHistory(for: orderID)
        }

        // Clear sensitive card data
        clearCardDetails()

        // Show success message
        if payment.status == .completed {
            // Success handling would go here
            print("Payment completed successfully")
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - PaymentError Extension

extension PaymentError {
    var localizedDescription: String {
        return errorDescription ?? "Unknown payment error"
    }
}