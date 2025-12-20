//
//  PaymentViewController.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit
import Combine

// MARK: - Payment View Controller

class PaymentViewController: UIViewController {

    // MARK: - Properties

    private let order: Order
    private let viewModel: PaymentViewModel
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var orderSummaryView: PaymentOrderSummaryView = {
        let view = PaymentOrderSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var paymentTypeSelectionView: PaymentTypeSelectionView = {
        let view = PaymentTypeSelectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var cardDetailsView: PaymentCardDetailsView = {
        let view = PaymentCardDetailsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        return view
    }()

    private lazy var paymentMethodsView: PaymentMethodsView = {
        let view = PaymentMethodsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var tipSelectionView: PaymentTipSelectionView = {
        let view = PaymentTipSelectionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var paymentSummaryView: PaymentSummaryView = {
        let view = PaymentSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var processPaymentButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Process Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(processPaymentTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var loadingOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization

    init(order: Order, paymentService: PaymentServiceProtocol) {
        self.order = order
        self.viewModel = PaymentViewModel(paymentService: paymentService)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        configureData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Set up keyboard observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Payment"
        view.backgroundColor = .systemBackground

        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(orderSummaryView)
        contentView.addSubview(paymentTypeSelectionView)
        contentView.addSubview(cardDetailsView)
        contentView.addSubview(paymentMethodsView)
        contentView.addSubview(tipSelectionView)
        contentView.addSubview(paymentSummaryView)
        contentView.addSubview(processPaymentButton)

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingIndicator)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Order summary
            orderSummaryView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            orderSummaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            orderSummaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Payment type selection
            paymentTypeSelectionView.topAnchor.constraint(equalTo: orderSummaryView.bottomAnchor, constant: 24),
            paymentTypeSelectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            paymentTypeSelectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Card details
            cardDetailsView.topAnchor.constraint(equalTo: paymentTypeSelectionView.bottomAnchor, constant: 16),
            cardDetailsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardDetailsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Payment methods
            paymentMethodsView.topAnchor.constraint(equalTo: paymentTypeSelectionView.bottomAnchor, constant: 16),
            paymentMethodsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            paymentMethodsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Tip selection
            tipSelectionView.topAnchor.constraint(equalTo: cardDetailsView.bottomAnchor, constant: 24),
            tipSelectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tipSelectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Payment summary
            paymentSummaryView.topAnchor.constraint(equalTo: tipSelectionView.bottomAnchor, constant: 24),
            paymentSummaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            paymentSummaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Process payment button
            processPaymentButton.topAnchor.constraint(equalTo: paymentSummaryView.bottomAnchor, constant: 32),
            processPaymentButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            processPaymentButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            processPaymentButton.heightAnchor.constraint(equalToConstant: 56),
            processPaymentButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),

            // Loading overlay
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
    }

    private func setupBindings() {
        // Bind to ViewModel properties
        viewModel.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProcessing in
                self?.updateUIForProcessing(isProcessing)
            }
            .store(in: &cancellables)

        viewModel.$selectedPaymentType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paymentType in
                self?.updatePaymentTypeUI(paymentType)
            }
            .store(in: &cancellables)

        viewModel.$paymentMethods
            .receive(on: DispatchQueue.main)
            .sink { [weak self] methods in
                self?.paymentMethodsView.configure(with: methods)
            }
            .store(in: &cancellables)

        viewModel.$totalAmount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePaymentSummary()
            }
            .store(in: &cancellables)

        viewModel.error.bind { [weak self] error in
            guard let error = error as? PaymentError else { return }
            self?.showErrorAlert(error)
        }

        // Handle payment success
        viewModel.$paymentResult
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payment in
                if payment.status == .completed {
                    self?.handlePaymentSuccess(payment)
                } else {
                    self?.handlePaymentFailure(payment)
                }
            }
            .store(in: &cancellables)
    }

    private func configureData() {
        viewModel.setOrder(order)
        orderSummaryView.configure(with: order)
        paymentTypeSelectionView.configure(with: viewModel.availableProcessors)
        updatePaymentSummary()
    }

    // MARK: - UI Updates

    private func updateUIForProcessing(_ isProcessing: Bool) {
        processPaymentButton.isEnabled = !isProcessing
        if isProcessing {
            processPaymentButton.setTitle("Processing...", for: .normal)
            showLoading(true)
        } else {
            processPaymentButton.setTitle("Process Payment", for: .normal)
            showLoading(false)
        }
    }

