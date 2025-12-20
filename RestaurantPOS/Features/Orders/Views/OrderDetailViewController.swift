//
//  OrderDetailViewController.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit
import Combine

// MARK: - Order Detail View Controller

class OrderDetailViewController: UIViewController {

    // MARK: - Properties

    private let order: Order
    private let orderRepository: OrderRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // Payment properties
    private let paymentService: PaymentServiceProtocol
    private lazy var paymentButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Process Payment", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(paymentButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.refreshControl = UIRefreshControl()
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var headerView: OrderDetailHeaderView = {
        let view = OrderDetailHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var statusCardView: OrderStatusCardView = {
        let view = OrderStatusCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var itemsSectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Order Items"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var itemsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(OrderItemTableViewCell.self, forCellReuseIdentifier: OrderItemTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    private lazy var timelineSectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Order Timeline"
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private lazy var timelineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var totalSummaryView: OrderTotalSummaryView = {
        let view = OrderTotalSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(
        order: Order,
        orderRepository: OrderRepositoryProtocol = OrderRepository(databaseService: CoreDataStack.shared),
        paymentService: PaymentServiceProtocol = PaymentService(
            paymentRepository: PaymentRepository(databaseService: CoreDataStack.shared),
            orderRepository: OrderRepository(databaseService: CoreDataStack.shared)
        )
    ) {
        self.order = order
        self.orderRepository = orderRepository
        self.paymentService = paymentService
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
        refreshOrder()
    }

    // MARK: - Setup Methods

    private func setupUI() {
        title = "Order Details"
        view.backgroundColor = .systemBackground

        // Navigation setup
        navigationItem.largeTitleDisplayMode = .never

        setupSubviews()
        setupConstraints()
        setupRefreshControl()
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(headerView)
        contentView.addSubview(statusCardView)
        contentView.addSubview(itemsSectionLabel)
        contentView.addSubview(itemsTableView)
        contentView.addSubview(timelineSectionLabel)
        contentView.addSubview(timelineStackView)
        contentView.addSubview(totalSummaryView)
        contentView.addSubview(paymentButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Status card view
            statusCardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            statusCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Items section label
            itemsSectionLabel.topAnchor.constraint(equalTo: statusCardView.bottomAnchor, constant: 24),
            itemsSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemsSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Items table view
            itemsTableView.topAnchor.constraint(equalTo: itemsSectionLabel.bottomAnchor, constant: 8),
            itemsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Timeline section label
            timelineSectionLabel.topAnchor.constraint(equalTo: itemsTableView.bottomAnchor, constant: 24),
            timelineSectionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timelineSectionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Timeline stack view
            timelineStackView.topAnchor.constraint(equalTo: timelineSectionLabel.bottomAnchor, constant: 8),
            timelineStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timelineStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Total summary view
            totalSummaryView.topAnchor.constraint(equalTo: timelineStackView.bottomAnchor, constant: 24),
            totalSummaryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            totalSummaryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Payment button
            paymentButton.topAnchor.constraint(equalTo: totalSummaryView.bottomAnchor, constant: 24),
            paymentButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            paymentButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            paymentButton.heightAnchor.constraint(equalToConstant: 56),
            paymentButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }

    private func setupRefreshControl() {
        scrollView.refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }

    private func setupBindings() {
        // Add any reactive bindings if needed
    }

    private func configureData() {
        headerView.configure(with: order)
        statusCardView.configure(with: order)
        totalSummaryView.configure(with: order)
        setupTimeline()
        updatePaymentButtonVisibility()

        // Update table view height based on content
        DispatchQueue.main.async {
            self.updateTableViewHeight()
        }
    }

    private func updatePaymentButtonVisibility() {
        // Show payment button only when order is ready and not yet paid
        let canShowPaymentButton = order.status == .ready

        DispatchQueue.main.async {
            self.paymentButton.isHidden = !canShowPaymentButton

            if canShowPaymentButton {
                self.paymentButton.setTitle("Pay \(order.formattedTotal)", for: .normal)
            }
        }
    }

    private func setupTimeline() {
        // Clear existing timeline items
        timelineStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add timeline events
        let createdAtEvent = OrderTimelineEvent(
            type: .created,
            date: order.createdAt,
            title: "Order Created",
            description: "Order \(order.orderNumber) was placed"
        )

        let currentStatusEvent = OrderTimelineEvent(
            type: .statusChanged,
            date: order.updatedAt,
            title: order.status.displayName,
            description: "Order status was updated to \(order.status.displayName.lowercased())"
        )

        timelineStackView.addArrangedSubview(createTimelineView(for: createdAtEvent))
        timelineStackView.addArrangedSubview(createTimelineView(for: currentStatusEvent))

        // Add completion event if completed
        if let completedAt = order.completedAt {
            let completedEvent = OrderTimelineEvent(
                type: .completed,
                date: completedAt,
                title: "Order Completed",
                description: "Order was successfully completed"
            )
            timelineStackView.addArrangedSubview(createTimelineView(for: completedEvent))
        }
    }

    private func createTimelineView(for event: OrderTimelineEvent) -> OrderTimelineEventView {
        let view = OrderTimelineEventView()
        view.configure(with: event)
        return view
    }

    private func updateTableViewHeight() {
        let itemCount = order.items.count
        let cellHeight: CGFloat = 80
        let headerHeight: CGFloat = 40
        let totalHeight = CGFloat(itemCount) * cellHeight + headerHeight

        itemsTableView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }

    // MARK: - Actions

    @objc private func refreshData() {
        refreshOrder()
        scrollView.refreshControl?.endRefreshing()
    }

    private func refreshOrder() {
        orderRepository.getOrder(id: order.id)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.showErrorAlert(error)
                        }
                    }
                },
                receiveValue: { [weak self] refreshedOrder in
                    if let order = refreshedOrder {
                        DispatchQueue.main.async {
                            self?.updateOrder(order)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func updateOrder(_ updatedOrder: Order) {
        // Update UI with refreshed order data
        headerView.configure(with: updatedOrder)
        statusCardView.configure(with: updatedOrder)
        totalSummaryView.configure(with: updatedOrder)
        setupTimeline()
        itemsTableView.reloadData()
        updateTableViewHeight()
        updatePaymentButtonVisibility()
    }

    // MARK: - Payment Actions

    @objc private func paymentButtonTapped() {
        let paymentViewController = PaymentViewController(order: order, paymentService: paymentService)
        let navigationController = UINavigationController(rootViewController: paymentViewController)

        // Present payment view controller modally
        present(navigationController, animated: true)
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

    private func showStatusChangeConfirmation() {
        let possibleStatuses = order.status.canTransitionTo

        guard !possibleStatuses.isEmpty else {
            let alert = UIAlertController(
                title: "No Status Change Available",
                message: "This order is in its final state.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: "Change Order Status",
            message: "Select new status:",
            preferredStyle: .actionSheet
        )

        for newStatus in possibleStatuses {
            let action = UIAlertAction(title: newStatus.displayName, style: .default) { [weak self] _ in
                self?.changeOrderStatus(to: newStatus)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = statusCardView
            popover.sourceRect = statusCardView.bounds
        }

        present(alert, animated: true)
    }

    private func changeOrderStatus(to newStatus: OrderStatus) {
        let result = order.updateStatus(newStatus)

        switch result {
        case .success(let updatedOrder):
            orderRepository.updateOrder(updatedOrder)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            DispatchQueue.main.async {
                                self?.showErrorAlert(error)
                            }
                        }
                    },
                    receiveValue: { [weak self] savedOrder in
                        DispatchQueue.main.async {
                            self?.updateOrder(savedOrder)

                            let successAlert = UIAlertController(
                                title: "Status Updated",
                                message: "Order status changed to \(newStatus.displayName)",
                                preferredStyle: .alert
                            )
                            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(successAlert, animated: true)
                        }
                    }
                )
                .store(in: &cancellables)

        case .failure(let error):
            showErrorAlert(error)
        }
    }
}

// MARK: - UITableViewDataSource

extension OrderDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return order.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderItemTableViewCell.identifier, for: indexPath) as! OrderItemTableViewCell

        let orderItem = order.items[indexPath.row]
        cell.configure(with: orderItem)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension OrderDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let orderItem = order.items[indexPath.row]
        showItemDetails(for: orderItem)
    }

    private func showItemDetails(for orderItem: OrderItem) {
        let alert = UIAlertController(
            title: orderItem.name,
            message: """
            Quantity: \(orderItem.quantity)
            Price per item: \(formatCurrency(orderItem.unitPrice))
            Modifiers: \(orderItem.modifiers.isEmpty ? "None" : orderItem.modifiers.joined(separator: ", "))
            Special Instructions: \(orderItem.specialInstructions ?? "None")
            """,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
}

// MARK: - OrderStatusCardViewDelegate

extension OrderDetailViewController: OrderStatusCardViewDelegate {
    func orderStatusCardViewDidTapStatusButton(_ view: OrderStatusCardView) {
        showStatusChangeConfirmation()
    }

    func orderStatusCardViewDidTapCancelButton(_ view: OrderStatusCardView) {
        let alert = UIAlertController(
            title: "Cancel Order",
            message: "Are you sure you want to cancel this order?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Yes, Cancel", style: .destructive) { [weak self] _ in
            self?.cancelOrder()
        })

        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(alert, animated: true)
    }

    private func cancelOrder() {
        let result = order.updateStatus(.cancelled)

        switch result {
        case .success(let updatedOrder):
            orderRepository.updateOrder(updatedOrder)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            DispatchQueue.main.async {
                                self?.showErrorAlert(error)
                            }
                        }
                    },
                    receiveValue: { [weak self] savedOrder in
                        DispatchQueue.main.async {
                            self?.updateOrder(savedOrder)

                            let successAlert = UIAlertController(
                                title: "Order Cancelled",
                                message: "Order has been successfully cancelled",
                                preferredStyle: .alert
                            )
                            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                            self?.present(successAlert, animated: true)
                        }
                    }
                )
                .store(in: &cancellables)

        case .failure(let error):
            showErrorAlert(error)
        }
    }
}

// MARK: - Supporting Types

// MARK: - Order Timeline Event

struct OrderTimelineEvent {
    let type: TimelineEventType
    let date: Date
    let title: String
    let description: String

    enum TimelineEventType {
        case created
        case statusChanged
        case completed
        case cancelled

        var iconName: String {
            switch self {
            case .created:
                return "cart.fill"
            case .statusChanged:
                return "arrow.clockwise"
            case .completed:
                return "checkmark.circle.fill"
            case .cancelled:
                return "xmark.circle.fill"
            }
        }

        var iconColor: UIColor {
            switch self {
            case .created:
                return .systemBlue
            case .statusChanged:
                return .systemOrange
            case .completed:
                return .systemGreen
            case .cancelled:
                return .systemRed
            }
        }
    }
}