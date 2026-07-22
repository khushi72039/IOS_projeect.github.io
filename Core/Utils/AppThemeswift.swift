import SwiftUI

enum AppTheme {
    
    // MARK: - Primary Brand Color (Adaptive)
    static let primaryIndigo = Color(
        light: Color(red: 0.11, green: 0.16, blue: 0.42),   // Deep Sapphire (light mode)
        dark: Color(red: 0.45, green: 0.52, blue: 0.92)      // Bright Sapphire (dark mode)
    )
    
    static let deepBackground = Color(
        light: Color(red: 0.97, green: 0.97, blue: 0.98),
        dark: Color(red: 0.05, green: 0.06, blue: 0.11)
    )
    
    // MARK: - Copper/Gold Accent (CTA buttons - premium feel)
    static let amberStart = Color(red: 0.80, green: 0.58, blue: 0.15)
    static let amberEnd = Color(red: 0.68, green: 0.42, blue: 0.08)
    
    // MARK: - Semantic Colors
    static let incomeGreen = Color(red: 0.12, green: 0.69, blue: 0.45)
    static let expenseRed = Color(red: 0.91, green: 0.36, blue: 0.36)
    static let warningAmber = Color(red: 0.90, green: 0.62, blue: 0.13)
    
    static let textSecondary = Color.secondary
    
    // MARK: - Gradients
    static let ctaGradient = LinearGradient(
        colors: [amberStart, amberEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let heroCardGradient = LinearGradient(
        colors: [Color(red: 0.09, green: 0.13, blue: 0.32),
                 Color(red: 0.20, green: 0.09, blue: 0.30)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Decorative top shape - ab deep aur rich, halka/pastel nahi
    static let decorativeGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.12, blue: 0.34),
                 Color(red: 0.24, green: 0.10, blue: 0.32)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Surfaces
    static let cardBackground = Color(.systemBackground)
    static let fieldBackground = Color(.systemGray6)
}

// MARK: - Helper Extension for Light/Dark Adaptive Colors
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