    private func updatePaymentTypeUI(_ paymentType: PaymentType) {
        if paymentType.requiresCardDetails {
            cardDetailsView.isHidden = false
            paymentMethodsView.isHidden = true
            tipSelectionView.topAnchor.constraint(equalTo: cardDetailsView.bottomAnchor, constant: 24).isActive = true
        } else {
            cardDetailsView.isHidden = true
            paymentMethodsView.isHidden = false
            tipSelectionView.topAnchor.constraint(equalTo: paymentMethodsView.bottomAnchor, constant: 24).isActive = true
        }
    }

    private func updatePaymentSummary() {
        paymentSummaryView.configure(
            subtotal: order.totalAmount,
            tip: viewModel.tipAmount,
            fee: viewModel.processingFee,
            total: viewModel.totalAmount
        )
    }

    private func showLoading(_ show: Bool) {
        loadingOverlay.isHidden = !show
        if show {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: - Actions

    @objc private func processPaymentTapped() {
        // Validate card details if needed
        if viewModel.selectedPaymentType.requiresCardDetails {
            guard let cardNumber = cardDetailsView.cardNumber,
                  let cardholderName = cardDetailsView.cardholderName,
                  let expirationMonth = cardDetailsView.expirationMonth,
                  let expirationYear = cardDetailsView.expirationYear,
                  let cvv = cardDetailsView.cvv else {
                showErrorAlert(PaymentError.invalidCardDetails)
                return
            }

            viewModel.cardNumber = cardNumber
            viewModel.cardholderName = cardholderName
            viewModel.expirationMonth = expirationMonth
            viewModel.expirationYear = expirationYear
            viewModel.cvv = cvv
        }

        viewModel.processPayment()
    }

    private func handlePaymentSuccess(_ payment: Payment) {
        let alert = UIAlertController(
            title: "Payment Successful",
            message: "Payment of \(payment.formattedAmount) has been processed successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func handlePaymentFailure(_ payment: Payment) {
        let message: String
        if let failureReason = payment.failureReason {
            message = "Payment failed: \(failureReason)"
        } else {
            message = "Payment could not be processed. Please try again."
        }

        let alert = UIAlertController(
            title: "Payment Failed",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.viewModel.processPayment()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}

// MARK: - PaymentTypeSelectionViewDelegate

extension PaymentViewController: PaymentTypeSelectionViewDelegate {
    func paymentTypeSelectionView(_ view: PaymentTypeSelectionView, didSelectPaymentType type: PaymentType) {
        viewModel.selectPaymentType(type)
    }

    func paymentTypeSelectionView(_ view: PaymentTypeSelectionView, didSelectProcessor processor: PaymentProcessor) {
        viewModel.selectedProcessor = processor
    }
}

// MARK: - PaymentCardDetailsViewDelegate

extension PaymentViewController: PaymentCardDetailsViewDelegate {
    func paymentCardDetailsViewDidUpdate(_ view: PaymentCardDetailsView) {
        // Update ViewModel with card details
        if let cardNumber = view.cardNumber,
           let cardholderName = view.cardholderName,
           let expirationMonth = view.expirationMonth,
           let expirationYear = view.expirationYear,
           let cvv = view.cvv {
            viewModel.cardNumber = cardNumber
            viewModel.cardholderName = cardholderName
            viewModel.expirationMonth = expirationMonth
            viewModel.expirationYear = expirationYear
            viewModel.cvv = cvv
        }
    }
}

// MARK: - PaymentMethodsViewDelegate

extension PaymentViewController: PaymentMethodsViewDelegate {
    func paymentMethodsView(_ view: PaymentMethodsView, didSelectPaymentMethod method: PaymentMethod) {
        viewModel.selectPaymentMethod(method)
    }

    func paymentMethodsViewDidRequestAddPaymentMethod(_ view: PaymentMethodsView) {
        // Navigate to add payment method flow
        let alert = UIAlertController(
            title: "Add Payment Method",
            message: "Payment method management would be implemented here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PaymentTipSelectionViewDelegate

extension PaymentViewController: PaymentTipSelectionViewDelegate {
    func paymentTipSelectionView(_ view: PaymentTipSelectionView, didSelectTipPercentage percentage: Double) {
        viewModel.calculateTip(percentage: percentage)
    }

    func paymentTipSelectionView(_ view: PaymentTipSelectionView, didSelectCustomTip amount: Decimal) {
        viewModel.tipAmount = amount
        viewModel.tipPercentage = 0
    }
}