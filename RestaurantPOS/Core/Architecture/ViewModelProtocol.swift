//
//  ViewModelProtocol.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation

/// Protocol defining the base requirements for all ViewModels
public protocol ViewModelProtocol {

    /// Called when the ViewModel should start its initial operations
    func viewDidLoad()

    /// Called when the ViewModel should refresh its data
    func refresh()
}

public extension ViewModelProtocol {

    /// Default implementation of viewDidLoad (optional)
    func viewDidLoad() {
        // Default empty implementation
    }

    /// Default implementation of refresh (optional)
    func refresh() {
        // Default empty implementation
    }
}
