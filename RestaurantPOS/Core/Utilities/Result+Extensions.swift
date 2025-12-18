//
//  Result+Extensions.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import Foundation

extension Result {

    /// Returns the success value if available, nil otherwise
    var successValue: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    /// Returns the failure error if available, nil otherwise
    var failureError: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    /// Returns true if the result is a success
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Returns true if the result is a failure
    var isFailure: Bool {
        return !isSuccess
    }
}
