import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isShowingRegister = false

    var body: some View {
        NavigationStack {
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

                VStack(spacing: AppTheme.Spacing.xLarge) {
                    header
                    form
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 460)
                .padding(.vertical, 28)
            }
            .navigationDestination(isPresented: $isShowingRegister) {
                RegisterView()
            }
            .alert("CareMyCar", isPresented: Binding(
                get: { errorMessage != nil || sessionStore.sessionMessage != nil },
                set: { _ in
                    errorMessage = nil
                    sessionStore.sessionMessage = nil
                }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? sessionStore.sessionMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            AppIconBadge(systemImage: "car.fill", tint: AppTheme.ColorToken.brand, size: 82)

            Text("CareMyCar")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.ColorToken.brand)

            Text("Administra tus vehiculos, servicios y refacciones.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            TextField("Correo electronico", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Contrasena", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await login() }
            } label: {
                LoadingLabel(isLoading ? "Ingresando..." : "Iniciar sesion", isLoading: isLoading, systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading)

            Button("Crear cuenta") {
                isShowingRegister = true
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.ColorToken.brand)
        }
        .appCard()
    }

    private func login() async {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty
        else {
            errorMessage = "Por favor completa todos los campos."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await dependencies.authUseCase.login(email: email, password: password)
            sessionStore.signIn(user: response.user.asUser, accessToken: response.accessToken)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Error al iniciar sesion."
        }
    }
}
