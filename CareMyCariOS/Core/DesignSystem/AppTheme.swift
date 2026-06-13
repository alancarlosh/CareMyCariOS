import SwiftUI

enum AppTheme {
    enum ColorToken {
        static let brand = Color(red: 0.05, green: 0.35, blue: 0.44)
        static let brandSecondary = Color(red: 0.13, green: 0.52, blue: 0.62)
        static let accent = Color(red: 0.13, green: 0.42, blue: 0.72)
        static let success = Color(red: 0.08, green: 0.52, blue: 0.30)
        static let warning = Color(red: 0.86, green: 0.49, blue: 0.10)
        static let danger = Color(red: 0.78, green: 0.16, blue: 0.20)
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)
        static let softBrandBackground = Color(red: 0.88, green: 0.95, blue: 0.98)
    }

    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.22)
        static let entrance = SwiftUI.Animation.spring(response: 0.36, dampingFraction: 0.86)
    }
}

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.ColorToken.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
    }
}

extension View {
    func appCard() -> some View {
        modifier(CardStyleModifier())
    }
}

