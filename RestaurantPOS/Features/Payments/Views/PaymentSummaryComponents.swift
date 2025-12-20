//
//  PaymentSummaryComponents.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Payment Tip Selection View

class PaymentTipSelectionView: UIView {

    // MARK: - Properties

    weak var delegate: PaymentTipSelectionViewDelegate?

    private let titleLabel = UILabel()
    private let tipButtonsStackView = UIStackView()
    private let customTipContainerView = UIView()
    private let customTipTextField = UITextField()
    private let customTipPrefixLabel = UILabel()
    private var tipButtons: [TipButton] = []

    // MARK: - Computed Properties

    var customTipAmount: Decimal? {
        guard let text = customTipTextField.text?.replacingOccurrences(of: "$", with: ""),
              let amount = Decimal(string: text) else {
            return nil
        }
        return amount
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTargets()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupTargets()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor

        addSubview(titleLabel)
        addSubview(tipButtonsStackView)
        addSubview(customTipContainerView)

        setupLabels()
        setupTipButtons()
        setupCustomTip()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Add Tip"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
    }

    private func setupTipButtons() {
        tipButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        tipButtonsStackView.axis = .horizontal
        tipButtonsStackView.spacing = 12
        tipButtonsStackView.distribution = .fillEqually

        let tipPercentages: [Double] = [0, 15, 18, 20, 25]

        for percentage in tipPercentages {
            let button = TipButton(percentage: percentage)
            button.addTarget(self, action: #selector(tipButtonTapped(_:)), for: .touchUpInside)
            tipButtonsStackView.addArrangedSubview(button)
            tipButtons.append(button)
        }

        // Default to 15%
        tipButtons[1].isSelected = true
    }

    private func setupCustomTip() {
        customTipContainerView.translatesAutoresizingMaskIntoConstraints = false
        customTipContainerView.backgroundColor = .systemGray6
        customTipContainerView.layer.cornerRadius = 8
        customTipContainerView.addSubview(customTipPrefixLabel)
        customTipContainerView.addSubview(customTipTextField)

        customTipPrefixLabel.translatesAutoresizingMaskIntoConstraints = false
        customTipPrefixLabel.text = "$"
        customTipPrefixLabel.font = UIFont.systemFont(ofSize: 16)
        customTipPrefixLabel.textColor = .secondaryLabel

        customTipTextField.translatesAutoresizingMaskIntoConstraints = false
        customTipTextField.placeholder = "0.00"
        customTipTextField.font = UIFont.systemFont(ofSize: 16)
        customTipTextField.borderStyle = .none
        customTipTextField.backgroundColor = .clear
        customTipTextField.keyboardType = .decimalPad
    }

    private func setupTargets() {
        customTipTextField.addTarget(self, action: #selector(customTipChanged), for: .editingChanged)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            tipButtonsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tipButtonsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tipButtonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            customTipContainerView.topAnchor.constraint(equalTo: tipButtonsStackView.bottomAnchor, constant: 16),
            customTipContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            customTipContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            customTipContainerView.heightAnchor.constraint(equalToConstant: 44),
            customTipContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            customTipPrefixLabel.leadingAnchor.constraint(equalTo: customTipContainerView.leadingAnchor, constant: 12),
            customTipPrefixLabel.centerYAnchor.constraint(equalTo: customTipContainerView.centerYAnchor),
            customTipPrefixLabel.widthAnchor.constraint(equalToConstant: 12),

            customTipTextField.leadingAnchor.constraint(equalTo: customTipPrefixLabel.trailingAnchor, constant: 4),
            customTipTextField.trailingAnchor.constraint(equalTo: customTipContainerView.trailingAnchor, constant: -12),
            customTipTextField.centerYAnchor.constraint(equalTo: customTipContainerView.centerYAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func tipButtonTapped(_ button: TipButton) {
        // Deselect all buttons
        tipButtons.forEach { $0.isSelected = false }
        // Select tapped button
        button.isSelected = true

        // Clear custom tip
        customTipTextField.text = ""

        // Notify delegate
        delegate?.paymentTipSelectionView(self, didSelectTipPercentage: button.percentage)
    }

    @objc private func customTipChanged() {
        // Deselect tip buttons
        tipButtons.forEach { $0.isSelected = false }

        // Notify delegate of custom tip
        if let amount = customTipAmount {
            delegate?.paymentTipSelectionView(self, didSelectCustomTip: amount)
        }
    }

    // MARK: - Configuration

    func configure(with baseAmount: Decimal) {
        // Update tip button amounts based on base amount
        for button in tipButtons {
            button.configure(baseAmount: baseAmount)
        }
    }
}

// MARK: - Tip Button

class TipButton: UIButton {

    let percentage: Double
    private let amountLabel = UILabel()

    init(percentage: Double) {
        self.percentage = percentage
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 8
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGray5.cgColor
        backgroundColor = .systemBackground

        // Set up stack view for percentage and amount
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center

        let percentageLabel = UILabel()
        percentageLabel.text = percentage == 0 ? "No Tip" : "\(Int(percentage))%"
        percentageLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        percentageLabel.textColor = .label

        amountLabel.text = "$0.00"
        amountLabel.font = UIFont.systemFont(ofSize: 12)
        amountLabel.textColor = .secondaryLabel

        stackView.addArrangedSubview(percentageLabel)
        stackView.addArrangedSubview(amountLabel)

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        heightAnchor.constraint(equalToConstant: 64).isActive = true
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = .systemGreen
                layer.borderColor = UIColor.systemGreen.cgColor
                amountLabel.textColor = .white
                // Update text colors for all labels
                if let stackView = subviews.first as? UIStackView,
                   let percentageLabel = stackView.arrangedSubviews.first as? UILabel {
                    percentageLabel.textColor = .white
                }
            } else {
                backgroundColor = .systemBackground
                layer.borderColor = UIColor.systemGray5.cgColor
                amountLabel.textColor = .secondaryLabel
                // Update text colors for all labels
                if let stackView = subviews.first as? UIStackView,
                   let percentageLabel = stackView.arrangedSubviews.first as? UILabel {
                    percentageLabel.textColor = .label
                }
            }
        }
    }

    func configure(baseAmount: Decimal) {
        let tipAmount = baseAmount * Decimal(percentage) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        amountLabel.text = formatter.string(from: NSDecimalNumber(decimal: tipAmount)) ?? "$0.00"
    }
}

// MARK: - Payment Summary View

class PaymentSummaryView: UIView {

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let summaryStackView = UIStackView()
    private let subtotalRow: UIStackView
    private let tipRow: UIStackView
    private let feeRow: UIStackView
    private let dividerView = UIView()
    private let totalRow: UIStackView

    // MARK: - Subtitle Labels

    private lazy var subtotalLabel = subtotalRow.subviews[0] as! UILabel
    private lazy var subtotalValueLabel = subtotalRow.subviews[1] as! UILabel
    private lazy var tipLabel = tipRow.subviews[0] as! UILabel
    private lazy var tipValueLabel = tipRow.subviews[1] as! UILabel
    private lazy var feeLabel = feeRow.subviews[0] as! UILabel
    private lazy var feeValueLabel = feeRow.subviews[1] as! UILabel
    private lazy var totalLabel = totalRow.subviews[0] as! UILabel
    private lazy var totalValueLabel = totalRow.subviews[1] as! UILabel

    // MARK: - Initialization

    override init(frame: CGRect) {
        subtotalRow = Self.createSummaryRow()
        tipRow = Self.createSummaryRow()
        feeRow = Self.createSummaryRow()
        totalRow = Self.createSummaryRow()

        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        subtotalRow = Self.createSummaryRow()
        tipRow = Self.createSummaryRow()
        feeRow = Self.createSummaryRow()
        totalRow = Self.createSummaryRow()

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
        addSubview(summaryStackView)

        setupLabels()
        setupStackView()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Payment Summary"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        // Configure individual labels
        configureRow(subtotalRow, title: "Subtotal", value: "$0.00", isBold: false)
        configureRow(tipRow, title: "Tip", value: "$0.00", isBold: false)
        configureRow(feeRow, title: "Processing Fee", value: "$0.00", isBold: false)
        configureRow(totalRow, title: "Total", value: "$0.00", isBold: true)

        // Configure divider
        dividerView.backgroundColor = .systemGray5
        dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func setupStackView() {
        summaryStackView.translatesAutoresizingMaskIntoConstraints = false
        summaryStackView.axis = .vertical
        summaryStackView.spacing = 12
        summaryStackView.distribution = .fill

        summaryStackView.addArrangedSubview(subtotalRow)
        summaryStackView.addArrangedSubview(tipRow)
        summaryStackView.addArrangedSubview(feeRow)
        summaryStackView.addArrangedSubview(dividerView)
        summaryStackView.addArrangedSubview(totalRow)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            summaryStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            summaryStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            summaryStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            summaryStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    private static func createSummaryRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.distribution = .fillEqually

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(valueLabel)

        return stackView
    }

    private func configureRow(_ row: UIStackView, title: String, value: String, isBold: Bool) {
        let titleLabel = row.arrangedSubviews[0] as! UILabel
        let valueLabel = row.arrangedSubviews[1] as! UILabel

        titleLabel.text = title
        valueLabel.text = value

        if isBold {
            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            valueLabel.textColor = .systemGreen
        } else {
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.font = UIFont.systemFont(ofSize: 16)
            valueLabel.textColor = .label
        }
    }

    // MARK: - Configuration

    func configure(subtotal: Decimal, tip: Decimal, fee: Decimal, total: Decimal) {
        subtotalValueLabel.text = formatCurrency(subtotal)
        tipValueLabel.text = formatCurrency(tip)
        feeValueLabel.text = formatCurrency(fee)
        totalValueLabel.text = formatCurrency(total)

        // Hide fee row if no fee
        feeRow.isHidden = fee == 0

        // Update tip row based on tip amount
        tipRow.isHidden = tip == 0
        if tip > 0 {
            configureRow(tipRow, title: "Tip", value: formatCurrency(tip), isBold: false)
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

// MARK: - Protocols

protocol PaymentTipSelectionViewDelegate: AnyObject {
    func paymentTipSelectionView(_ view: PaymentTipSelectionView, didSelectTipPercentage percentage: Double)
    func paymentTipSelectionView(_ view: PaymentTipSelectionView, didSelectCustomTip amount: Decimal)
}