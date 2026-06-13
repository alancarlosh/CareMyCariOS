import SwiftUI

struct AppIconBadge: View {
    let systemImage: String
    var tint: Color = AppTheme.ColorToken.brand
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct AppInfoRow<Accessory: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color
    @ViewBuilder let accessory: Accessory

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = AppTheme.ColorToken.brand,
        @ViewBuilder accessory: () -> Accessory = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.accessory = accessory()
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            AppIconBadge(systemImage: systemImage, tint: tint)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            accessory
        }
        .padding(.vertical, AppTheme.Spacing.xSmall)
    }
}

