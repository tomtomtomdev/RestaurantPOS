//
//  UIColor+Theme.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

extension UIColor {

    /// Theme colors for the Restaurant POS app
    struct Theme {
        /// Primary brand color
        static let primary = UIColor.systemBlue

        /// Secondary accent color
        static let secondary = UIColor.systemGreen

        /// Background color for views
        static let background = UIColor.systemBackground

        /// Secondary background color
        static let secondaryBackground = UIColor.secondarySystemBackground

        /// Text color for primary content
        static let primaryText = UIColor.label

        /// Text color for secondary content
        static let secondaryText = UIColor.secondaryLabel

        /// Error or destructive action color
        static let error = UIColor.systemRed

        /// Success color
        static let success = UIColor.systemGreen

        /// Warning color
        static let warning = UIColor.systemOrange
    }
}
