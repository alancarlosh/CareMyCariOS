import Foundation

enum SessionState: Equatable {
    case restoring
    case signedOut
    case signedIn(User)
}

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var state: SessionState = .restoring
    @Published var sessionMessage: String?

    private let tokenStore: KeychainTokenStore

    init(tokenStore: KeychainTokenStore = .shared) {
        self.tokenStore = tokenStore
    }

    func restoreSession() async {
        guard tokenStore.getToken() != nil else {
            state = .signedOut
            return
        }

        if let savedUser = tokenStore.getUser() {
            state = .signedIn(savedUser)
            return
        }

        let savedRole = tokenStore.getUserRole()
        let restoredUser = User(
            id: "local-session",
            email: nil,
            name: nil,
            role: savedRole
        )
        state = .signedIn(restoredUser)
    }

    func signIn(user: User, accessToken: String) {
        tokenStore.save(token: accessToken, user: user)
        state = .signedIn(user)
    }

    func signOut(message: String? = nil) {
        tokenStore.clear()
        sessionMessage = message
        state = .signedOut
    }
}
