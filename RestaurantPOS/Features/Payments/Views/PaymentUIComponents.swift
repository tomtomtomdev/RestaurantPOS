//
//  PaymentUIComponents.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Payment Order Summary View

class PaymentOrderSummaryView: UIView {

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let orderNumberLabel = UILabel()
    private let itemCountLabel = UILabel()
    private let amountLabel = UILabel()
    private let separatorView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor

        addSubview(titleLabel)
        addSubview(orderNumberLabel)
        addSubview(itemCountLabel)
        addSubview(amountLabel)
        addSubview(separatorView)

        setupLabels()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Order Summary"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        orderNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        orderNumberLabel.font = UIFont.systemFont(ofSize: 16)
        orderNumberLabel.textColor = .secondaryLabel

        itemCountLabel.translatesAutoresizingMaskIntoConstraints = false
        itemCountLabel.font = UIFont.systemFont(ofSize: 16)
        itemCountLabel.textColor = .secondaryLabel

        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        amountLabel.textColor = .label
        amountLabel.textAlignment = .right

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .systemGray5
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            orderNumberLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            orderNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            itemCountLabel.topAnchor.constraint(equalTo: orderNumberLabel.bottomAnchor, constant: 4),
            itemCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            amountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bottomAnchor.constraint(equalTo: itemCountLabel.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Configuration

    func configure(with order: Order) {
        orderNumberLabel.text = "Order #\(order.orderNumber)"
        itemCountLabel.text = "\(order.items.count) items"
        amountLabel.text = formatCurrency(order.totalAmount)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - Payment Type Selection View

class PaymentTypeSelectionView: UIView {

    // MARK: - Properties

    weak var delegate: PaymentTypeSelectionViewDelegate?

    private let titleLabel = UILabel()
    private let processorLabel = UILabel()
    private let paymentTypeStackView = UIStackView()
    private let processorStackView = UIStackView()
    private var paymentTypeButtons: [PaymentTypeButton] = []
    private var processorButtons: [ProcessorButton] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor

        addSubview(titleLabel)
        addSubview(paymentTypeStackView)
        addSubview(processorLabel)
        addSubview(processorStackView)

        setupLabels()
        setupButtons()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Payment Type"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        processorLabel.translatesAutoresizingMaskIntoConstraints = false
        processorLabel.text = "Payment Processor"
        processorLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        processorLabel.textColor = .label
        processorLabel.topAnchor.constraint(equalTo: paymentTypeStackView.bottomAnchor, constant: 24).isActive = true
    }

    private func setupButtons() {
        // Payment type buttons
        paymentTypeStackView.translatesAutoresizingMaskIntoConstraints = false
        paymentTypeStackView.axis = .vertical
        paymentTypeStackView.spacing = 12
        paymentTypeStackView.distribution = .fillEqually

        for paymentType in PaymentType.allCases {
            let button = PaymentTypeButton(type: paymentType)
            button.addTarget(self, action: #selector(paymentTypeButtonTapped(_:)), for: .touchUpInside)
            paymentTypeStackView.addArrangedSubview(button)
            paymentTypeButtons.append(button)
        }

        // Processor buttons
        processorStackView.translatesAutoresizingMaskIntoConstraints = false
        processorStackView.axis = .horizontal
        processorStackView.spacing = 12
        processorStackView.distribution = .fillEqually

        for processor in PaymentProcessor.allCases {
            let button = ProcessorButton(processor: processor)
            button.addTarget(self, action: #selector(processorButtonTapped(_:)), for: .touchUpInside)
            processorStackView.addArrangedSubview(button)
            processorButtons.append(button)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            paymentTypeStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            paymentTypeStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            paymentTypeStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            processorLabel.topAnchor.constraint(equalTo: paymentTypeStackView.bottomAnchor, constant: 24),
            processorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            processorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            processorStackView.topAnchor.constraint(equalTo: processorLabel.bottomAnchor, constant: 16),
            processorStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            processorStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            bottomAnchor.constraint(equalTo: processorStackView.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Configuration

    func configure(with processors: [PaymentProcessor]) {
        // Enable/disable processor buttons based on availability
        for button in processorButtons {
            button.isEnabled = processors.contains(button.processor)
        }
    }

    // MARK: - Actions

    @objc private func paymentTypeButtonTapped(_ button: PaymentTypeButton) {
        // Deselect all buttons
        paymentTypeButtons.forEach { $0.isSelected = false }
        // Select tapped button
        button.isSelected = true
        // Notify delegate
        delegate?.paymentTypeSelectionView(self, didSelectPaymentType: button.paymentType)
    }

    @objc private func processorButtonTapped(_ button: ProcessorButton) {
        // Deselect all buttons
        processorButtons.forEach { $0.isSelected = false }
        // Select tapped button
        button.isSelected = true
        // Notify delegate
        delegate?.paymentTypeSelectionView(self, didSelectProcessor: button.processor)
    }
}

// MARK: - Payment Type Button

class PaymentTypeButton: UIButton {

    let paymentType: PaymentType

    init(type: PaymentType) {
        self.paymentType = type
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setTitle(paymentType.displayName, for: .normal)
        setImage(UIImage(systemName: paymentType.systemImageName), for: .normal)
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray5.cgColor
        backgroundColor = .systemBackground

        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        setTitleColor(.label, for: .normal)
        tintColor = .systemBlue

        // Image configuration
        imageView?.contentMode = .scaleAspectFit
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = .systemBlue
                setTitleColor(.white, for: .normal)
                tintColor = .white
                layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                backgroundColor = .systemBackground
                setTitleColor(.label, for: .normal)
                tintColor = .systemBlue
                layer.borderColor = UIColor.systemGray5.cgColor
            }
        }
    }
}

// MARK: - Processor Button

class ProcessorButton: UIButton {

    let processor: PaymentProcessor

    init(processor: PaymentProcessor) {
        self.processor = processor
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setTitle(processor.displayName, for: .normal)
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray5.cgColor
        backgroundColor = .systemBackground

        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        setTitleColor(.label, for: .normal)

        // Make it smaller than payment type buttons
        heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = .systemGreen
                setTitleColor(.white, for: .normal)
                layer.borderColor = UIColor.systemGreen.cgColor
            } else {
                backgroundColor = .systemBackground
                setTitleColor(.label, for: .normal)
                layer.borderColor = UIColor.systemGray5.cgColor
            }
        }
    }

    override var isEnabled: Bool {
        didSet {
            if !isEnabled {
                backgroundColor = .systemGray6
                setTitleColor(.systemGray, for: .normal)
                layer.borderColor = UIColor.systemGray4.cgColor
            } else if !isSelected {
                backgroundColor = .systemBackground
                setTitleColor(.label, for: .normal)
                layer.borderColor = UIColor.systemGray5.cgColor
            }
        }
    }
}

// MARK: - Protocols

protocol PaymentTypeSelectionViewDelegate: AnyObject {
    func paymentTypeSelectionView(_ view: PaymentTypeSelectionView, didSelectPaymentType type: PaymentType)
    func paymentTypeSelectionView(_ view: PaymentTypeSelectionView, didSelectProcessor processor: PaymentProcessor)
}