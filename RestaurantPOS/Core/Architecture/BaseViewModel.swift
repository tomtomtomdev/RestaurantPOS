//
//  BaseViewModel.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation

/// Base class for all ViewModels providing common functionality
open class BaseViewModel: ViewModelProtocol {

    // MARK: - Properties

    /// Observable loading state
    let isLoading = Observable<Bool>(false)

    /// Observable error state
    let error = Observable<Error?>(nil)

    /// Observable alert message
    let alertMessage = Observable<String?>(nil)

    // MARK: - ViewModelProtocol

    public func viewDidLoad() {
        // Subclasses can override
    }

    public func refresh() {
        // Subclasses can override
    }

    // MARK: - Protected Methods

    /// Sets the loading state
    /// - Parameter loading: Whether loading is in progress
    func setLoading(_ loading: Bool) {
        isLoading.value = loading
    }

    /// Sets an error
    /// - Parameter error: The error to set
    func setError(_ error: Error) {
        self.error.value = error
        self.alertMessage.value = error.localizedDescription
    }

    /// Clears the current error
    func clearError() {
        self.error.value = nil
        self.alertMessage.value = nil
    }

    /// Shows an alert message
    /// - Parameter message: The message to display
    func showAlert(_ message: String) {
        self.alertMessage.value = message
    }

    /// Clears the alert message
    func clearAlert() {
        self.alertMessage.value = nil
    }
}
