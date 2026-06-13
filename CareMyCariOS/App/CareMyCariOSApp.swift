import SwiftUI

@main
struct CareMyCariOSApp: App {
    @StateObject private var sessionStore = SessionStore()
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionStore)
                .environment(\.appDependencies, dependencies)
                .tint(AppTheme.ColorToken.brand)
                .task {
                    await sessionStore.restoreSession()
                }
        }
    }
}
