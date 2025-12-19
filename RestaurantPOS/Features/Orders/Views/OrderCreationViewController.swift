//
//  OrderCreationViewController.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit
import Combine

// MARK: - Order Creation View Controller

class OrderCreationViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: OrderCreationViewModel
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search menu items..."
        controller.searchBar.searchBarStyle = .minimal
        return controller
    }()

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.identifier)
        return collectionView
    }()

    private lazy var menuCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MenuItemCollectionViewCell.self, forCellWithReuseIdentifier: MenuItemCollectionViewCell.identifier)
        return collectionView
    }()

    private lazy var cartSummaryView: OrderSummaryView = {
        let view = OrderSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "fork.knife")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Menu Items"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .systemGray
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Try adjusting your search or filters"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray2
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        view.addSubview(imageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])

        return view
    }()

    // Loading indicator
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    init(viewModel: OrderCreationViewModel? = nil) {
        self.viewModel = viewModel ?? OrderCreationViewModel()
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
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup Methods

    private func setupUI() {
        title = "Create Order"
        view.backgroundColor = .systemBackground

        // Navigation setup
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(categoryCollectionView)
        contentView.addSubview(menuCollectionView)
        contentView.addSubview(emptyStateView)
        contentView.addSubview(loadingIndicator)

        // Cart summary is pinned to bottom of main view, not in scroll view
        view.addSubview(cartSummaryView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cartSummaryView.topAnchor),

            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Category collection view
            categoryCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            categoryCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 50),

            // Menu collection view
            menuCollectionView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 8),
            menuCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            menuCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            menuCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Empty state view
            emptyStateView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 40),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Cart summary view - pinned to bottom
            cartSummaryView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cartSummaryView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cartSummaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cartSummaryView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func setupBindings() {
        // Loading state
        viewModel.isLoading.bind { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.menuCollectionView.isHidden = true
                    self?.emptyStateView.isHidden = true
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.updateContentVisibility()
                }
            }
        }

        // Error handling
        viewModel.error.bind { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showErrorAlert(error)
                }
            }
        }
    }

    private func loadData() {
        viewModel.viewDidLoad()
        viewModel.loadMenu()

        // Refresh UI after data loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateContentVisibility()
            self.updateCartSummary()
            self.refreshCollectionViews()
        }
    }

    private func updateContentVisibility() {
        let hasItems = !viewModel.filteredMenuItems.isEmpty
        let isLoading = viewModel.isLoading.value

        menuCollectionView.isHidden = !hasItems || isLoading
        emptyStateView.isHidden = hasItems || isLoading
    }

    private func updateCartSummary() {
        cartSummaryView.configure(
            itemCount: viewModel.itemCount,
            subtotal: viewModel.subtotal,
            tax: viewModel.tax,
            total: viewModel.totalAmount,
            isEmpty: viewModel.isEmpty
        )
    }

    private func refreshCollectionViews() {
        categoryCollectionView.reloadData()
        menuCollectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true)
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

    private func showItemDetails(_ item: MenuItem) {
        let alert = UIAlertController(
            title: item.name,
            message: item.description ?? "No description available",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Add to Cart", style: .default) { [weak self] _ in
            self?.viewModel.addToCart(menuItem: item, quantity: 1)
        })

        alert.addAction(UIAlertAction(title: "Customize", style: .default) { [weak self] _ in
            self?.showCustomizationSheet(for: item)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func showCustomizationSheet(for item: MenuItem) {
        let sheet = UIAlertController(
            title: "Customize \(item.name)",
            message: "Select modifiers and quantity",
            preferredStyle: .actionSheet
        )

        // Add modifiers if available
        for modifier in item.modifiers {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            let priceString = formatter.string(from: NSDecimalNumber(decimal: modifier.price)) ?? "$0.00"

            let action = UIAlertAction(
                title: "\(modifier.name) (+\(priceString))",
                style: .default
            ) { [weak self] _ in
                self?.viewModel.addToCart(
                    menuItem: item,
                    quantity: 1,
                    modifiers: [modifier]
                )
            }
            sheet.addAction(action)
        }

        // Quantity options
        for quantity in [1, 2, 3] {
            let action = UIAlertAction(
                title: "Quantity: \(quantity)",
                style: .default
            ) { [weak self] _ in
                self?.viewModel.addToCart(menuItem: item, quantity: quantity)
            }
            sheet.addAction(action)
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = menuCollectionView
            popover.sourceRect = CGRect(x: menuCollectionView.bounds.midX, y: menuCollectionView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(sheet, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension OrderCreationViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        viewModel.searchItems(searchText)
    }
}

// MARK: - UICollectionViewDataSource

extension OrderCreationViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return viewModel.menuCategories.count + 1 // +1 for "All Categories"
        } else {
            return viewModel.filteredMenuItems.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.identifier, for: indexPath) as! CategoryCollectionViewCell

            if indexPath.item == 0 {
                // "All Categories" cell
                cell.configure(
                    name: "All",
                    isSelected: viewModel.selectedCategory == nil
                )
            } else {
                let category = viewModel.menuCategories[indexPath.item - 1]
                cell.configure(
                    name: category.name,
                    isSelected: viewModel.selectedCategory?.id == category.id
                )
            }

            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MenuItemCollectionViewCell.identifier, for: indexPath) as! MenuItemCollectionViewCell

            let menuItem = viewModel.filteredMenuItems[indexPath.item]
            cell.configure(with: menuItem)

            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension OrderCreationViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            if indexPath.item == 0 {
                // "All Categories" selected
                viewModel.filterByCategory(nil)
            } else {
                let category = viewModel.menuCategories[indexPath.item - 1]
                viewModel.filterByCategory(category)
            }
        } else {
            let menuItem = viewModel.filteredMenuItems[indexPath.item]
            showItemDetails(menuItem)
        }

        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension OrderCreationViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoryCollectionView {
            let name: String
            if indexPath.item == 0 {
                name = "All"
            } else {
                name = viewModel.menuCategories[indexPath.item - 1].name
            }

            let width = name.size(withAttributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ]).width + 32

            return CGSize(width: width, height: 40)
        } else {
            let padding: CGFloat = 32 * 2 // Left and right padding
            let spacing: CGFloat = 12 * (2 - 1) // Between items
            let availableWidth = collectionView.frame.width - padding - spacing

            let itemWidth = availableWidth / 2
            return CGSize(width: itemWidth, height: 280)
        }
    }
}

// MARK: - OrderSummaryViewDelegate

extension OrderCreationViewController: OrderSummaryViewDelegate {
    func orderSummaryViewDidTapViewCart(_ view: OrderSummaryView) {
        // TODO: Present cart view controller
        print("View cart tapped")
    }

    func orderSummaryViewDidTapCheckout(_ view: OrderSummaryView) {
        guard !viewModel.isEmpty else {
            let alert = UIAlertController(
                title: "Empty Cart",
                message: "Please add items to your cart before checking out.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // TODO: Present checkout flow
        print("Checkout tapped - creating order...")

        viewModel.createOrder()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.showErrorAlert(error)
                    }
                },
                receiveValue: { [weak self] order in
                    let alert = UIAlertController(
                        title: "Order Created",
                        message: "Order \(order.orderNumber) has been created successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Great!", style: .default) { _ in
                        self?.closeTapped()
                    })
                    self?.present(alert, animated: true)
                }
            )
            .store(in: &cancellables)
    }
}