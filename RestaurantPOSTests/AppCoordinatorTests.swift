//
//  AppCoordinatorTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
@testable import RestaurantPOS

final class AppCoordinatorTests: XCTestCase {

    // MARK: - Properties

    var sut: AppCoordinator!
    var navigationController: UINavigationController!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        sut = AppCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        sut = nil
        navigationController = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testCoordinatorInitialization() {
        // Given/When
        let coordinator = AppCoordinator(navigationController: navigationController)

        // Then
        XCTAssertNotNil(coordinator, "Coordinator should be initialized")
    }

    func testStartShowsPlaceholderViewController() {
        // When
        sut.start()

        // Then
        XCTAssertEqual(
            navigationController.viewControllers.count,
            1,
            "Navigation controller should have exactly one view controller"
        )
        XCTAssertNotNil(
            navigationController.viewControllers.first,
            "Navigation controller should have a root view controller"
        )
    }

    func testNavigationBarConfiguration() {
        // When
        sut.start()

        // Then
        XCTAssertTrue(
            navigationController.navigationBar.prefersLargeTitles,
            "Navigation bar should prefer large titles"
        )
        XCTAssertEqual(
            navigationController.navigationBar.tintColor,
            .systemBlue,
            "Navigation bar tint color should be system blue"
        )
    }
}
