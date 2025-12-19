//
//  OrderSummaryView.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Order Summary View Delegate

protocol OrderSummaryViewDelegate: AnyObject {
    func orderSummaryViewDidTapViewCart(_ view: OrderSummaryView)
    func orderSummaryViewDidTapCheckout(_ view: OrderSummaryView)
}

// MARK: - Order Summary View

class OrderSummaryView: UIView {

    // MARK: - Properties

    weak var delegate: OrderSummaryViewDelegate?

    private let containerView = UIView()
    private let cartIconImageView = UIImageView()
    private let itemCountLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailsStackView = UIStackView()
    private let subtotalLabel = UILabel()
    private let taxLabel = UILabel()
    private let totalLabel = UILabel()
    private let dividerView = UIView()
    private let viewCartButton = UIButton(type: .system)
    private let checkoutButton = UIButton(type: .system)

    // MARK: - State

    private var itemCount: Int = 0
    private var subtotal: Decimal = 0
    private var tax: Decimal = 0
    private var total: Decimal = 0
    private var isEmpty: Bool = true

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestureRecognizers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGestureRecognizers()
    }

    // MARK: - Setup

    private func setupUI() {
        setupContainer()
        setupHeader()
        setupDetails()
        setupButtons()
        setupConstraints()
    }

    private func setupContainer() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground

        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false

        // Border
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
    }

    private func setupHeader() {
        containerView.addSubview(cartIconImageView)
        cartIconImageView.translatesAutoresizingMaskIntoConstraints = false
        cartIconImageView.image = UIImage(systemName: "cart.fill")
        cartIconImageView.tintColor = .systemBlue
        cartIconImageView.contentMode = .scaleAspectFit

        containerView.addSubview(itemCountLabel)
        itemCountLabel.translatesAutoresizingMaskIntoConstraints = false
        itemCountLabel.text = "0"
        itemCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        itemCountLabel.textColor = .white
        itemCountLabel.textAlignment = .center
        itemCountLabel.backgroundColor = .systemRed
        itemCountLabel.layer.cornerRadius = 10
        itemCountLabel.layer.masksToBounds = true

        containerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Your Order"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
    }

    private func setupDetails() {
        containerView.addSubview(detailsStackView)
        detailsStackView.translatesAutoresizingMaskIntoConstraints = false
        detailsStackView.axis = .vertical
        detailsStackView.spacing = 4
        detailsStackView.alignment = .trailing
        detailsStackView.distribution = .fill

        // Subtotal
        detailsStackView.addArrangedSubview(subtotalLabel)
        subtotalLabel.font = UIFont.systemFont(ofSize: 16)
        subtotalLabel.textColor = .secondaryLabel
        subtotalLabel.textAlignment = .right

        // Tax
        detailsStackView.addArrangedSubview(taxLabel)
        taxLabel.font = UIFont.systemFont(ofSize: 16)
        taxLabel.textColor = .secondaryLabel
        taxLabel.textAlignment = .right

        // Total
        detailsStackView.addArrangedSubview(totalLabel)
        totalLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        totalLabel.textColor = .label
        totalLabel.textAlignment = .right

        // Divider
        containerView.addSubview(dividerView)
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .systemGray5
    }

    private func setupButtons() {
        // View Cart Button
        containerView.addSubview(viewCartButton)
        viewCartButton.translatesAutoresizingMaskIntoConstraints = false
        viewCartButton.setTitle("View Cart", for: .normal)
        viewCartButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        viewCartButton.backgroundColor = .systemGray5
        viewCartButton.layer.cornerRadius = 8
        viewCartButton.setTitleColor(.systemBlue, for: .normal)

        // Checkout Button
        containerView.addSubview(checkoutButton)
        checkoutButton.translatesAutoresizingMaskIntoConstraints = false
        checkoutButton.setTitle("Checkout", for: .normal)
        checkoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        checkoutButton.backgroundColor = .systemBlue
        checkoutButton.layer.cornerRadius = 8
        checkoutButton.setTitleColor(.white, for: .normal)

        // Button actions
        viewCartButton.addTarget(self, action: #selector(viewCartTapped), for: .touchUpInside)
        checkoutButton.addTarget(self, action: #selector(checkoutTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Cart icon
            cartIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cartIconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cartIconImageView.widthAnchor.constraint(equalToConstant: 24),
            cartIconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Item count badge
            itemCountLabel.centerXAnchor.constraint(equalTo: cartIconImageView.trailingAnchor, constant: -2),
            itemCountLabel.centerYAnchor.constraint(equalTo: cartIconImageView.topAnchor, constant: 2),
            itemCountLabel.widthAnchor.constraint(equalToConstant: 20),
            itemCountLabel.heightAnchor.constraint(equalToConstant: 20),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: cartIconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),

            // Details stack
            detailsStackView.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            detailsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Divider
            dividerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            // View cart button
            viewCartButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 12),
            viewCartButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            viewCartButton.widthAnchor.constraint(equalToConstant: 100),
            viewCartButton.heightAnchor.constraint(equalToConstant: 36),

            // Checkout button
            checkoutButton.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 12),
            checkoutButton.leadingAnchor.constraint(equalTo: viewCartButton.trailingAnchor, constant: 12),
            checkoutButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            checkoutButton.heightAnchor.constraint(equalToConstant: 36),
            checkoutButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    private func setupGestureRecognizers() {
        let cartTapGesture = UITapGestureRecognizer(target: self, action: #selector(cartAreaTapped))
        cartIconImageView.addGestureRecognizer(cartTapGesture)
        cartIconImageView.isUserInteractionEnabled = true

        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(cartAreaTapped))
        titleLabel.addGestureRecognizer(titleTapGesture)
        titleLabel.isUserInteractionEnabled = true
    }

    // MARK: - Configuration

    func configure(itemCount: Int, subtotal: Decimal, tax: Decimal, total: Decimal, isEmpty: Bool) {
        self.itemCount = itemCount
        self.subtotal = subtotal
        self.tax = tax
        self.total = total
        self.isEmpty = isEmpty

        updateUI()
    }

    private func updateUI() {
        // Update labels
        itemCountLabel.text = "\(itemCount)"
        subtotalLabel.text = "Subtotal: \(formatCurrency(subtotal))"
        taxLabel.text = "Tax: \(formatCurrency(tax))"
        totalLabel.text = "Total: \(formatCurrency(total))"

        // Update button states
        viewCartButton.isEnabled = !isEmpty
        checkoutButton.isEnabled = !isEmpty

        if isEmpty {
            viewCartButton.backgroundColor = .systemGray5
            viewCartButton.setTitleColor(.systemGray, for: .normal)

            checkoutButton.backgroundColor = .systemGray5
            checkoutButton.setTitleColor(.systemGray, for: .normal)
            checkoutButton.setTitle("Add Items", for: .normal)
        } else {
            viewCartButton.backgroundColor = .systemGray5
            viewCartButton.setTitleColor(.systemBlue, for: .normal)

            checkoutButton.backgroundColor = .systemBlue
            checkoutButton.setTitleColor(.white, for: .normal)
            checkoutButton.setTitle("Checkout", for: .normal)
        }

        // Update title based on item count
        if itemCount == 0 {
            titleLabel.text = "Your Order"
        } else if itemCount == 1 {
            titleLabel.text = "1 Item"
        } else {
            titleLabel.text = "\(itemCount) Items"
        }

        // Animate the badge if items were added
        if itemCount > 0 {
            animateBadge()
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    // MARK: - Animations

    private func animateBadge() {
        itemCountLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: .curveEaseOut) {
            self.itemCountLabel.transform = .identity
        }
    }

    // MARK: - Actions

    @objc private func viewCartTapped() {
        guard !isEmpty else { return }
        delegate?.orderSummaryViewDidTapViewCart(self)
    }

    @objc private func checkoutTapped() {
        guard !isEmpty else { return }
        delegate?.orderSummaryViewDidTapCheckout(self)
    }

    @objc private func cartAreaTapped() {
        guard !isEmpty else { return }
        delegate?.orderSummaryViewDidTapViewCart(self)
    }
}