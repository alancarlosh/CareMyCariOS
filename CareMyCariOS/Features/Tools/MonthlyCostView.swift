import SwiftUI

struct MonthlyCostView: View {
    @Environment(\.appDependencies) private var dependencies

    @State private var monthlyKm = ""
    @State private var kmPerLiter = ""
    @State private var fuelPrice = ""
    @State private var maintenancePerKm = ""
    @State private var estimate: MonthlyCostEstimate?
    @State private var isCalculating = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Resumen") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(monthlyKm.nilIfBlank.map { "\($0) km / mes" } ?? "Sin calculo", systemImage: "speedometer")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(estimate?.totalMonthlyCost.formatted(.currency(code: "MXN")) ?? "-")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.ColorToken.brand)
                    Text("Estimacion mensual de combustible y mantenimiento.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Datos") {
                TextField("Kilometros al mes", text: $monthlyKm)
                    .keyboardType(.decimalPad)
                TextField("Rendimiento (km/l)", text: $kmPerLiter)
                    .keyboardType(.decimalPad)
                TextField("Precio por litro", text: $fuelPrice)
                    .keyboardType(.decimalPad)
                TextField("Mantenimiento por km", text: $maintenancePerKm)
                    .keyboardType(.decimalPad)

                Button {
                    Task {
                        await calculate()
                    }
                } label: {
                    LoadingLabel(isCalculating ? "Calculando..." : "Calcular costo mensual", isLoading: isCalculating, systemImage: "function")
                }
                .disabled(isCalculating)
            }

            if let estimate {
                Section("Resultado") {
                    LabeledContent("Litros necesarios", value: estimate.litersNeeded.formatted(.number.precision(.fractionLength(2))))
                    LabeledContent("Combustible", value: estimate.fuelCost.formatted(.currency(code: "MXN")))
                    LabeledContent("Mantenimiento", value: estimate.maintenanceCost.formatted(.currency(code: "MXN")))
                    LabeledContent("Total mensual", value: estimate.totalMonthlyCost.formatted(.currency(code: "MXN")))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Costo mensual")
        .scrollContentBackground(.hidden)
        .background(AppTheme.ColorToken.groupedBackground)
        .refreshable {
            if estimate != nil {
                await calculate()
            }
        }
    }

    @MainActor
    private func calculate() async {
        guard let monthlyKmValue = monthlyKm.positiveDouble(field: "Kilometros al mes", errorMessage: &errorMessage) else {
            return
        }
        guard let kmPerLiterValue = kmPerLiter.positiveDouble(field: "Rendimiento", errorMessage: &errorMessage) else {
            return
        }
        guard let fuelPriceValue = fuelPrice.positiveDouble(field: "Precio por litro", errorMessage: &errorMessage) else {
            return
        }
        guard let maintenancePerKmValue = maintenancePerKm.nonNegativeDouble(field: "Mantenimiento por km", errorMessage: &errorMessage) else {
            return
        }

        isCalculating = true
        errorMessage = nil
        defer { isCalculating = false }

        do {
            estimate = try await dependencies.monthlyCostUseCase.estimate(
                monthlyKm: monthlyKmValue,
                kmPerLiter: kmPerLiterValue,
                fuelPrice: fuelPriceValue,
                maintenancePerKm: maintenancePerKmValue
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedDecimal: Double? {
        Double(trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    func positiveDouble(field: String, errorMessage: inout String?) -> Double? {
        guard let value = normalizedDecimal else {
            errorMessage = "\(field) debe ser numerico."
            return nil
        }
        guard value > 0 else {
            errorMessage = "\(field) debe ser mayor que 0."
            return nil
        }
        return value
    }

    func nonNegativeDouble(field: String, errorMessage: inout String?) -> Double? {
        guard let value = normalizedDecimal else {
            errorMessage = "\(field) debe ser numerico."
            return nil
        }
        guard value >= 0 else {
            errorMessage = "\(field) no puede ser negativo."
            return nil
        }
        return value
    }
}
