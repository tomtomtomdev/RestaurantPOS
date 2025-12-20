//
//  PaymentDetailViews.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Payment Card Details View

class PaymentCardDetailsView: UIView {

    // MARK: - Properties

    weak var delegate: PaymentCardDetailsViewDelegate?

    private let titleLabel = UILabel()
    private let cardNumberTextField = UITextField()
    private let cardholderNameTextField = UITextField()
    private let expirationStackView = UIStackView()
    private let expirationMonthTextField = UITextField()
    private let expirationYearTextField = UITextField()
    private let cvvTextField = UITextField()
    private let cardIconImageView = UIImageView()

    // MARK: - Computed Properties

    var cardNumber: String? {
        return cardNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cardholderName: String? {
        return cardholderNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var expirationMonth: String? {
        return expirationMonthTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var expirationYear: String? {
        return expirationYearTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var cvv: String? {
        return cvvTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
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
        addSubview(cardIconImageView)
        addSubview(cardNumberTextField)
        addSubview(cardholderNameTextField)
        addSubview(expirationStackView)
        addSubview(cvvTextField)

        setupLabels()
        setupTextFields()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Card Details"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label

        cardIconImageView.translatesAutoresizingMaskIntoConstraints = false
        cardIconImageView.image = UIImage(systemName: "creditcard")
        cardIconImageView.tintColor = .systemBlue
        cardIconImageView.contentMode = .scaleAspectFit
    }

    private func setupTextFields() {
        // Card number
        setupTextField(cardNumberTextField, placeholder: "Card Number", keyboardType: .numberPad)
        cardNumberTextField.tag = 1

        // Cardholder name
        setupTextField(cardholderNameTextField, placeholder: "Cardholder Name", keyboardType: .default)
        cardholderNameTextField.tag = 2

        // Expiration stack
        expirationStackView.translatesAutoresizingMaskIntoConstraints = false
        expirationStackView.axis = .horizontal
        expirationStackView.spacing = 12
        expirationStackView.distribution = .fillEqually

        setupTextField(expirationMonthTextField, placeholder: "MM", keyboardType: .numberPad)
        expirationMonthTextField.tag = 3

        setupTextField(expirationYearTextField, placeholder: "YY", keyboardType: .numberPad)
        expirationYearTextField.tag = 4

        expirationStackView.addArrangedSubview(expirationMonthTextField)
        expirationStackView.addArrangedSubview(expirationYearTextField)

        // CVV
        setupTextField(cvvTextField, placeholder: "CVV", keyboardType: .numberPad)
        cvvTextField.tag = 5
        cvvTextField.isSecureTextEntry = true
    }

    private func setupTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = .systemBackground
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.keyboardType = keyboardType
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
    }

    private func setupTargets() {
        cardNumberTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cardholderNameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        expirationMonthTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        expirationYearTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cvvTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),

            cardIconImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cardIconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            cardIconImageView.widthAnchor.constraint(equalToConstant: 24),
            cardIconImageView.heightAnchor.constraint(equalToConstant: 24),

            cardNumberTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            cardNumberTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardNumberTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            cardholderNameTextField.topAnchor.constraint(equalTo: cardNumberTextField.bottomAnchor, constant: 16),
            cardholderNameTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            cardholderNameTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            expirationStackView.topAnchor.constraint(equalTo: cardholderNameTextField.bottomAnchor, constant: 16),
            expirationStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            expirationStackView.widthAnchor.constraint(equalToConstant: 120),

            cvvTextField.topAnchor.constraint(equalTo: cardholderNameTextField.bottomAnchor, constant: 16),
            cvvTextField.leadingAnchor.constraint(equalTo: expirationStackView.trailingAnchor, constant: 12),
            cvvTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            bottomAnchor.constraint(equalTo: expirationStackView.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Actions

    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Format card number
        if textField.tag == 1 {
            formatCardNumber()
            updateCardIcon()
        }

        // Auto-advance from month to year
        if textField.tag == 3 && textField.text?.count == 2 {
            expirationYearTextField.becomeFirstResponder()
        }

        // Limit CVV length
        if textField.tag == 5 && textField.text?.count ?? 0 > 4 {
            textField.text = String(textField.text?.prefix(4) ?? "")
        }

        delegate?.paymentCardDetailsViewDidUpdate(self)
    }

    private func formatCardNumber() {
        guard var text = cardNumberTextField.text else { return }
        // Remove non-digit characters
        text = text.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Limit to 16 digits
        text = String(text.prefix(16))
        // Format with spaces
        var formatted = ""
        for (index, character) in text.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        cardNumberTextField.text = formatted
    }

    private func updateCardIcon() {
        guard let cardNumber = cardNumber?.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression) else {
            cardIconImageView.image = UIImage(systemName: "creditcard")
            return
        }

        let imageName: String
        if cardNumber.hasPrefix("4") {
            imageName = "creditcard" // Visa
        } else if cardNumber.hasPrefix("5") {
            imageName = "creditcard" // Mastercard
        } else if cardNumber.hasPrefix("3") {
            imageName = "creditcard" // Amex
        } else {
            imageName = "creditcard" // Default
        }

        cardIconImageView.image = UIImage(systemName: imageName)
    }
}

// MARK: - Payment Methods View

class PaymentMethodsView: UIView {

    // MARK: - Properties

    weak var delegate: PaymentMethodsViewDelegate?

    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private var paymentMethods: [PaymentMethod] = []

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
        addSubview(tableView)

        setupLabels()
        setupTableView()
        setupConstraints()
    }

    private func setupLabels() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Saved Payment Methods"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(PaymentMethodTableViewCell.self, forCellReuseIdentifier: PaymentMethodTableViewCell.identifier)

        // Add footer button for adding payment methods
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        let addButton = UIButton(type: .system)
        addButton.setTitle("+ Add Payment Method", for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addButton.addTarget(self, action: #selector(addPaymentMethodTapped), for: .touchUpInside)
        addButton.frame = CGRect(x: 16, y: 10, width: footerView.frame.width - 32, height: 44)
        footerView.addSubview(addButton)
        tableView.tableFooterView = footerView
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with methods: [PaymentMethod]) {
        self.paymentMethods = methods
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func addPaymentMethodTapped() {
        delegate?.paymentMethodsViewDidRequestAddPaymentMethod(self)
    }
}

// MARK: - Payment Method Table View Cell

class PaymentMethodTableViewCell: UITableViewCell {
    static let identifier = "PaymentMethodTableViewCell"

    private let cardIconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let selectionIndicator = UIImageView()

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
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardIconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(selectionIndicator)

        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        cardIconImageView.translatesAutoresizingMaskIntoConstraints = false
        cardIconImageView.image = UIImage(systemName: "creditcard")
        cardIconImageView.tintColor = .systemBlue
        cardIconImageView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel

        selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectionIndicator.image = UIImage(systemName: "checkmark.circle.fill")
        selectionIndicator.tintColor = .systemBlue
        selectionIndicator.contentMode = .scaleAspectFit
        selectionIndicator.isHidden = true
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            cardIconImageView.widthAnchor.constraint(equalToConstant: 24),
            cardIconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: cardIconImageView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionIndicator.leadingAnchor, constant: -12),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectionIndicator.leadingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            selectionIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 24),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Configuration

    func configure(with paymentMethod: PaymentMethod, isSelected: Bool = false) {
        titleLabel.text = paymentMethod.displayText

        if let masked = paymentMethod.maskedNumber {
            subtitleLabel.text = masked
        } else {
            subtitleLabel.text = paymentMethod.type.displayName
        }

        selectionIndicator.isHidden = !isSelected

        if paymentMethod.isDefault {
            accessoryType = .checkmark
        } else {
            accessoryType = .none
        }
    }
}

// MARK: - Protocols

protocol PaymentCardDetailsViewDelegate: AnyObject {
    func paymentCardDetailsViewDidUpdate(_ view: PaymentCardDetailsView)
}

protocol PaymentMethodsViewDelegate: AnyObject {
    func paymentMethodsView(_ view: PaymentMethodsView, didSelectPaymentMethod method: PaymentMethod)
    func paymentMethodsViewDidRequestAddPaymentMethod(_ view: PaymentMethodsView)
}

// MARK: - UITableView Delegate & DataSource

extension PaymentMethodsView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentMethods.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodTableViewCell.identifier, for: indexPath) as! PaymentMethodTableViewCell
        let method = paymentMethods[indexPath.row]
        cell.configure(with: method)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let method = paymentMethods[indexPath.row]
        delegate?.paymentMethodsView(self, didSelectPaymentMethod: method)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}