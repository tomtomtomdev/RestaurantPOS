//
//  Observable.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation

/// A generic observable wrapper for data binding between ViewModels and Views
public final class Observable<T> {

    // MARK: - Properties

    /// The current value
    var value: T {
        didSet {
            DispatchQueue.main.async {
                self.listener?(self.value)
            }
        }
    }

    /// The listener closure called when value changes
    private var listener: ((T) -> Void)?

    // MARK: - Initialization

    /// Initialize with an initial value
    /// - Parameter value: The initial value
    init(_ value: T) {
        self.value = value
    }

    // MARK: - Public Methods

    /// Bind a listener to be called when the value changes
    /// - Parameter listener: The closure to call with the new value
    func bind(_ listener: @escaping (T) -> Void) {
        self.listener = listener
        // Immediately call listener with current value
        DispatchQueue.main.async {
            listener(self.value)
        }
    }

    /// Remove the current listener
    func unbind() {
        listener = nil
    }
}
