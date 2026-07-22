//
//  AppTheme.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 15/07/26.
//

import SwiftUI

enum AppTheme {
    
    // MARK: - Brand Colors
    static let primaryTeal = Color(red: 0.05, green: 0.43, blue: 0.37)
    static let deepNavy = Color(red: 0.04, green: 0.12, blue: 0.19)
    
    // MARK: - Semantic Colors
    static let incomeGreen = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let expenseRed = Color(red: 0.91, green: 0.30, blue: 0.24)
    static let warningAmber = Color(red: 0.95, green: 0.65, blue: 0.15)
    
    // MARK: - Text
    static let textSecondary = Color.secondary
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryTeal, deepNavy],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.5, blue: 0.45),
                 Color(red: 0.04, green: 0.35, blue: 0.35)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let balanceCardGradient = LinearGradient(
        colors: [Color(red: 0.06, green: 0.48, blue: 0.42),
                 Color(red: 0.05, green: 0.2, blue: 0.28)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Surfaces
    static let cardBackground = Color(.systemBackground)
    static let fieldBackground = Color(.systemGray6)
}
