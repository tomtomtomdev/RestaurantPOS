//
//  BaseViewModelTests.swift
//  RestaurantPOSTests
//
//  Created by Claude Code
//

import XCTest
@testable import RestaurantPOS

final class BaseViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: BaseViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = BaseViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInitialState() {
        // Then
        XCTAssertFalse(sut.isLoading.value, "Initial loading state should be false")
        XCTAssertNil(sut.error.value, "Initial error should be nil")
        XCTAssertNil(sut.alertMessage.value, "Initial alert message should be nil")
    }

    func testObservableBinding() {
        // Given
        let expectation = self.expectation(description: "Observable callback called")
        var receivedValue: Bool?

        // When
        sut.isLoading.bind { value in
            receivedValue = value
            if value {
                expectation.fulfill()
            }
        }

        sut.isLoading.value = true

        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedValue, true, "Observable should notify listener of value change")
    }

    func testSetLoadingState() {
        // Given
        var loadingStates: [Bool] = []
        sut.isLoading.bind { loadingStates.append($0) }

        // When
        sut.setLoading(true)
        sut.setLoading(false)

        // Then - Wait for async updates
        let expectation = self.expectation(description: "Loading state updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(loadingStates.contains(true), "Loading states should include true")
        XCTAssertTrue(loadingStates.contains(false), "Loading states should include false")
    }

    func testSetError() {
        // Given
        let testError = NSError(domain: "test", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        var receivedError: Error?
        var receivedAlertMessage: String?

        sut.error.bind { receivedError = $0 }
        sut.alertMessage.bind { receivedAlertMessage = $0 }

        // When
        sut.setError(testError)

        // Then - Wait for async updates
        let expectation = self.expectation(description: "Error updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(receivedError, "Error should be set")
        XCTAssertEqual(receivedAlertMessage, "Test error", "Alert message should match error description")
    }

    func testClearError() {
        // Given
        let testError = NSError(domain: "test", code: 123, userInfo: nil)
        sut.setError(testError)

        // When
        sut.clearError()

        // Then - Wait for async updates
        let expectation = self.expectation(description: "Error cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertNil(sut.error.value, "Error should be cleared")
        XCTAssertNil(sut.alertMessage.value, "Alert message should be cleared")
    }

    func testShowAndClearAlert() {
        // Given
        var receivedMessages: [String?] = []
        sut.alertMessage.bind { receivedMessages.append($0) }

        // When
        sut.showAlert("Test message")

        // Wait for update
        let expectation1 = self.expectation(description: "Alert shown")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(sut.alertMessage.value, "Test message", "Alert message should be set")

        // When
        sut.clearAlert()

        // Wait for update
        let expectation2 = self.expectation(description: "Alert cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation2.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertNil(sut.alertMessage.value, "Alert message should be cleared")
    }
}
