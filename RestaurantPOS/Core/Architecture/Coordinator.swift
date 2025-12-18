//
//  Coordinator.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

/// Protocol defining the base requirements for all Coordinators
protocol Coordinator: AnyObject {

    /// The navigation controller managed by this coordinator
    var navigationController: UINavigationController { get }

    /// Child coordinators managed by this coordinator
    var childCoordinators: [Coordinator] { get set }

    /// Starts the coordinator's flow
    func start()
}

extension Coordinator {

    /// Adds a child coordinator to the hierarchy
    /// - Parameter coordinator: The child coordinator to add
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    /// Removes a child coordinator from the hierarchy
    /// - Parameter coordinator: The child coordinator to remove
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    /// Removes all child coordinators
    func removeAllChildCoordinators() {
        childCoordinators.removeAll()
    }
}
