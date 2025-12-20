//
//  OrderItemTableViewCell.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Order Item Table View Cell

class OrderItemTableViewCell: UITableViewCell {
    static let identifier = "OrderItemTableViewCell"

    // MARK: - Properties

    private let containerView = UIView()
    private let itemInfoStackView = UIStackView()
    private let itemNameLabel = UILabel()
    private let itemDetailsLabel = UILabel()
    private let quantityLabel = UILabel()
    private let priceLabel = UILabel()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        setupContainer()
        setupItemInfoStack()
        setupLabels()
        setupConstraints()
    }

    private func setupContainer() {
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor

        // Add subtle shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 1)
        containerView.layer.shadowRadius = 2
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.masksToBounds = false
    }

    private func setupItemInfoStack() {
        containerView.addSubview(itemInfoStackView)
        itemInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        itemInfoStackView.axis = .vertical
        itemInfoStackView.spacing = 4
        itemInfoStackView.alignment = .leading
        itemInfoStackView.distribution = .fill
    }

    private func setupLabels() {
        // Item name label
        itemInfoStackView.addArrangedSubview(itemNameLabel)
        itemNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        itemNameLabel.textColor = .label
        itemNameLabel.numberOfLines = 2

        // Item details label
        itemInfoStackView.addArrangedSubview(itemDetailsLabel)
        itemDetailsLabel.font = UIFont.systemFont(ofSize: 14)
        itemDetailsLabel.textColor = .secondaryLabel
        itemDetailsLabel.numberOfLines = 2

        // Quantity label
        containerView.addSubview(quantityLabel)
        quantityLabel.translatesAutoresizingMaskIntoConstraints = false
        quantityLabel.font = UIFont.systemFont(ofSize: 14)
        quantityLabel.textColor = .secondaryLabel
        quantityLabel.textAlignment = .center
        quantityLabel.backgroundColor = .systemGray6
        quantityLabel.layer.cornerRadius = 12
        quantityLabel.layer.masksToBounds = true

        // Price label
        containerView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        priceLabel.textColor = .label
        priceLabel.textAlignment = .right
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Item info stack view
            itemInfoStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            itemInfoStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            itemInfoStackView.trailingAnchor.constraint(lessThanOrEqualTo: quantityLabel.leadingAnchor, constant: -12),
            itemInfoStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            // Quantity label
            quantityLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            quantityLabel.trailingAnchor.constraint(equalTo: priceLabel.leadingAnchor, constant: -12),
            quantityLabel.widthAnchor.constraint(equalToConstant: 80),
            quantityLabel.heightAnchor.constraint(equalToConstant: 24),

            // Price label
            priceLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            priceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    // MARK: - Configuration

    func configure(with orderItem: OrderItem) {
        itemNameLabel.text = orderItem.name
        quantityLabel.text = "Qty: \(orderItem.quantity)"
        priceLabel.text = formatCurrency(orderItem.totalPrice)

        // Build item details string
        var details: [String] = []

        if !orderItem.modifiers.isEmpty {
            details.append("Modifiers: \(orderItem.modifiers.joined(separator: ", "))")
        }

        if let instructions = orderItem.specialInstructions, !instructions.isEmpty {
            details.append("Notes: \(instructions)")
        }

        if details.isEmpty {
            itemDetailsLabel.text = "No modifiers or special instructions"
        } else {
            itemDetailsLabel.text = details.joined(separator: "\n")
        }

        // Update quantity label color based on quantity
        if orderItem.quantity > 1 {
            quantityLabel.backgroundColor = .systemBlue
            quantityLabel.textColor = .white
        } else {
            quantityLabel.backgroundColor = .systemGray6
            quantityLabel.textColor = .label
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        itemNameLabel.text = nil
        itemDetailsLabel.text = nil
        quantityLabel.text = nil
        priceLabel.text = nil
        quantityLabel.backgroundColor = .systemGray6
        quantityLabel.textColor = .label
    }

    // MARK: - Animation

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        UIView.animate(withDuration: animated ? 0.1 : 0) {
            if highlighted {
                self.containerView.backgroundColor = UIColor.systemGray6
                self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            } else {
                self.containerView.backgroundColor = .systemBackground
                self.containerView.transform = .identity
            }
        }
    }
}

// MARK: - Order Detail Header View

class OrderDetailHeaderView: UIView {

    // MARK: - Properties

    private let orderNumberLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusBadgeLabel = UILabel()

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

        addSubview(orderNumberLabel)
        addSubview(dateLabel)
        addSubview(statusBadgeLabel)

