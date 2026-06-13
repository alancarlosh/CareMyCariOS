import SwiftUI

struct AddVehicleView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var catalogVehicles: [CatalogVehicle] = []
    @State private var selectedMake = ""
    @State private var selectedModel = ""
    @State private var year = ""
    @State private var mileage = ""
    @State private var color = ""
    @State private var isCatalogLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var makes: [String] {
        Array(Set(catalogVehicles.map(\.make))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var modelsForMake: [String] {
        catalogVehicles
            .filter { $0.make == selectedMake }
            .map(\.model)
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var selectedCatalogVehicle: CatalogVehicle? {
        catalogVehicles.first { $0.make == selectedMake && $0.model == selectedModel }
    }

    var body: some View {
        Form {
            if isCatalogLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Cargando catalogo...")
                    }
                }
            }

            Section("Ficha del catalogo") {
                Picker("Marca", selection: $selectedMake) {
                    Text("Selecciona").tag("")
                    ForEach(makes, id: \.self) { make in
                        Text(make).tag(make)
                    }
                }
                .onChange(of: selectedMake) { _, _ in
                    selectedModel = ""
                }

                Picker("Modelo", selection: $selectedModel) {
                    Text(selectedMake.isEmpty ? "Elige marca primero" : "Selecciona").tag("")
                    ForEach(modelsForMake, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .disabled(selectedMake.isEmpty)
            }

            if let selectedCatalogVehicle {
                Section("Vehiculo seleccionado") {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                .fill(AppTheme.ColorToken.softBrandBackground)
                            Image(systemName: "car.fill")
                                .foregroundStyle(AppTheme.ColorToken.brand)
                        }
                        .frame(width: 58, height: 58)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedCatalogVehicle.title)
                                .font(.headline)
                            Text(selectedCatalogVehicle.vehicleType)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(selectedCatalogVehicle.fuelType) - \(selectedCatalogVehicle.transmission)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Datos de tu auto") {
                TextField("Ano", text: $year)
                    .keyboardType(.numberPad)

                TextField("Kilometraje actual", text: $mileage)
                    .keyboardType(.numberPad)

                TextField("Color", text: $color)
                    .textInputAutocapitalization(.words)
            }

            Section {
                Button {
                    Task { await createVehicle() }
                } label: {
                    LoadingLabel(isSaving ? "Guardando..." : "Guardar vehiculo", isLoading: isSaving, systemImage: "checkmark.circle.fill")
                }
                .disabled(isSaving || selectedCatalogVehicle == nil)
            }
        }
        .navigationTitle("Agregar vehiculo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancelar") {
                    dismiss()
                }
            }
        }
        .task {
            if catalogVehicles.isEmpty {
                await loadCatalog()
            }
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

    private func loadCatalog() async {
        isCatalogLoading = true
        defer { isCatalogLoading = false }

        do {
            catalogVehicles = try await dependencies.vehicleUseCase.listCatalogVehicles()
            errorMessage = nil
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo cargar el catalogo de vehiculos."
        }
    }

    private func createVehicle() async {
        guard let selectedCatalogVehicle else {
            errorMessage = "Selecciona un vehiculo del catalogo."
            return
        }

        guard let yearValue = year.trimmedInt else {
            errorMessage = "Ano debe ser numerico."
            return
        }
        guard (1980...Calendar.current.component(.year, from: Date()) + 1).contains(yearValue) else {
            errorMessage = "Ano debe estar entre 1980 y \(Calendar.current.component(.year, from: Date()) + 1)."
            return
        }
        guard let mileageValue = mileage.trimmedInt else {
            errorMessage = "Kilometraje actual debe ser numerico."
            return
        }
        guard mileageValue >= 0 else {
            errorMessage = "Kilometraje actual no puede ser negativo."
            return
        }

        let trimmedColor = color.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = CreateVehicleRequest(
            catalogVehicleId: selectedCatalogVehicle.id,
            make: nil,
            model: nil,
            year: yearValue,
            currentMileage: mileageValue,
            color: trimmedColor.isEmpty ? nil : trimmedColor,
            fuelType: nil,
            transmission: nil,
            vehicleType: nil
        )

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await dependencies.vehicleUseCase.createVehicle(request: request)
            onCreated()
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo crear el vehiculo."
        }
    }
}

private extension String {
    var trimmedInt: Int? {
        Int(trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
