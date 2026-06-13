import SwiftUI

struct AppStateView: View {
    let state: AppUIState
    var actionTitle: String?
    var actionSystemImage: String?
    var action: (() -> Void)?

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading(let message):
            VStack(spacing: AppTheme.Spacing.medium) {
                ProgressView()
                    .controlSize(.large)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
            .accessibilityElement(children: .combine)
        case .empty(let title, let systemImage, let message):
            content(title: title, systemImage: systemImage, message: message, tint: AppTheme.ColorToken.brandSecondary)
        case .error(let title, let systemImage, let message):
            content(title: title, systemImage: systemImage, message: message, tint: AppTheme.ColorToken.danger)
        }
    }

    private func content(title: String, systemImage: String, message: String, tint: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 72, height: 72)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.Spacing.small) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: actionSystemImage ?? "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(AppTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

struct LoadingLabel: View {
    let title: String
    let isLoading: Bool
    let systemImage: String?

    init(_ title: String, isLoading: Bool, systemImage: String? = nil) {
        self.title = title
        self.isLoading = isLoading
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            if isLoading {
                ProgressView()
            } else if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

