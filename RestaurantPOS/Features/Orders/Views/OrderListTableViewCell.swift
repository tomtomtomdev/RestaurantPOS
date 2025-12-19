import UIKit

class OrderListTableViewCell: UITableViewCell {
    static let identifier = "OrderListTableViewCell"

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let statusView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let orderNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let itemsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let itemCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let totalAmountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.textAlignment = .right
        return label
    }()

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
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(statusView)
        statusView.addSubview(statusLabel)
        containerView.addSubview(orderNumberLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(itemsLabel)
        containerView.addSubview(itemCountLabel)
        containerView.addSubview(totalAmountLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Status view
            statusView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statusView.widthAnchor.constraint(equalToConstant: 80),
            statusView.heightAnchor.constraint(equalToConstant: 24),

            // Status label
            statusLabel.centerXAnchor.constraint(equalTo: statusView.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusView.centerYAnchor),

            // Order number label
            orderNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            orderNumberLabel.leadingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: 12),
            orderNumberLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),

            // Time label
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            timeLabel.trailingAnchor.constraint(equalTo: totalAmountLabel.leadingAnchor, constant: -12),

            // Total amount label
            totalAmountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            totalAmountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Items label
            itemsLabel.topAnchor.constraint(equalTo: orderNumberLabel.bottomAnchor, constant: 8),
            itemsLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            itemsLabel.trailingAnchor.constraint(equalTo: itemCountLabel.leadingAnchor, constant: -8),

            // Item count label
            itemCountLabel.centerYAnchor.constraint(equalTo: itemsLabel.centerYAnchor),
            itemCountLabel.trailingAnchor.constraint(equalTo: totalAmountLabel.trailingAnchor)
        ])

        // Set content hugging priorities separately
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        itemCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    // MARK: - Configuration
    func configure(with order: OrderListItem) {
        orderNumberLabel.text = order.orderNumber
        timeLabel.text = order.timeElapsed
        itemsLabel.text = order.itemsSummary
        itemCountLabel.text = "\(order.itemCount) item\(order.itemCount != 1 ? "s" : "")"
        totalAmountLabel.text = order.formattedTotalAmount

        configureStatus(order.status)
        updateLayoutForItems()
    }

    private func configureStatus(_ status: OrderStatus) {
        statusLabel.text = status.displayName

        switch status {
        case .pending:
            statusView.backgroundColor = UIColor.systemOrange
        case .inProgress:
            statusView.backgroundColor = UIColor.systemBlue
        case .ready:
            statusView.backgroundColor = UIColor.systemGreen
        case .completed:
            statusView.backgroundColor = UIColor.systemGray
        case .cancelled:
            statusView.backgroundColor = UIColor.systemRed
        }
    }

    private func updateLayoutForItems() {
        // Adjust the label's number of lines based on content length
        if itemsLabel.text?.count ?? 0 > 50 {
            itemsLabel.numberOfLines = 2
        } else {
            itemsLabel.numberOfLines = 1
        }
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        orderNumberLabel.text = nil
        timeLabel.text = nil
        itemsLabel.text = nil
        itemCountLabel.text = nil
        totalAmountLabel.text = nil
        statusLabel.text = nil
        itemsLabel.numberOfLines = 1
    }

    // MARK: - Animation
    func animateSelection() {
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }
    }
}

// MARK: - Preview Support
#if DEBUG
import SwiftUI

struct OrderListTableViewCellPreview: PreviewProvider {
    static var previews: some View {
        UIViewPreview {
            let cell = OrderListTableViewCell(style: .default, reuseIdentifier: nil)
            let order = OrderListItem(
                orderNumber: "ORD-123",
                status: .inProgress,
                itemCount: 3,
                totalAmount: 45.99,
                createdAt: Date(),
                items: [
                    OrderItem(name: "Classic Burger", quantity: 1, unitPrice: 12.99),
                    OrderItem(name: "French Fries", quantity: 1, unitPrice: 4.99),
                    OrderItem(name: "Coca Cola", quantity: 1, unitPrice: 2.99)
                ]
            )
            cell.configure(with: order)
            return cell
        }
        .previewLayout(.fixed(width: 375, height: 100))
        .padding()
    }
}
#endif