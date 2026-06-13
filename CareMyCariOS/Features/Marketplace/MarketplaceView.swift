import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies

    @State private var selectedTab = MarketplaceTab.products
    @State private var products: [Part] = []
    @State private var purchases: [Order] = []
    @State private var searchText = ""
    @State private var isLoadingProducts = false
    @State private var isLoadingPurchases = false
    @State private var errorMessage: String?
    @State private var selectedPart: Part?
    @State private var successMessage: String?

    var body: some View {
        List {
            Picker("Vista", selection: $selectedTab) {
                ForEach(MarketplaceTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            if selectedTab == .products {
                productsSection
            } else {
                purchasesSection
            }
        }
        .navigationTitle("Marketplace")
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Buscar refaccion")
        .refreshable {
            await reloadCurrentTab()
        }
        .task {
            await loadProducts()
            await loadPurchases()
        }
        .onChange(of: selectedTab) { _, newValue in
            Task {
                if newValue == .products {
                    await loadProducts()
                } else {
                    await loadPurchases()
                }
            }
        }
        .onSubmit(of: .search) {
            Task {
                await loadProducts()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await reloadCurrentTab()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoadingProducts || isLoadingPurchases)
            }
        }
        .alert("Marketplace", isPresented: Binding(
            get: { errorMessage != nil || successMessage != nil },
            set: { visible in
                if !visible {
                    errorMessage = nil
                    successMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? successMessage ?? "")
        }
        .sheet(item: $selectedPart) { part in
            PurchaseSheet(part: part) { quantity in
                await purchase(part: part, quantity: quantity)
            }
        }
    }

    private var productsSection: some View {
        Section {
            if isLoadingProducts {
                ProgressView("Cargando productos")
            } else if products.isEmpty {
                ContentUnavailableView("Sin productos", systemImage: "shippingbox", description: Text("No hay refacciones disponibles con estos filtros."))
            } else {
                ForEach(products) { part in
                    MarketplaceProductRow(part: part) {
                        selectedPart = part
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text("Productos")
        }
    }

    private var purchasesSection: some View {
        Section {
            if isLoadingPurchases {
                ProgressView("Cargando compras")
            } else if purchases.isEmpty {
                ContentUnavailableView("Sin compras", systemImage: "cart", description: Text("Tus compras apareceran aqui."))
            } else {
                ForEach(purchases) { order in
                    PurchaseRow(order: order)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .padding(.vertical, 4)
                        )
                        .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text("Mis compras")
        }
    }

    @MainActor
    private func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await dependencies.marketplaceUseCase.listProducts(query: searchText.trimmedNil, category: nil).items
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadPurchases() async {
        isLoadingPurchases = true
        defer { isLoadingPurchases = false }

        do {
            purchases = try await dependencies.marketplaceUseCase.listMyPurchases().items
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func reloadCurrentTab() async {
        if selectedTab == .products {
            await loadProducts()
        } else {
            await loadPurchases()
        }
    }

    @MainActor
    private func purchase(part: Part, quantity: Int) async {
        do {
            let order = try await dependencies.marketplaceUseCase.purchase(partId: part.id, quantity: quantity)
            selectedPart = nil
            successMessage = "Compra registrada: \(order.partLabel)"
            await loadProducts()
            await loadPurchases()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct MarketplaceProductRow: View {
    let part: Part
    let onPurchase: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(part.name)
                        .font(.headline)
                    Text(part.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(part.price, format: .currency(code: "MXN"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.06, green: 0.38, blue: 0.48))
            }

            Label(part.vehicleLabel, systemImage: "car.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(part.quantity) disponibles", systemImage: "cube.box.fill")
                    .foregroundColor(part.quantity > 0 ? .secondary : .red)
                Spacer()
                Button("Comprar") {
                    onPurchase()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(part.quantity < 1)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}

private struct PurchaseRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(order.partLabel)
                    .font(.headline)
                Spacer()
                Text(order.totalPrice, format: .currency(code: "MXN"))
                    .font(.headline)
            }

            HStack {
                Label("Cantidad \(order.quantity)", systemImage: "number")
                Spacer()
                Text(statusLabel(order.status))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let createdAt = order.createdAt?.nilIfEmpty {
                Text(createdAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func statusLabel(_ status: String) -> String {
        switch status.lowercased() {
        case "pending":
            return "Pendiente"
        case "confirmed":
            return "Confirmada"
        case "delivered":
            return "Entregada"
        case "canceled", "cancelled":
            return "Cancelada"
        default:
            return status.isEmpty ? "Sin estado" : status.capitalized
        }
    }
}

private struct PurchaseSheet: View {
    let part: Part
    let onConfirm: (Int) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var isSubmitting = false

    private var total: Double {
        Double(quantity) * part.price
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Refaccion") {
                    LabeledContent("Producto", value: part.name)
                    LabeledContent("Precio", value: part.price.formatted(.currency(code: "MXN")))
                    LabeledContent("Disponibles", value: "\(part.quantity)")
                }

                Section("Compra") {
                    Stepper(value: $quantity, in: 1...max(part.quantity, 1)) {
                        LabeledContent("Cantidad", value: "\(quantity)")
                    }
                    LabeledContent("Total", value: total.formatted(.currency(code: "MXN")))
                }
            }
            .navigationTitle("Comprar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            isSubmitting = true
                            await onConfirm(quantity)
                            isSubmitting = false
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Confirmar")
                        }
                    }
                    .disabled(isSubmitting || part.quantity < 1)
                }
            }
        }
    }
}

private enum MarketplaceTab: String, CaseIterable, Identifiable {
    case products
    case purchases

    var id: String { rawValue }

    var title: String {
        switch self {
        case .products:
            return "Productos"
        case .purchases:
            return "Compras"
        }
    }
}

private extension String {
    var trimmedNil: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
