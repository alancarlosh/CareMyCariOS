import SwiftUI

struct AdminPartsView: View {
    @Environment(\.appDependencies) private var dependencies

    @State private var parts: [Part] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var formRoute: AdminPartFormRoute?
    @State private var partToDelete: Part?

    var body: some View {
        List {
            Section {
                if isLoading {
                    ProgressView("Cargando catalogo")
                } else if parts.isEmpty {
                    ContentUnavailableView("Sin refacciones", systemImage: "wrench.and.screwdriver", description: Text("Crea la primera refaccion del catalogo."))
                } else {
                    ForEach(parts) { part in
                        AdminPartRow(part: part)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                formRoute = .edit(part)
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .padding(.vertical, 4)
                            )
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    partToDelete = part
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text("Refacciones")
            }
        }
        .navigationTitle("Catalogo")
        .scrollContentBackground(.hidden)
        .background(AppTheme.ColorToken.groupedBackground)
        .searchable(text: $searchText, prompt: "Buscar refaccion")
        .refreshable {
            await loadParts()
        }
        .task {
            await loadParts()
        }
        .onSubmit(of: .search) {
            Task {
                await loadParts()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    formRoute = .create
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $formRoute) { route in
            NavigationStack {
                AdminPartFormView(route: route) { part in
                    upsert(part)
                    successMessage = route.title == "Nueva refaccion" ? "Refaccion creada" : "Refaccion actualizada"
                    formRoute = nil
                }
            }
        }
        .alert("Eliminar refaccion", isPresented: Binding(
            get: { partToDelete != nil },
            set: { visible in
                if !visible {
                    partToDelete = nil
                }
            }
        )) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                if let partToDelete {
                    Task {
                        await delete(partToDelete)
                    }
                }
            }
        } message: {
            Text("Esta accion no se puede deshacer.")
        }
        .alert("Catalogo", isPresented: Binding(
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
    private func loadParts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            parts = try await dependencies.adminPartsUseCase.listParts(query: searchText.trimmedNil, category: nil).items
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func delete(_ part: Part) async {
        do {
            try await dependencies.adminPartsUseCase.deletePart(id: part.id)
            parts.removeAll { $0.id == part.id }
            partToDelete = nil
            successMessage = "Refaccion eliminada"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func upsert(_ part: Part) {
        if let index = parts.firstIndex(where: { $0.id == part.id }) {
            parts[index] = part
        } else {
            parts.insert(part, at: 0)
        }
    }
}

struct AdminPartFormView: View {
    let route: AdminPartFormRoute
    let onSaved: (Part) -> Void

    @Environment(\.appDependencies) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: String
    @State private var make: String
    @State private var year: String
    @State private var model: String
    @State private var price: String
    @State private var quantity: String
    @State private var catalogVehicles: [CatalogVehicle] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(route: AdminPartFormRoute, onSaved: @escaping (Part) -> Void) {
        self.route = route
        self.onSaved = onSaved

        let part = route.part
        _name = State(initialValue: part?.name ?? "")
        _category = State(initialValue: part?.category ?? "")
        _make = State(initialValue: part?.make ?? "")
        _year = State(initialValue: part?.year.map(String.init) ?? "")
        _model = State(initialValue: part?.model ?? "")
        _price = State(initialValue: part?.price.partNumberText ?? "")
        _quantity = State(initialValue: part.map { String($0.quantity) } ?? "")
    }

    private var availableMakes: [String] {
        Array(Set(catalogVehicles.map(\.make))).sorted()
    }

    private var availableModels: [String] {
        Array(Set(catalogVehicles.filter { make.isEmpty || $0.make == make }.map(\.model))).sorted()
    }

    var body: some View {
        Form {
            Section("Datos") {
                TextField("Nombre", text: $name)
                TextField("Categoria", text: $category)

                Picker("Marca", selection: $make) {
                    Text("Sin marca").tag("")
                    ForEach(availableMakes, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                Picker("Modelo", selection: $model) {
                    Text("Sin modelo").tag("")
                    ForEach(availableModels, id: \.self) { value in
                        Text(value).tag(value)
                    }
                }

                TextField("Ano", text: $year)
                    .keyboardType(.numberPad)
            }

            Section("Inventario") {
                TextField("Precio", text: $price)
                    .keyboardType(.decimalPad)
                TextField("Cantidad", text: $quantity)
                    .keyboardType(.numberPad)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCatalog()
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
                .disabled(isSaving)
            }
        }
    }

    @MainActor
    private func loadCatalog() async {
        do {
            catalogVehicles = try await dependencies.vehicleUseCase.listCatalogVehicles()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        guard !name.trimmed.isEmpty, !category.trimmed.isEmpty else {
            errorMessage = "Nombre y categoria son obligatorios."
            return
        }

        guard let priceValue = price.normalizedDecimal else {
            errorMessage = "Precio debe ser numerico."
            return
        }
        guard priceValue >= 0 else {
            errorMessage = "Precio no puede ser negativo."
            return
        }
        guard let quantityValue = quantity.trimmedInt else {
            errorMessage = "Cantidad debe ser numerica."
            return
        }
        guard quantityValue >= 0 else {
            errorMessage = "Cantidad no puede ser negativa."
            return
        }
        let yearValue = year.trimmed.isEmpty ? nil : year.trimmedInt
        if !year.trimmed.isEmpty, yearValue == nil {
            errorMessage = "Ano debe ser numerico."
            return
        }
        if let yearValue, !validVehicleYearRange.contains(yearValue) {
            errorMessage = "Ano debe estar entre \(validVehicleYearRange.lowerBound) y \(validVehicleYearRange.upperBound)."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let savedPart: Part
            switch route.mode {
            case .create:
                savedPart = try await dependencies.adminPartsUseCase.createPart(request: CreatePartRequest(
                    name: name.trimmed,
                    category: category.trimmed,
                    make: make.trimmedNil,
                    year: yearValue,
                    model: model.trimmedNil,
                    compatibility: [],
                    price: priceValue,
                    quantity: quantityValue
                ))
            case .edit(let part):
                savedPart = try await dependencies.adminPartsUseCase.updatePart(id: part.id, request: UpdatePartRequest(
                    name: name.trimmed,
                    category: category.trimmed,
                    make: make.trimmed,
                    year: yearValue ?? 0,
                    model: model.trimmed,
                    price: priceValue,
                    quantity: quantityValue
                ))
            }
            onSaved(savedPart)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private var validVehicleYearRange: ClosedRange<Int> {
    1980...(Calendar.current.component(.year, from: Date()) + 1)
}

struct AdminPartFormRoute: Identifiable {
    let mode: Mode

    static var create: AdminPartFormRoute {
        AdminPartFormRoute(mode: .create)
    }

    static func edit(_ part: Part) -> AdminPartFormRoute {
        AdminPartFormRoute(mode: .edit(part))
    }

    var id: String {
        switch mode {
        case .create:
            return "create"
        case .edit(let part):
            return "edit-\(part.id)"
        }
    }

    var part: Part? {
        switch mode {
        case .create:
            return nil
        case .edit(let part):
            return part
        }
    }

    var title: String {
        switch mode {
        case .create:
            return "Nueva refaccion"
        case .edit:
            return "Editar refaccion"
        }
    }

    enum Mode {
        case create
        case edit(Part)
    }
}

private struct AdminPartRow: View {
    let part: Part

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
                    .font(.headline)
            }

            HStack {
                Label(part.vehicleLabel, systemImage: "car.fill")
                Spacer()
                Label("\(part.quantity) disp.", systemImage: "cube.box.fill")
                    .foregroundColor(part.quantity > 0 ? .secondary : .red)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private extension Double {
    var partNumberText: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(self)
    }
}

private extension String {
    var normalizedDecimal: Double? {
        Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    var trimmedInt: Int? {
        Int(trimmed)
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
}
