import SwiftUI

struct VehiclesListView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @State private var vehicles: [Vehicle] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isShowingAddVehicle = false

    var body: some View {
        Group {
            if isLoading && vehicles.isEmpty {
                AppStateView(state: .loading("Cargando vehiculos..."))
            } else if vehicles.isEmpty {
                AppStateView(
                    state: errorMessage.map {
                        .error(title: "No se pudieron cargar tus vehiculos", systemImage: "wifi.exclamationmark", message: $0)
                    } ?? .empty(
                        title: "Sin vehiculos",
                        systemImage: "car",
                        message: "Agrega tu primer auto para consultar mantenimiento, servicios y costos."
                    ),
                    actionTitle: errorMessage == nil ? "Agregar vehiculo" : "Reintentar",
                    actionSystemImage: errorMessage == nil ? "plus" : "arrow.clockwise"
                ) {
                    if errorMessage == nil {
                        isShowingAddVehicle = true
                    } else {
                        Task { await loadVehicles() }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .background(AppTheme.ColorToken.groupedBackground)
            } else {
                List {
                    Section {
                        ForEach(vehicles) { vehicle in
                            NavigationLink {
                                VehicleDetailView(vehicleId: vehicle.id, initialVehicle: vehicle) {
                                    Task { await loadVehicles() }
                                }
                            } label: {
                                VehicleRow(vehicle: vehicle)
                            }
                        }
                    } header: {
                        Text("\(vehicles.count) registrados")
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await loadVehicles()
                }
                .overlay(alignment: .top) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, AppTheme.Spacing.small)
                    }
                }
            }
        }
        .animation(AppTheme.Animation.standard, value: isLoading)
        .animation(AppTheme.Animation.entrance, value: vehicles)
        .navigationTitle("Mis vehiculos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        Task { await loadVehicles() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)

                    Button {
                        isShowingAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isShowingAddVehicle) {
            AddVehicleView {
                isShowingAddVehicle = false
                Task { await loadVehicles() }
            }
        }
        .task {
            if vehicles.isEmpty {
                await loadVehicles()
            }
        }
        .alert("CareMyCar", isPresented: Binding(
            get: { errorMessage != nil && !vehicles.isEmpty },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadVehicles() async {
        isLoading = true
        defer { isLoading = false }

        do {
            vehicles = try await dependencies.vehicleUseCase.listVehicles()
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudieron cargar tus vehiculos."
        }
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle

    var body: some View {
        AppInfoRow(
            title: vehicle.title,
            subtitle: subtitle,
            systemImage: "car.fill",
            tint: AppTheme.ColorToken.brand
        ) {
            if let mileage = vehicle.currentMileage {
                Text("\(Int(mileage)) km")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var subtitle: String {
        [vehicle.subtitle == "Sin datos generales" ? nil : vehicle.subtitle, vehicle.vehicleType]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
