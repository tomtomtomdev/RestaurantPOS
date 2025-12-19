import UIKit
import Combine

class OrderListViewController: UIViewController {
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderListTableViewCell.self, forCellReuseIdentifier: OrderListTableViewCell.identifier)
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search orders..."
        controller.searchBar.searchBarStyle = .minimal
        return controller
    }()

    private lazy var filterBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "line.horizontal.3.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        return item
    }()

    private lazy var sortBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(sortButtonTapped)
        )
        return item
    }()

    private let refreshControl = UIRefreshControl()

    // MARK: - Loading Views
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = .systemBlue
        return indicator
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "list.bullet.rectangle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Orders"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Orders will appear here once they're created"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        return view
    }()

    // MARK: - Properties
    private let viewModel: OrderListViewModel
    private var cancellables = Set<AnyCancellable>()
    private var isInitialLoad = true

    // MARK: - Statistics View
    private let statisticsContainerView: UIView = {
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

    private let revenueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization
    init(viewModel: OrderListViewModel) {
        self.viewModel = viewModel
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
        setupRefreshControl()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isInitialLoad {
            isInitialLoad = false
            viewModel.refresh()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Orders"
        view.backgroundColor = .systemGroupedBackground

        // Navigation
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.rightBarButtonItems = [sortBarButtonItem, filterBarButtonItem]

        // Add subviews
        view.addSubview(tableView)
        view.addSubview(statisticsContainerView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateView)

        // Setup statistics view
        statisticsContainerView.addSubview(revenueLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Statistics container
            statisticsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statisticsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statisticsContainerView.heightAnchor.constraint(equalToConstant: 60),

            revenueLabel.centerXAnchor.constraint(equalTo: statisticsContainerView.centerXAnchor),
            revenueLabel.centerYAnchor.constraint(equalTo: statisticsContainerView.centerYAnchor),

            // Table view
            tableView.topAnchor.constraint(equalTo: statisticsContainerView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: statisticsContainerView.bottomAnchor, constant: 20),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshOrders), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    private func setupBindings() {
        // Use timer to simulate property observation for demo purposes
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateEmptyState()
                self?.tableView.reloadData()
                self?.updateStatistics()
            }
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        let isEmpty = viewModel.isEmpty
        let hasNoResults = !viewModel.searchText.isEmpty && viewModel.filteredOrders.isEmpty

        emptyStateView.isHidden = !isEmpty

        if hasNoResults {
            // Update empty state for no search results
            if let titleLabel = emptyStateView.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "No Orders" }) as? UILabel {
                titleLabel.text = "No Results"
            }
            if let subtitleLabel = emptyStateView.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text?.contains("created") == true }) as? UILabel {
                subtitleLabel.text = "No orders found matching your search"
            }
        } else {
            // Reset empty state
            if let titleLabel = emptyStateView.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text == "No Results" }) as? UILabel {
                titleLabel.text = "No Orders"
            }
            if let subtitleLabel = emptyStateView.subviews.first(where: { $0 is UILabel && ($0 as? UILabel)?.text?.contains("matching") == true }) as? UILabel {
                subtitleLabel.text = "Orders will appear here once they're created"
            }
        }
    }

    private func updateStatistics() {
        let totalOrders = viewModel.totalOrdersCount
        let completedOrders = viewModel.completedOrdersCount
        let revenue = viewModel.formattedTotalRevenue

        if totalOrders > 0 {
            revenueLabel.text = "\(completedOrders)/\(totalOrders) orders • \(revenue) revenue"
        } else {
            revenueLabel.text = "No orders yet"
        }
    }

    // MARK: - Actions
    @objc private func refreshOrders() {
        viewModel.refresh()
    }

    @objc private func filterButtonTapped() {
        showFilterOptions()
    }

    @objc private func sortButtonTapped() {
        showSortOptions()
    }

    private func showError(_ error: OrderError) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showFilterOptions() {
        let alert = UIAlertController(title: "Filter by Status", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = filterBarButtonItem

        // Clear filter action
        alert.addAction(UIAlertAction(title: "All Orders", style: .default) { [weak self] _ in
            self?.viewModel.selectedStatuses.removeAll()
        })

        // Status filter actions
        for status in viewModel.statusOptions {
            let isSelected = viewModel.selectedStatuses.contains(status)
            let title = isSelected ? "✓ \(status.displayName)" : status.displayName

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.toggleStatus(status)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showSortOptions() {
        let alert = UIAlertController(title: "Sort Orders", message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.barButtonItem = sortBarButtonItem

        for option in viewModel.sortOptions {
            let isSelected = viewModel.selectedSortOption == option
            let title = isSelected ? "✓ \(option.displayName)" : option.displayName

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.selectedSortOption = option
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension OrderListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredOrdersCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderListTableViewCell.identifier, for: indexPath) as! OrderListTableViewCell
        let order = viewModel.filteredOrders[indexPath.row]
        cell.configure(with: order)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension OrderListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if let cell = tableView.cellForRow(at: indexPath) as? OrderListTableViewCell {
            cell.animateSelection()
        }

        let order = viewModel.filteredOrders[indexPath.row]
        // TODO: Navigate to order details
        print("Selected order: \(order.orderNumber)")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.alpha = 0
        cell.transform = CGAffineTransform(translationX: 0, y: 50)

        UIView.animate(
            withDuration: 0.5,
            delay: 0.05 * Double(indexPath.row),
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            cell.alpha = 1
            cell.transform = .identity
        }
    }
}

// MARK: - UISearchResultsUpdating
extension OrderListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text ?? ""
    }
}

