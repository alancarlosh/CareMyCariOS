import SwiftUI

struct VehicleDetailView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    let vehicleId: String
    let initialVehicle: Vehicle?
    let onChanged: () -> Void

    @State private var vehicle: Vehicle?
    @State private var mileage = ""
    @State private var isLoading = false
    @State private var isSavingMileage = false
    @State private var isDeleting = false
    @State private var isShowingDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(vehicleId: String, initialVehicle: Vehicle? = nil, onChanged: @escaping () -> Void = {}) {
        self.vehicleId = vehicleId
        self.initialVehicle = initialVehicle
        self.onChanged = onChanged
        _vehicle = State(initialValue: initialVehicle)
        _mileage = State(initialValue: initialVehicle?.currentMileage.map { String(Int($0)) } ?? "")
    }

    var body: some View {
        Group {
            if let vehicle {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            AppIconBadge(systemImage: "car.fill", tint: AppTheme.ColorToken.brand, size: 96)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)

                            Text(vehicle.title)
                                .font(.title2.bold())
                            Text(vehicle.subtitle)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Detalles") {
                        ForEach(vehicle.detailRows, id: \.0) { label, value in
                            LabeledContent(label, value: value)
                        }
                    }

                    Section {
                        NavigationLink {
                            MaintenanceListView(vehicleId: vehicle.id, vehicleTitle: vehicle.title)
                        } label: {
                            Label("Mantenimiento", systemImage: "wrench.and.screwdriver")
                        }
                    }

                    Section("Actualizar kilometraje") {
                        if let currentMileage = vehicle.currentMileage {
                            LabeledContent("Lectura registrada", value: "\(Int(currentMileage)) km")
                        }

                        TextField("Nuevo kilometraje", text: $mileage)
                            .keyboardType(.numberPad)

                        Button {
                            Task { await updateMileage() }
                        } label: {
                            LoadingLabel(isSavingMileage ? "Actualizando..." : "Actualizar kilometraje", isLoading: isSavingMileage, systemImage: "speedometer")
                        }
                        .disabled(isSavingMileage || isLoading)
                    }

                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            LoadingLabel(isDeleting ? "Eliminando..." : "Eliminar vehiculo", isLoading: isDeleting, systemImage: "trash")
                        }
                        .disabled(isDeleting)
                    }
                }
                .refreshable {
                    await loadVehicle()
                }
            } else if isLoading {
                AppStateView(state: .loading("Cargando detalle..."))
            } else {
                AppStateView(
                    state: .error(
                        title: "Vehiculo no disponible",
                        systemImage: "exclamationmark.triangle",
                        message: errorMessage ?? "No se pudo cargar este vehiculo."
                    ),
                    actionTitle: "Reintentar",
                    actionSystemImage: "arrow.clockwise"
                ) {
                    Task { await loadVehicle() }
                }
            }
        }
        .navigationTitle(vehicle?.title ?? "Vehiculo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        Task { await loadVehicle() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)

                    Button(role: .destructive) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(vehicle == nil || isDeleting)
                }
            }
        }
        .task {
            await loadVehicle()
        }
        .alert("CareMyCar", isPresented: Binding(
            get: { (errorMessage != nil || successMessage != nil) && vehicle != nil },
            set: { _ in
                errorMessage = nil
                successMessage = nil
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? successMessage ?? "")
        }
        .confirmationDialog(
            "Eliminar vehiculo",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar vehiculo", role: .destructive) {
                Task { await deleteVehicle() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta accion no se puede deshacer.")
        }
    }

    private func loadVehicle() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedVehicle = try await dependencies.vehicleService.getVehicle(id: vehicleId)
            vehicle = loadedVehicle
            mileage = loadedVehicle.currentMileage.map { String(Int($0)) } ?? ""
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo cargar el vehiculo."
        }
    }

    private func updateMileage() async {
        guard let mileageValue = mileage.trimmedInt else {
            errorMessage = "El kilometraje debe ser numerico."
            return
        }

        guard mileageValue >= 0 else {
            errorMessage = "El kilometraje no puede ser negativo."
            return
        }

        isSavingMileage = true
        defer { isSavingMileage = false }

        do {
            let updatedVehicle = try await dependencies.vehicleService.updateMileage(vehicleId: vehicleId, mileage: mileageValue)
            vehicle = updatedVehicle
            mileage = updatedVehicle.currentMileage.map { String(Int($0)) } ?? ""
            successMessage = "Kilometraje actualizado."
            onChanged()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo actualizar el kilometraje."
        }
    }

    private func deleteVehicle() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await dependencies.vehicleService.deleteVehicle(id: vehicleId)
            onChanged()
            dismiss()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo eliminar el vehiculo."
        }
    }
}

private extension String {
    var trimmedInt: Int? {
        Int(trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
