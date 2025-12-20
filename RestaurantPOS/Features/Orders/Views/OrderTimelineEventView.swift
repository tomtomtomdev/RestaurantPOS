//
//  OrderTimelineEventView.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Order Timeline Event View

class OrderTimelineEventView: UIView {

    // MARK: - Properties

    private let iconImageView = UIImageView()
    private let lineView = UIView()
    private let contentStackView = UIStackView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let timeLabel = UILabel()

    // MARK: - Initialization

    init(event: OrderTimelineEvent) {
        super.init(frame: .zero)
        setupUI()
        configure(with: event)
    }

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

        addSubview(lineView)
        addSubview(iconImageView)
        addSubview(contentStackView)
        addSubview(timeLabel)

        setupLine()
        setupIcon()
        setupContentStack()
        setupLabels()
        setupConstraints()
    }

    private func setupLine() {
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = .systemGray4
        lineView.layer.cornerRadius = 1
    }

    private func setupIcon() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 12
        iconImageView.layer.masksToBounds = true
    }

    private func setupContentStack() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 2
        contentStackView.alignment = .leading
        contentStackView.distribution = .fill
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .right
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Line view
            lineView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            lineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            lineView.widthAnchor.constraint(equalToConstant: 2),
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            // Icon image view
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Content stack view
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -12),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            timeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with event: OrderTimelineEvent) {
        titleLabel.text = event.title
        descriptionLabel.text = event.description

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        timeLabel.text = formatter.string(from: event.date)

        iconImageView.image = UIImage(systemName: event.type.iconName)
        iconImageView.backgroundColor = event.type.iconColor
        iconImageView.tintColor = .white

        // Update content stack to include time label as well
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStackView.addArrangedSubview(timeLabel)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
    }
}

// MARK: - Order Total Summary View

class OrderTotalSummaryView: UIView {

    // MARK: - Properties

    private let containerStackView = UIStackView()
    private let dividerView = UIView()
    private let subtotalLabel = UILabel()
    private let taxLabel = UILabel()
    private let totalLabel = UILabel()
    private let subtotalValueLabel = UILabel()
    private let taxValueLabel = UILabel()
    private let totalValueLabel = UILabel()

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

        setupContainer()
        setupDivider()
        setupLabels()
        setupConstraints()
    }

    private func setupContainer() {
        addSubview(containerStackView)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.axis = .vertical
        containerStackView.spacing = 12
        containerStackView.alignment = .fill
        containerStackView.distribution = .fill
    }

    private func setupDivider() {
        containerStackView.addArrangedSubview(dividerView)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .systemGray5
        dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    private func setupLabels() {
        // Subtotal row
        let subtotalRow = createLabelRow(titleLabel: subtotalLabel, valueLabel: subtotalValueLabel)
        containerStackView.addArrangedSubview(subtotalRow)

        // Tax row
        let taxRow = createLabelRow(titleLabel: taxLabel, valueLabel: taxValueLabel)
        containerStackView.addArrangedSubview(taxRow)

        // Total row
        let totalRow = createLabelRow(titleLabel: totalLabel, valueLabel: totalValueLabel)
        containerStackView.addArrangedSubview(totalRow)

        // Configure individual labels
        subtotalLabel.text = "Subtotal"
        subtotalLabel.font = UIFont.systemFont(ofSize: 16)
        subtotalLabel.textColor = .secondaryLabel

        taxLabel.text = "Tax"
        taxLabel.font = UIFont.systemFont(ofSize: 16)
        taxLabel.textColor = .secondaryLabel

        totalLabel.text = "Total"
        totalLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        totalLabel.textColor = .label

        subtotalValueLabel.font = UIFont.systemFont(ofSize: 16)
        subtotalValueLabel.textColor = .label
        subtotalValueLabel.textAlignment = .right

        taxValueLabel.font = UIFont.systemFont(ofSize: 16)
        taxValueLabel.textColor = .label
        taxValueLabel.textAlignment = .right

        totalValueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        totalValueLabel.textColor = .systemGreen
        totalValueLabel.textAlignment = .right
    }

    private func createLabelRow(titleLabel: UILabel, valueLabel: UILabel) -> UIStackView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 0
        rowStack.alignment = .center
        rowStack.distribution = .fillEqually

        rowStack.addArrangedSubview(titleLabel)
        rowStack.addArrangedSubview(valueLabel)

        return rowStack
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Configuration

    func configure(with order: Order) {
        subtotalValueLabel.text = formatCurrency(order.subtotal)
        taxValueLabel.text = formatCurrency(order.tax)
        totalValueLabel.text = formatCurrency(order.totalAmount)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