        setupLabels()
        setupConstraints()
    }

    private func setupLabels() {
        orderNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        orderNumberLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        orderNumberLabel.textColor = .label
        orderNumberLabel.textAlignment = .left

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 16)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .left

        statusBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        statusBadgeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusBadgeLabel.textColor = .white
        statusBadgeLabel.textAlignment = .center
        statusBadgeLabel.layer.cornerRadius = 12
        statusBadgeLabel.layer.masksToBounds = true
        statusBadgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            orderNumberLabel.topAnchor.constraint(equalTo: topAnchor),
            orderNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            dateLabel.topAnchor.constraint(equalTo: orderNumberLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            statusBadgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusBadgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            statusBadgeLabel.heightAnchor.constraint(equalToConstant: 24),

            bottomAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8)
        ])
    }

    // MARK: - Configuration

    func configure(with order: Order) {
        orderNumberLabel.text = order.orderNumber

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: order.createdAt)

        statusBadgeLabel.text = order.status.displayName
        statusBadgeLabel.backgroundColor = statusColor(for: order.status)
    }

    private func statusColor(for status: OrderStatus) -> UIColor {
        switch status {
        case .pending:
            return .systemOrange
        case .inProgress:
            return .systemBlue
        case .ready:
            return .systemGreen
        case .completed:
            return .systemMint
        case .cancelled:
            return .systemRed
        }
    }
}

// MARK: - Order Status Card View

class OrderStatusCardView: UIView {

    // MARK: - Properties

    weak var delegate: OrderStatusCardViewDelegate?

    private let statusIconImageView = UIImageView()
    private let statusLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let changeStatusButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let buttonsStackView = UIStackView()

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

        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        addSubview(statusIconImageView)
        addSubview(statusLabel)
        addSubview(descriptionLabel)
        addSubview(buttonsStackView)

        setupStatusIcon()
        setupLabels()
        setupButtons()
    }

    private func setupStatusIcon() {
        statusIconImageView.translatesAutoresizingMaskIntoConstraints = false
        statusIconImageView.contentMode = .scaleAspectFit
        statusIconImageView.tintColor = .systemBlue
    }

    private func setupLabels() {
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        statusLabel.textColor = .label

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
    }

    private func setupButtons() {
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonsStackView.axis = .horizontal
        buttonsStackView.spacing = 12
        buttonsStackView.distribution = .fillEqually

        changeStatusButton.translatesAutoresizingMaskIntoConstraints = false
        changeStatusButton.setTitle("Change Status", for: .normal)
        changeStatusButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        changeStatusButton.backgroundColor = .systemBlue
        changeStatusButton.setTitleColor(.white, for: .normal)
        changeStatusButton.layer.cornerRadius = 8
        changeStatusButton.addTarget(self, action: #selector(changeStatusTapped), for: .touchUpInside)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setTitle("Cancel Order", for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.backgroundColor = .systemRed
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        buttonsStackView.addArrangedSubview(changeStatusButton)
        buttonsStackView.addArrangedSubview(cancelButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusIconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            statusIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            statusIconImageView.widthAnchor.constraint(equalToConstant: 24),
            statusIconImageView.heightAnchor.constraint(equalToConstant: 24),

            statusLabel.centerYAnchor.constraint(equalTo: statusIconImageView.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusIconImageView.trailingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            buttonsStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            buttonsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 44),
            bottomAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Configuration

    func configure(with order: Order) {
        statusLabel.text = order.status.displayName

        switch order.status {
        case .pending:
            descriptionLabel.text = "Order is waiting to be prepared"
            statusIconImageView.image = UIImage(systemName: "clock")
            statusIconImageView.tintColor = .systemOrange
            changeStatusButton.isEnabled = true
            cancelButton.isEnabled = true

        case .inProgress:
            descriptionLabel.text = "Order is currently being prepared"
            statusIconImageView.image = UIImage(systemName: "arrow.triangle.2.circlepath")
            statusIconImageView.tintColor = .systemBlue
            changeStatusButton.isEnabled = true
            cancelButton.isEnabled = true

        case .ready:
            descriptionLabel.text = "Order is ready for pickup/delivery"
            statusIconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusIconImageView.tintColor = .systemGreen
            changeStatusButton.isEnabled = true
            cancelButton.isEnabled = false

        case .completed:
            descriptionLabel.text = "Order has been completed"
            statusIconImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusIconImageView.tintColor = .systemMint
            changeStatusButton.isEnabled = false
            cancelButton.isEnabled = false

        case .cancelled:
            descriptionLabel.text = "Order was cancelled"
            statusIconImageView.image = UIImage(systemName: "xmark.circle.fill")
            statusIconImageView.tintColor = .systemRed
            changeStatusButton.isEnabled = false
            cancelButton.isEnabled = false
        }
    }

    // MARK: - Actions

    @objc private func changeStatusTapped() {
        delegate?.orderStatusCardViewDidTapStatusButton(self)
    }

    @objc private func cancelTapped() {
        delegate?.orderStatusCardViewDidTapCancelButton(self)
    }
}

// MARK: - Order Status Card View Delegate

protocol OrderStatusCardViewDelegate: AnyObject {
    func orderStatusCardViewDidTapStatusButton(_ view: OrderStatusCardView)
    func orderStatusCardViewDidTapCancelButton(_ view: OrderStatusCardView)
}