import SwiftUI

enum MaintenanceFormMode: Hashable {
    case create(vehicleId: String)
    case edit(MaintenanceRecord)
}

struct MaintenanceFormView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss

    let mode: MaintenanceFormMode
    let onSaved: (MaintenanceRecord) -> Void

    @State private var serviceType = ""
    @State private var serviceDate = Date()
    @State private var description = ""
    @State private var cost = ""
    @State private var mileage = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var title: String {
        switch mode {
        case .create:
            return "Nuevo servicio"
        case .edit:
            return "Editar servicio"
        }
    }

    init(mode: MaintenanceFormMode, onSaved: @escaping (MaintenanceRecord) -> Void) {
        self.mode = mode
        self.onSaved = onSaved

        if case .edit(let record) = mode {
            _serviceType = State(initialValue: record.serviceType ?? "")
            _serviceDate = State(initialValue: Self.dateFormatter.date(from: record.serviceDate ?? "") ?? Date())
            _description = State(initialValue: record.description ?? "")
            _cost = State(initialValue: record.cost.map { String($0) } ?? "")
            _mileage = State(initialValue: record.mileage.map { String($0) } ?? "")
        }
    }

    init(
        mode: MaintenanceFormMode,
        initialServiceType: String,
        initialServiceDate: String,
        onSaved: @escaping (MaintenanceRecord) -> Void
    ) {
        self.mode = mode
        self.onSaved = onSaved
        _serviceType = State(initialValue: initialServiceType)
        _serviceDate = State(initialValue: Self.dateFormatter.date(from: initialServiceDate) ?? Date())
    }

    var body: some View {
        Form {
            Section("Servicio") {
                TextField("Tipo de servicio", text: $serviceType)
                    .textInputAutocapitalization(.words)

                DatePicker("Fecha", selection: $serviceDate, displayedComponents: .date)

                TextField("Descripcion", text: $description, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
            }

            Section("Datos opcionales") {
                TextField("Costo", text: $cost)
                    .keyboardType(.decimalPad)

                TextField("Kilometraje", text: $mileage)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    LoadingLabel(isSaving ? "Guardando..." : "Guardar", isLoading: isSaving, systemImage: "checkmark.circle.fill")
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancelar") {
                    dismiss()
                }
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

    private func save() async {
        guard let normalized = normalizedFields() else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let saved: MaintenanceRecord
            switch mode {
            case .create(let vehicleId):
                saved = try await dependencies.maintenanceUseCase.createMaintenance(
                    request: CreateMaintenanceRequest(
                        vehicleId: vehicleId,
                        serviceType: normalized.serviceType,
                        serviceDate: normalized.serviceDate,
                        description: normalized.description,
                        cost: normalized.cost,
                        mileage: normalized.mileage
                    )
                )
            case .edit(let record):
                saved = try await dependencies.maintenanceUseCase.updateMaintenance(
                    id: record.id,
                    request: UpdateMaintenanceRequest(
                        serviceType: normalized.serviceType,
                        serviceDate: normalized.serviceDate,
                        description: normalized.description,
                        cost: normalized.cost,
                        mileage: normalized.mileage
                    )
                )
            }

            onSaved(saved)
        } catch APIError.unauthorized {
            sessionStore.signOut(message: APIError.unauthorized.errorDescription)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "No se pudo guardar el mantenimiento."
        }
    }

    private func normalizedFields() -> (serviceType: String, serviceDate: String, description: String?, cost: Double?, mileage: Int?)? {
        let normalizedServiceType = serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedServiceDate = Self.dateFormatter.string(from: serviceDate)

        guard !normalizedServiceType.isEmpty else {
            errorMessage = "El tipo de servicio es requerido."
            return nil
        }

        let normalizedCost = cost.trimmingCharacters(in: .whitespacesAndNewlines)
        let costValue = normalizedCost.isEmpty ? nil : normalizedCost.normalizedDecimal
        if !normalizedCost.isEmpty && costValue == nil {
            errorMessage = "Costo debe ser numerico."
            return nil
        }
        if let costValue, costValue < 0 {
            errorMessage = "Costo no puede ser negativo."
            return nil
        }

        let normalizedMileage = mileage.trimmingCharacters(in: .whitespacesAndNewlines)
        let mileageValue = normalizedMileage.isEmpty ? nil : Int(normalizedMileage)
        if !normalizedMileage.isEmpty && mileageValue == nil {
            errorMessage = "Kilometraje debe ser entero."
            return nil
        }
        if let mileageValue, mileageValue < 0 {
            errorMessage = "Kilometraje no puede ser negativo."
            return nil
        }

        return (
            serviceType: normalizedServiceType,
            serviceDate: normalizedServiceDate,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            cost: costValue,
            mileage: mileageValue
        )
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

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    var normalizedDecimal: Double? {
        Double(replacingOccurrences(of: ",", with: "."))
    }
}
