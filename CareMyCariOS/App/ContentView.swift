import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        Group {
            switch sessionStore.state {
            case .restoring:
                SplashView()
            case .signedOut:
                LoginView()
            case .signedIn(let user):
                RoleHomeView(user: user)
            }
        }
        .animation(AppTheme.Animation.standard, value: sessionStore.state)
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.ColorToken.softBrandBackground,
                    AppTheme.ColorToken.groupedBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.large) {
                AppIconBadge(systemImage: "car.fill", tint: AppTheme.ColorToken.brand, size: 76)

                Text("CareMyCar")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ColorToken.brand)

                ProgressView()
                    .tint(AppTheme.ColorToken.brand)
                    .padding(.top, 8)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.97)))
        }
    }
}
