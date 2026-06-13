import SwiftUI

struct MaintenanceListView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    let vehicleId: String
    let vehicleTitle: String

    @State private var records: [MaintenanceRecord] = []
    @State private var recommendations: [MaintenanceRecommendation] = []
    @State private var isLoading = false
    @State private var isLoadingRecommendations = false
    @State private var errorMessage: String?
    @State private var recommendationsError: String?
    @State private var selectedRecord: MaintenanceRecord?
    @State private var isShowingAdd = false
    @State private var selectedRecommendation: MaintenanceRecommendation?
    @State private var recordPendingDelete: MaintenanceRecord?

    var body: some View {
        Group {
            if isLoading && records.isEmpty {
                AppStateView(state: .loading("Cargando mantenimiento..."))
            } else if records.isEmpty && recommendations.isEmpty {
                AppStateView(
                    state: errorMessage.map {
                        .error(title: "No se pudo cargar el historial", systemImage: "wrench.adjustable", message: $0)
                    } ?? .empty(
                        title: "Sin historial",
                        systemImage: "wrench.and.screwdriver",
                        message: "Registra los servicios realizados a este vehiculo."
                    ),
                    actionTitle: errorMessage == nil ? "Agregar servicio" : "Reintentar",
                    actionSystemImage: errorMessage == nil ? "plus" : "arrow.clockwise"
                ) {
                    if errorMessage == nil {
                        isShowingAdd = true
                    } else {
                        Task { await loadAll() }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            } else {
                List {
                    Section {
                        NavigationLink {
                            ServiceOrdersView(vehicleId: vehicleId)
                        } label: {
                            Label("Ordenes de servicio", systemImage: "doc.text")
                        }
                    }

                    if !recommendations.isEmpty {
                        Section("Recomendaciones") {
                            ForEach(recommendations) { recommendation in
                                MaintenanceRecommendationRow(recommendation: recommendation) {
                                    selectedRecommendation = recommendation
                                }
                            }
                        }
                    }

                    ForEach(records) { record in
                        Button {
                            selectedRecord = record
                        } label: {
                            MaintenanceRecordRow(record: record)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                recordPendingDelete = record
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    if records.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "Sin historial",
                                systemImage: "wrench.and.screwdriver",
                                description: Text("Registra los servicios realizados a este vehiculo.")
                            )
                        }
                    }
                }
                .refreshable {
                    await loadAll()
                }
            }
        }
        .navigationTitle("Mantenimiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        Task { await loadMaintenance() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)

                    Button {
                        isShowingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            if records.isEmpty {
                await loadAll()
            }
        }
        .navigationDestination(isPresented: $isShowingAdd) {
            MaintenanceFormView(
                mode: .create(vehicleId: vehicleId),
                onSaved: { created in
                    records.insert(created, at: 0)
                    isShowingAdd = false
                }
            )
        }
        .navigationDestination(item: $selectedRecommendation) { recommendation in
            MaintenanceFormView(
                mode: .create(vehicleId: vehicleId),
                initialServiceType: recommendation.serviceLabel,
                initialServiceDate: recommendation.dueDate,
                onSaved: { created in
                    records.insert(created, at: 0)
                    selectedRecommendation = nil
                }
            )
        }
        .navigationDestination(item: $selectedRecord) { record in
            MaintenanceFormView(
                mode: .edit(record),
                onSaved: { updated in
                    records = records.map { $0.id == updated.id ? updated : $0 }
                    selectedRecord = nil
                }
            )
        }
        .alert("CareMyCar", isPresented: Binding(
            get: { errorMessage != nil && !records.isEmpty },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Eliminar mantenimiento",
            isPresented: Binding(
                get: { recordPendingDelete != nil },
                set: { if !$0 { recordPendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                Task { await deletePendingRecord() }
            }
            Button("Cancelar", role: .cancel) {
                recordPendingDelete = nil
            }
        } message: {
            Text("Se eliminara el registro seleccionado.")
        }
    }

    private func loadMaintenance() async {
        isLoading = true
        defer { isLoading = false }

        do {
            records = try await dependencies.maintenanceService.listMaintenance(vehicleId: vehicleId)
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo cargar el mantenimiento."
        }
    }

    private func loadRecommendations() async {
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }

        do {
            recommendations = try await dependencies.maintenanceService.listRecommendations(vehicleId: vehicleId)
            recommendationsError = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            recommendationsError = (error as? LocalizedError)?.errorDescription ?? "No se pudieron cargar las recomendaciones."
        }
    }

    private func loadAll() async {
        await loadMaintenance()
        await loadRecommendations()
    }

    private func deletePendingRecord() async {
        guard let record = recordPendingDelete else { return }

        do {
            try await dependencies.maintenanceService.deleteMaintenance(id: record.id)
            records.removeAll { $0.id == record.id }
            recordPendingDelete = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo eliminar el registro."
            recordPendingDelete = nil
        }
    }
}

private struct MaintenanceRecommendationRow: View {
    let recommendation: MaintenanceRecommendation
    let onUse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.serviceLabel)
                    .font(.headline)
                Spacer()
                Text(recommendation.status)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            HStack(spacing: 12) {
                Label(recommendation.dueDate, systemImage: "calendar")
                Label("\(recommendation.dueKm) km", systemImage: "gauge.with.dots.needle.67percent")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("\(recommendation.daysLeft) dias / \(recommendation.kmLeft) km restantes")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Registrar este servicio") {
                onUse()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch recommendation.status.lowercased() {
        case "overdue", "vencido", "urgent", "urgente":
            return .red
        case "soon", "proximo", "próximo", "warning":
            return .orange
        default:
            return .blue
        }
    }
}

private struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.title)
                    .font(.headline)
                Spacer()
                Text(record.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let description = record.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if let mileage = record.mileage {
                    Label("\(mileage) km", systemImage: "gauge.with.dots.needle.67percent")
                }
                if let cost = record.cost {
                    Label(cost.formatted(.currency(code: "MXN")), systemImage: "dollarsign.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
