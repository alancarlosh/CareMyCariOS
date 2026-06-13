import SwiftUI

struct AdminOrdersView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies

    @State private var orders: [Order] = []
    @State private var report: SalesDailyReport?
    @State private var searchText = ""
    @State private var selectedStatus = ""
    @State private var allCount = 0
    @State private var pendingCount = 0
    @State private var isLoading = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedOrder: Order?
    @State private var showingCreateOrder = false
    @State private var exportedReportURL: URL?
    @State private var isExportingReport = false

    private let statuses = ["", "pending", "confirmed", "delivered", "canceled"]

    var body: some View {
        List {
            reportSection

            Section {
                Picker("Estado", selection: $selectedStatus) {
                    ForEach(statuses, id: \.self) { status in
                        Text(statusFilterLabel(status)).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Section {
                if isLoading {
                    ProgressView("Cargando pedidos")
                } else if orders.isEmpty {
                    ContentUnavailableView("Sin pedidos", systemImage: "cart", description: Text("Las ventas registradas apareceran aqui."))
                } else {
                    ForEach(orders) { order in
                        AdminOrderRow(order: order)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedOrder = order
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
                Text("Pedidos")
            }
        }
        .navigationTitle("Ventas")
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Buscar cliente o pieza")
        .refreshable {
            await reload()
        }
        .task {
            await reload()
        }
        .onSubmit(of: .search) {
            Task {
                await loadOrders()
            }
        }
        .onChange(of: selectedStatus) { _, _ in
            Task {
                await loadOrders()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateOrder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateOrder) {
            NavigationStack {
                AdminCreateOrderView { order in
                    orders.insert(order, at: 0)
                    successMessage = "Pedido creado"
                    showingCreateOrder = false
                    Task {
                        await reload()
                    }
                }
            }
        }
        .sheet(item: $selectedOrder) { order in
            NavigationStack {
                AdminOrderDetailView(order: order, isUpdating: isUpdating) { status in
                    await update(order: order, status: status)
                }
            }
        }
        .alert("Ventas", isPresented: Binding(
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
    }

    private var reportSection: some View {
        Section("Reporte diario") {
            VStack(alignment: .leading, spacing: 8) {
                Label(report?.date ?? "Hoy", systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text((report?.totalSales ?? 0).formatted(.currency(code: "MXN")))
                    .font(.title2.bold())
                    .foregroundStyle(Color(red: 0.06, green: 0.38, blue: 0.48))
                Text("\(report?.totalOrders ?? allCount) ordenes registradas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            LabeledContent("Ordenes", value: "\(report?.totalOrders ?? allCount)")
            LabeledContent("Pendientes", value: "\(report?.pendingCount ?? pendingCount)")
            LabeledContent("Confirmadas", value: "\(report?.confirmedCount ?? 0)")
            LabeledContent("Entregadas", value: "\(report?.deliveredCount ?? 0)")
            LabeledContent("Canceladas", value: "\(report?.canceledCount ?? 0)")

            Button {
                Task {
                    await exportDailyReport()
                }
            } label: {
                if isExportingReport {
                    ProgressView()
                } else {
                    Label("Generar PDF", systemImage: "doc.richtext")
                }
            }
            .disabled(isExportingReport)

            if let exportedReportURL {
                ShareLink(item: exportedReportURL) {
                    Label("Compartir PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    @MainActor
    private func reload() async {
        await loadOrders()
        await loadReport()
    }

    @MainActor
    private func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await dependencies.adminOrdersUseCase.listOrders(query: searchText.trimmedNil, status: selectedStatus.trimmedNil)
            orders = response.items.map(\.asOrder)
            allCount = response.allCount ?? response.total
            pendingCount = response.pendingCount ?? 0
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func loadReport() async {
        do {
            report = try await dependencies.adminOrdersUseCase.dailyReport()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func exportDailyReport() async {
        isExportingReport = true
        defer { isExportingReport = false }

        do {
            let reportDate = report?.date ?? "daily"
            let data = try await dependencies.adminOrdersUseCase.dailyReportPDF(date: report?.date)
            exportedReportURL = try PDFExportStore.write(data: data, fileName: "ventas_\(reportDate).pdf")
            successMessage = "PDF generado"
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func update(order: Order, status: String) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            let updated = try await dependencies.adminOrdersUseCase.updateStatus(orderId: order.id, status: status)
            if let index = orders.firstIndex(where: { $0.id == updated.id }) {
                orders[index] = updated
            }
            selectedOrder = nil
            successMessage = "Estado actualizado"
            await reload()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AdminCreateOrderView: View {
    let onCreated: (Order) -> Void

    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var clientName = ""
    @State private var vin = ""
    @State private var make = ""
    @State private var model = ""
    @State private var year = ""
    @State private var quantity = "1"
    @State private var catalogVehicles: [CatalogVehicle] = []
    @State private var parts: [Part] = []
    @State private var selectedPartId = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var availableMakes: [String] {
        Array(Set(catalogVehicles.map(\.make))).sorted()
    }

    private var availableModels: [String] {
        Array(Set(catalogVehicles.filter { make.isEmpty || $0.make == make }.map(\.model))).sorted()
    }

    private var availableParts: [Part] {
        parts
            .filter { part in
                (make.isEmpty || part.make?.caseInsensitiveCompare(make) == .orderedSame) &&
                (model.isEmpty || part.model?.caseInsensitiveCompare(model) == .orderedSame)
            }
            .sorted { $0.name < $1.name }
    }

    private var selectedPart: Part? {
        availableParts.first { $0.id == selectedPartId }
    }

    var body: some View {
        Form {
            Section("Cliente") {
                TextField("Nombre", text: $clientName)
                TextField("VIN", text: $vin)
                    .textInputAutocapitalization(.characters)
            }

            Section("Vehiculo") {
                Picker("Marca", selection: $make) {
                    Text("Selecciona").tag("")
                    ForEach(availableMakes, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                Picker("Modelo", selection: $model) {
                    Text("Selecciona").tag("")
                    ForEach(availableModels, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                TextField("Ano", text: $year)
                    .keyboardType(.numberPad)
            }

            Section("Refaccion") {
                Picker("Pieza", selection: $selectedPartId) {
                    Text("Selecciona").tag("")
                    ForEach(availableParts) { part in
                        Text("\(part.name) - \(part.quantity) disp.").tag(part.id)
                    }
                }

                TextField("Cantidad", text: $quantity)
                    .keyboardType(.numberPad)

                if let selectedPart {
                    LabeledContent("Precio unitario", value: selectedPart.price.formatted(.currency(code: "MXN")))
                    LabeledContent("Total", value: (selectedPart.price * Double(quantity.trimmedInt ?? 0)).formatted(.currency(code: "MXN")))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Nuevo pedido")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
        .onChange(of: make) { _, _ in
            if !model.isEmpty && !availableModels.contains(model) {
                model = ""
            }
            clearUnavailablePartSelection()
        }
        .onChange(of: model) { _, _ in
            clearUnavailablePartSelection()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
                .disabled(isSaving)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await save()
                    }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Guardar")
                    }
                }
                .disabled(isSaving || isLoading)
            }
        }
    }

    @MainActor
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let vehicleResult = dependencies.vehicleUseCase.listCatalogVehicles()
            async let partsResult = dependencies.adminPartsUseCase.listParts(query: nil, category: nil, page: 1, limit: 100)
            catalogVehicles = try await vehicleResult
            parts = try await partsResult.items
            clearUnavailablePartSelection()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        guard let part = selectedPart else {
            errorMessage = "Selecciona una refaccion valida."
            return
        }

        guard !clientName.trimmed.isEmpty, !vin.trimmed.isEmpty, !make.trimmed.isEmpty, !model.trimmed.isEmpty else {
            errorMessage = "Completa los campos obligatorios."
            return
        }

        guard let yearValue = year.trimmedInt else {
            errorMessage = "Ano debe ser numerico."
            return
        }
        guard validVehicleYearRange.contains(yearValue) else {
            errorMessage = "Ano debe estar entre \(validVehicleYearRange.lowerBound) y \(validVehicleYearRange.upperBound)."
            return
        }
        guard let quantityValue = quantity.trimmedInt else {
            errorMessage = "Cantidad debe ser numerica."
            return
        }
        guard quantityValue > 0 else {
            errorMessage = "Cantidad debe ser mayor que 0."
            return
        }
        guard quantityValue <= part.quantity else {
            errorMessage = "Solo hay \(part.quantity) unidades disponibles."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let order = try await dependencies.adminOrdersUseCase.createOrder(request: CreateOrderRequest(
                clientName: clientName.trimmed,
                vin: vin.trimmed,
                make: make.trimmed,
                year: yearValue,
                model: model.trimmed,
                partId: part.id,
                quantity: quantityValue,
                status: "pending"
            ))
            onCreated(order)
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func clearUnavailablePartSelection() {
        guard !selectedPartId.isEmpty else { return }
        if !availableParts.contains(where: { $0.id == selectedPartId }) {
            selectedPartId = ""
        }
    }
}

private var validVehicleYearRange: ClosedRange<Int> {
    1980...(Calendar.current.component(.year, from: Date()) + 1)
}

private struct AdminOrderDetailView: View {
    let order: Order
    let isUpdating: Bool
    let onStatusChange: (String) async -> Void

    @Environment(\.dismiss) private var dismiss

    private var transitions: [String] {
        switch order.status.lowercased() {
        case "pending":
            return ["confirmed", "canceled"]
        case "confirmed":
            return ["delivered", "canceled"]
        default:
            return []
        }
    }

    var body: some View {
        List {
            Section("Pedido") {
                LabeledContent("Cliente", value: order.clientName)
                LabeledContent("Pieza", value: order.partLabel)
                LabeledContent("Cantidad", value: "\(order.quantity)")
                LabeledContent("Total", value: order.totalPrice.formatted(.currency(code: "MXN")))
                LabeledContent("Estado", value: orderStatusLabel(order.status))
            }

            Section("Vehiculo") {
                LabeledContent("Marca", value: order.make)
                LabeledContent("Modelo", value: order.model)
                LabeledContent("Ano", value: "\(order.year)")
                LabeledContent("VIN", value: order.vin)
            }

            Section("Cambiar estado") {
                if transitions.isEmpty {
                    Text("Este pedido ya no permite cambios de estado.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(transitions, id: \.self) { status in
                        Button {
                            Task {
                                await onStatusChange(status)
                            }
                        } label: {
                            Label(orderStatusLabel(status), systemImage: orderStatusIcon(status))
                        }
                        .disabled(isUpdating)
                    }
                }
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cerrar") {
                    dismiss()
                }
                .disabled(isUpdating)
            }
        }
    }
}

private struct AdminOrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName)
                        .font(.headline)
                    Text(order.partLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(order.totalPrice, format: .currency(code: "MXN"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.06, green: 0.38, blue: 0.48))
            }

            HStack {
                Label("\(order.make) \(order.model)", systemImage: "car.fill")
                Spacer()
                Label(orderStatusLabel(order.status), systemImage: orderStatusIcon(order.status))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private func statusFilterLabel(_ status: String) -> String {
    status.isEmpty ? "Todos" : orderStatusLabel(status)
}

private func orderStatusLabel(_ status: String) -> String {
    switch status.lowercased() {
    case "pending":
        return "Pendiente"
    case "confirmed":
        return "Confirmado"
    case "delivered":
        return "Entregado"
    case "canceled", "cancelled":
        return "Cancelado"
    default:
        return status.isEmpty ? "Sin estado" : status.capitalized
    }
}

private func orderStatusIcon(_ status: String) -> String {
    switch status.lowercased() {
    case "confirmed":
        return "checkmark.circle.fill"
    case "delivered":
        return "shippingbox.fill"
    case "canceled", "cancelled":
        return "xmark.circle.fill"
    default:
        return "clock.fill"
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNil: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }

    var trimmedInt: Int? {
        Int(trimmed)
    }
}
