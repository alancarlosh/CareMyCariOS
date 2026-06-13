import SwiftUI

struct AdminServiceOrdersView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies

    @State private var orders: [ServiceOrder] = []
    @State private var selectedStatus = ""
    @State private var isLoading = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedOrder: ServiceOrder?
    @State private var actionRoute: ServiceOrderActionRoute?
    @State private var includesReportFrom = false
    @State private var includesReportTo = false
    @State private var reportFrom = Date()
    @State private var reportTo = Date()
    @State private var exportedReportURL: URL?
    @State private var isExportingReport = false

    private let statuses = ["", "PROGRAMADO", "EN_PROCESO", "FINALIZADO", "CANCELADO"]

    var body: some View {
        List {
            Section("Reporte PDF") {
                Toggle("Filtrar desde", isOn: $includesReportFrom)
                if includesReportFrom {
                    DatePicker("Desde", selection: $reportFrom, displayedComponents: .date)
                }

                Toggle("Filtrar hasta", isOn: $includesReportTo)
                if includesReportTo {
                    DatePicker("Hasta", selection: $reportTo, displayedComponents: .date)
                }

                Button {
                    Task {
                        await exportReport()
                    }
                } label: {
                    if isExportingReport {
                        ProgressView()
                    } else {
                        Label("Generar servicios finalizados", systemImage: "doc.richtext")
                    }
                }
                .disabled(isExportingReport)

                if let exportedReportURL {
                    ShareLink(item: exportedReportURL) {
                        Label("Compartir PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }

            Section {
                Picker("Estado", selection: $selectedStatus) {
                    ForEach(statuses, id: \.self) { status in
                        Text(serviceOrderStatusLabel(status)).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                if isLoading {
                    ProgressView("Cargando ordenes")
                } else if orders.isEmpty {
                    ContentUnavailableView("Sin ordenes", systemImage: "doc.text", description: Text("Las ordenes de servicio apareceran aqui."))
                } else {
                    ForEach(orders) { order in
                        AdminServiceOrderRow(order: order)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedOrder = order
                            }
                    }
                }
            } header: {
                Text("Servicios")
            }
        }
        .navigationTitle("Ordenes de servicio")
        .refreshable {
            await loadOrders()
        }
        .task {
            await loadOrders()
        }
        .onChange(of: selectedStatus) { _, _ in
            Task {
                await loadOrders()
            }
        }
        .sheet(item: $selectedOrder) { order in
            NavigationStack {
                AdminServiceOrderDetailView(order: order) { route in
                    selectedOrder = nil
                    actionRoute = route
                }
            }
        }
        .sheet(item: $actionRoute) { route in
            NavigationStack {
                ServiceOrderActionForm(route: route, isUpdating: isUpdating) { action in
                    await perform(action: action, for: route.order)
                }
            }
        }
        .alert("Ordenes de servicio", isPresented: Binding(
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

    @MainActor
    private func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            orders = try await dependencies.adminServiceOrdersService.listOrders(status: selectedStatus.trimmedNil)
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func perform(action: ServiceOrderAction, for order: ServiceOrder) async {
        isUpdating = true
        defer { isUpdating = false }

        do {
            let updated: ServiceOrder
            switch action {
            case .start(let notes):
                updated = try await dependencies.adminServiceOrdersService.start(orderId: order.id, agencyNotes: notes)
                successMessage = "Orden iniciada"
            case .complete(let token, let finalCost, let notes, let mileage):
                updated = try await dependencies.adminServiceOrdersService.complete(
                    orderId: order.id,
                    completionToken: token,
                    finalCost: finalCost,
                    agencyNotes: notes,
                    mileage: mileage
                )
                successMessage = "Orden finalizada"
            case .cancel(let notes):
                updated = try await dependencies.adminServiceOrdersService.cancel(orderId: order.id, agencyNotes: notes)
                successMessage = "Orden cancelada"
            }

            if let index = orders.firstIndex(where: { $0.id == updated.id }) {
                orders[index] = updated
            }
            actionRoute = nil
            await loadOrders()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func exportReport() async {
        if includesReportFrom, includesReportTo, reportFrom > reportTo {
            errorMessage = "La fecha Desde no puede ser mayor que Hasta."
            return
        }

        isExportingReport = true
        defer { isExportingReport = false }

        do {
            let fromValue = includesReportFrom ? Self.dateFormatter.string(from: reportFrom) : nil
            let toValue = includesReportTo ? Self.dateFormatter.string(from: reportTo) : nil
            let data = try await dependencies.adminServiceOrdersService.reportPDF(from: fromValue, to: toValue)
            let suffix = [fromValue, toValue].compactMap { $0 }.joined(separator: "_")
            exportedReportURL = try PDFExportStore.write(
                data: data,
                fileName: suffix.isEmpty ? "servicios_finalizados.pdf" : "servicios_finalizados_\(suffix).pdf"
            )
            successMessage = "PDF generado"
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
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

private struct AdminServiceOrderDetailView: View {
    let order: ServiceOrder
    let onAction: (ServiceOrderActionRoute) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Servicio") {
                LabeledContent("Vehiculo", value: order.vehicleSnapshot.label)
                LabeledContent("Tipo", value: order.serviceType)
                LabeledContent("Fecha", value: order.scheduledDate)
                LabeledContent("Estado", value: serviceOrderStatusLabel(order.status))
                LabeledContent("Estimado", value: (order.estimatedCost ?? 0).formatted(.currency(code: "MXN")))
                LabeledContent("Final", value: (order.finalCost ?? 0).formatted(.currency(code: "MXN")))
            }

            Section("Cliente") {
                if !order.userName.isEmpty {
                    LabeledContent("Nombre", value: order.userName)
                }
                if !order.userEmail.isEmpty {
                    LabeledContent("Email", value: order.userEmail)
                }
                if !order.userNotes.isEmpty {
                    Text(order.userNotes)
                }
            }

            if let breakdown = order.costBreakdown {
                Section("Cotizacion") {
                    LabeledContent("Productos", value: breakdown.productsTotalMxn.formatted(.currency(code: "MXN")))
                    LabeledContent("Mano de obra", value: breakdown.laborTotalMxn.formatted(.currency(code: "MXN")))
                    ForEach(breakdown.products) { product in
                        LabeledContent(product.name, value: "\(product.qty)x \(product.unitPriceMxn.formatted(.currency(code: "MXN")))")
                    }
                }
            }

            if !order.completionToken.isEmpty && (order.status == "PROGRAMADO" || order.status == "EN_PROCESO") {
                Section("Token esperado") {
                    Text(order.completionToken)
                        .font(.headline.monospaced())
                }
            }

            Section("Acciones") {
                if order.status == "PROGRAMADO" {
                    Button {
                        onAction(.start(order))
                    } label: {
                        Label("Iniciar", systemImage: "play.fill")
                    }
                }

                if order.status == "EN_PROCESO" {
                    Button {
                        onAction(.complete(order))
                    } label: {
                        Label("Finalizar", systemImage: "checkmark.circle.fill")
                    }
                }

                if order.status == "PROGRAMADO" || order.status == "EN_PROCESO" {
                    Button(role: .destructive) {
                        onAction(.cancel(order))
                    } label: {
                        Label("Cancelar", systemImage: "xmark.circle.fill")
                    }
                }

                if order.status != "PROGRAMADO" && order.status != "EN_PROCESO" {
                    Text("Esta orden ya no permite acciones.")
                        .foregroundStyle(.secondary)
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
            }
        }
    }
}

private struct ServiceOrderActionForm: View {
    let route: ServiceOrderActionRoute
    let isUpdating: Bool
    let onSubmit: (ServiceOrderAction) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""
    @State private var completionToken = ""
    @State private var finalCost = ""
    @State private var mileage = ""
    @State private var validationMessage: String?

    var body: some View {
        Form {
            Section(route.title) {
                if route.kind == .complete {
                    TextField("Token de finalizacion", text: $completionToken)
                        .textInputAutocapitalization(.characters)
                    TextField("Costo final", text: $finalCost)
                        .keyboardType(.decimalPad)
                    TextField("Kilometraje", text: $mileage)
                        .keyboardType(.numberPad)
                }

                TextField("Notas de agencia", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let validationMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
                .disabled(isUpdating)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await submit()
                    }
                } label: {
                    if isUpdating {
                        ProgressView()
                    } else {
                        Text("Confirmar")
                    }
                }
                .disabled(isUpdating)
            }
        }
    }

    private func submit() async {
        switch route.kind {
        case .start:
            await onSubmit(.start(notes.trimmedNil))
        case .cancel:
            await onSubmit(.cancel(notes.trimmedNil))
        case .complete:
            guard !completionToken.trimmed.isEmpty else {
                validationMessage = "El token es obligatorio."
                return
            }
            let costValue = finalCost.trimmed.isEmpty ? nil : finalCost.normalizedDecimal
            let mileageValue = mileage.trimmed.isEmpty ? nil : Int(mileage)
            if !finalCost.trimmed.isEmpty, costValue == nil {
                validationMessage = "El costo final debe ser numerico."
                return
            }
            if let costValue, costValue < 0 {
                validationMessage = "El costo final no puede ser negativo."
                return
            }
            if !mileage.trimmed.isEmpty, mileageValue == nil {
                validationMessage = "El kilometraje debe ser numerico."
                return
            }
            if let mileageValue, mileageValue < 0 {
                validationMessage = "El kilometraje no puede ser negativo."
                return
            }
            await onSubmit(.complete(
                token: completionToken.trimmed,
                finalCost: costValue,
                notes: notes.trimmedNil,
                mileage: mileageValue
            ))
        }
    }
}

private struct AdminServiceOrderRow: View {
    let order: ServiceOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.vehicleSnapshot.label)
                        .font(.headline)
                    Text(order.serviceType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(serviceOrderStatusLabel(order.status))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

            HStack {
                Label(order.scheduledDate.isEmpty ? "Sin fecha" : order.scheduledDate, systemImage: "calendar")
                Spacer()
                Text(((order.finalCost ?? order.estimatedCost) ?? 0).formatted(.currency(code: "MXN")))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !order.userName.isEmpty || !order.userEmail.isEmpty {
                Text([order.userName, order.userEmail].filter { !$0.isEmpty }.joined(separator: " - "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private enum ServiceOrderAction {
    case start(String?)
    case complete(token: String, finalCost: Double?, notes: String?, mileage: Int?)
    case cancel(String?)
}

private struct ServiceOrderActionRoute: Identifiable {
    enum Kind {
        case start
        case complete
        case cancel
    }

    let kind: Kind
    let order: ServiceOrder

    static func start(_ order: ServiceOrder) -> ServiceOrderActionRoute {
        ServiceOrderActionRoute(kind: .start, order: order)
    }

    static func complete(_ order: ServiceOrder) -> ServiceOrderActionRoute {
        ServiceOrderActionRoute(kind: .complete, order: order)
    }

    static func cancel(_ order: ServiceOrder) -> ServiceOrderActionRoute {
        ServiceOrderActionRoute(kind: .cancel, order: order)
    }

    var id: String {
        "\(order.id)-\(title)"
    }

    var title: String {
        switch kind {
        case .start:
            return "Iniciar orden"
        case .complete:
            return "Finalizar orden"
        case .cancel:
            return "Cancelar orden"
        }
    }
}

private func serviceOrderStatusLabel(_ status: String) -> String {
    switch status {
    case "":
        return "Todos"
    case "PROGRAMADO":
        return "Programado"
    case "EN_PROCESO":
        return "En proceso"
    case "FINALIZADO":
        return "Finalizado"
    case "CANCELADO":
        return "Cancelado"
    default:
        return status
    }
}

private func validateDateRange(from: String, to: String) -> String? {
    let fromValue = from.trimmed
    let toValue = to.trimmed
    let pattern = #"^\d{4}-\d{2}-\d{2}$"#

    if !fromValue.isEmpty, fromValue.range(of: pattern, options: .regularExpression) == nil {
        return "La fecha Desde debe tener formato YYYY-MM-DD."
    }
    if !toValue.isEmpty, toValue.range(of: pattern, options: .regularExpression) == nil {
        return "La fecha Hasta debe tener formato YYYY-MM-DD."
    }
    if !fromValue.isEmpty, !toValue.isEmpty, fromValue > toValue {
        return "La fecha Desde no puede ser mayor que Hasta."
    }
    return nil
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNil: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }

    var normalizedDecimal: Double? {
        Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }
}
