//
//  AppCoordinator.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

/// Main coordinator responsible for app-level navigation and flow
final class AppCoordinator {

    // MARK: - Properties

    private let navigationController: UINavigationController

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        configureNavigationBar()
    }

    // MARK: - Public Methods

    /// Starts the coordinator and displays the initial screen
    func start() {
        showPlaceholderScreen()
    }

    // MARK: - Private Methods

    private func configureNavigationBar() {
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .systemBlue
    }

    private func showPlaceholderScreen() {
        let placeholderVC = PlaceholderViewController()
        placeholderVC.title = "Restaurant POS"
        navigationController.setViewControllers([placeholderVC], animated: false)
    }
}

// MARK: - Placeholder View Controller

/// Temporary placeholder view controller for Phase 1
private class PlaceholderViewController: UIViewController {

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Restaurant POS\n\nUIKit Migration Complete ✓"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
