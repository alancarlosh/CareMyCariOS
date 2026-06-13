import SwiftUI

struct RoleHomeView: View {
    let user: User

    private var isAdmin: Bool {
        user.role == "admin"
    }

    var body: some View {
        if isAdmin {
            AgencyShellView(user: user)
        } else {
            ClientShellView(user: user)
        }
    }
}

private struct ClientShellView: View {
    let user: User

    var body: some View {
        TabView {
            NavigationStack {
                VehiclesListView()
            }
            .tabItem {
                Label("Vehiculos", systemImage: "car.2.fill")
            }

            NavigationStack {
                MarketplaceView()
            }
            .tabItem {
                Label("Marketplace", systemImage: "shippingbox.fill")
            }

            NavigationStack {
                MonthlyCostView()
            }
            .tabItem {
                Label("Costos", systemImage: "fuelpump.fill")
            }

            NavigationStack {
                AccountView(user: user, title: "Cliente")
            }
            .tabItem {
                Label("Cuenta", systemImage: "person.crop.circle.fill")
            }
        }
    }
}

private struct AgencyShellView: View {
    let user: User

    var body: some View {
        TabView {
            NavigationStack {
                AgencyDashboardView()
            }
            .tabItem {
                Label("Panel", systemImage: "square.grid.2x2.fill")
            }

            NavigationStack {
                AdminPartsView()
            }
            .tabItem {
                Label("Catalogo", systemImage: "wrench.and.screwdriver.fill")
            }

            NavigationStack {
                AdminOrdersView()
            }
            .tabItem {
                Label("Ventas", systemImage: "cart.fill")
            }

            NavigationStack {
                AdminServiceOrdersView()
            }
            .tabItem {
                Label("Servicios", systemImage: "doc.text.fill")
            }

            NavigationStack {
                AccountView(user: user, title: "Agencia")
            }
            .tabItem {
                Label("Cuenta", systemImage: "building.2.fill")
            }
        }
    }
}

private struct AgencyDashboardView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        AppIconBadge(systemImage: "building.2.fill", tint: AppTheme.ColorToken.brand, size: 58)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Centro de operaciones")
                                .font(.title3.bold())
                            Text("Gestiona catalogo, ventas y servicios desde un solo lugar.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 10) {
                        DashboardStat(title: "Catalogo", systemImage: "wrench.and.screwdriver.fill", tint: .blue)
                        DashboardStat(title: "Ventas", systemImage: "cart.fill", tint: AppTheme.ColorToken.success)
                        DashboardStat(title: "Servicios", systemImage: "doc.text.fill", tint: AppTheme.ColorToken.warning)
                    }
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section("Operaciones") {
                NavigationLink {
                    AdminPartsView()
                } label: {
                    DashboardRow(
                        title: "Catalogo",
                        systemImage: "wrench.and.screwdriver.fill",
                        tint: .blue
                    )
                }

                NavigationLink {
                    AdminOrdersView()
                } label: {
                    DashboardRow(
                        title: "Pedidos y ventas",
                        systemImage: "cart.fill",
                        tint: .green
                    )
                }

                NavigationLink {
                    AdminServiceOrdersView()
                } label: {
                    DashboardRow(
                        title: "Ordenes de servicio",
                        systemImage: "doc.text.fill",
                        tint: .orange
                    )
                }
            }
        }
        .navigationTitle("CareMyCar")
        .scrollContentBackground(.hidden)
        .background(AppTheme.ColorToken.groupedBackground)
    }
}

private struct DashboardStat: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            AppIconBadge(systemImage: systemImage, tint: tint, size: 34)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.medium)
        .background(AppTheme.ColorToken.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
    }
}

private struct DashboardRow: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(systemImage: systemImage, tint: tint, size: 38)

            Text(title)
                .font(.body.weight(.medium))
        }
        .padding(.vertical, 4)
    }
}

private struct AccountView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    let user: User
    let title: String

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: user.role == "admin" ? "building.2.fill" : "person.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(AppTheme.ColorToken.brand)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.name?.nilIfBlank ?? title)
                                .font(.headline)
                            Text(user.email?.nilIfBlank ?? "Sesion activa")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Label(user.role ?? "Sin rol", systemImage: "key.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                Button(role: .destructive) {
                    sessionStore.signOut()
                } label: {
                    Label("Cerrar sesion", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Cuenta")
        .scrollContentBackground(.hidden)
        .background(AppTheme.ColorToken.groupedBackground)
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
