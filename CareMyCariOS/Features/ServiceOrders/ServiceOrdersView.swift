import SwiftUI

struct ServiceOrdersView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    let vehicleId: String

    @State private var orders: [ServiceOrder] = []
    @State private var serviceType = ""
    @State private var scheduledDate = Date()
    @State private var notes = ""
    @State private var quote: ServiceQuote?
    @State private var isLoading = false
    @State private var isQuoting = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Solicitar servicio") {
                TextField("Tipo de servicio", text: $serviceType)
                    .textInputAutocapitalization(.words)
                DatePicker("Fecha", selection: $scheduledDate, displayedComponents: .date)
                TextField("Notas", text: $notes, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)

                Button {
                    Task { await loadQuote() }
                } label: {
                    HStack {
                        LoadingLabel(isQuoting ? "Cotizando..." : "Cotizar servicio", isLoading: isQuoting, systemImage: "function")
                    }
                }
                .disabled(isQuoting || serviceType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let quote {
                    QuoteSummaryView(quote: quote)

                    Button {
                        Task { await createOrder() }
                    } label: {
                        HStack {
                            LoadingLabel(isCreating ? "Creando orden..." : "Crear orden", isLoading: isCreating, systemImage: "checkmark.circle.fill")
                        }
                    }
                    .disabled(isCreating)
                }
            }

            Section("Ordenes") {
                if isLoading && orders.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Cargando ordenes...")
                    }
                } else if orders.isEmpty {
                    ContentUnavailableView(
                        "Sin ordenes",
                        systemImage: "doc.text",
                        description: Text("Las solicitudes de servicio apareceran aqui.")
                    )
                } else {
                    ForEach(orders) { order in
                        ServiceOrderRow(order: order)
                    }
                }
            }
        }
        .navigationTitle("Ordenes de servicio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await loadOrders() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            if orders.isEmpty {
                await loadOrders()
            }
        }
        .refreshable {
            await loadOrders()
        }
        .alert("CareMyCar", isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            orders = try await dependencies.serviceOrderService.listMyServiceOrders(vehicleId: vehicleId)
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudieron cargar las ordenes."
        }
    }

    private func loadQuote() async {
        let normalizedServiceType = serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedServiceType.isEmpty else {
            errorMessage = "Selecciona un tipo de servicio para cotizar."
            return
        }

        isQuoting = true
        defer { isQuoting = false }

        do {
            quote = try await dependencies.serviceOrderService.quote(vehicleId: vehicleId, serviceType: normalizedServiceType)
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo obtener la cotizacion."
        }
    }

    private func createOrder() async {
        let normalizedServiceType = serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedScheduledDate = Self.dateFormatter.string(from: scheduledDate)

        guard !normalizedServiceType.isEmpty else {
            errorMessage = "Selecciona un tipo de servicio."
            return
        }

        isCreating = true
        defer { isCreating = false }

        do {
            let created = try await dependencies.serviceOrderService.create(
                request: CreateServiceOrderRequest(
                    vehicleId: vehicleId,
                    serviceType: normalizedServiceType,
                    scheduledDate: normalizedScheduledDate,
                    estimatedCost: quote?.suggestedTotalMxn,
                    userNotes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                )
            )
            orders.insert(created, at: 0)
            quote = nil
            notes = ""
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo crear la orden."
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct QuoteSummaryView: View {
    let quote: ServiceQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Total sugerido", value: quote.suggestedTotalMxn.formatted(.currency(code: "MXN")))
            LabeledContent("Mano de obra", value: quote.laborTotalMxn.formatted(.currency(code: "MXN")))
            LabeledContent("Refacciones", value: quote.productsTotalMxn.formatted(.currency(code: "MXN")))

            if !quote.products.isEmpty {
                Text("Productos")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                ForEach(quote.products) { product in
                    Text("\(product.qty)x \(product.name) - \(product.unitPriceMxn.formatted(.currency(code: "MXN")))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ServiceOrderRow: View {
    let order: ServiceOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.serviceType.isEmpty ? "Servicio" : order.serviceType)
                    .font(.headline)
                Spacer()
                Text(order.status.isEmpty ? "SIN ESTADO" : order.status)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            Text(order.scheduledDate.isEmpty ? "Sin fecha" : order.scheduledDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let estimatedCost = order.estimatedCost {
                Text("Estimado: \(estimatedCost.formatted(.currency(code: "MXN")))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !order.completionToken.isEmpty {
                Text("Codigo: \(order.completionToken)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
