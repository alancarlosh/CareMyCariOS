import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependencies) private var dependencies
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            AppTheme.ColorToken.groupedBackground
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xLarge) {
                VStack(spacing: 8) {
                    AppIconBadge(systemImage: "person.badge.plus.fill", tint: AppTheme.ColorToken.brand, size: 64)

                    Text("Crear cuenta")
                        .font(.largeTitle.bold())
                    Text("Registra tu acceso a CareMyCar.")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    TextField("Nombre", text: $name)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)

                    TextField("Correo electronico", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    SecureField("Contrasena", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await register() }
                    } label: {
                        LoadingLabel(isLoading ? "Registrando..." : "Registrarme", isLoading: isLoading, systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                }
                .appCard()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 460)
        }
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
        .alert("CareMyCar", isPresented: Binding(
            get: { errorMessage != nil || successMessage != nil },
            set: { _ in
                if successMessage != nil {
                    dismiss()
                }
                errorMessage = nil
                successMessage = nil
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? successMessage ?? "")
        }
    }

    private func register() async {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty
        else {
            errorMessage = "Por favor completa correo y contrasena."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await dependencies.authService.register(email: email, password: password, name: name)
            successMessage = "Cuenta creada. Inicia sesion para continuar."
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Error al registrar usuario."
        }
    }
}
