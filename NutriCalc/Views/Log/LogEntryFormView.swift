import SwiftUI
import SwiftData

struct LogEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dish.name) private var allDishes: [Dish]

    @AppStorage("showTimestamp") var showTimestamp = false

    let entry: LogEntry?    // nil = new entry

    // Common
    @State private var entryName: String = ""
    @State private var entryDate: Date = .now
    @State private var isManual: Bool = false

    // Dish mode
    @State private var selectedDish: Dish? = nil
    @State private var useServingsMode: Bool = true
    @State private var servingsConsumed: String = "1"
    @State private var massConsumed: String = ""

    // Manual mode
    @State private var manualCalories: String = ""
    @State private var manualProtein: String = ""
    @State private var manualCarbs: String = ""
    @State private var manualFat: String = ""

    @State private var showingDishPicker = false

    private var isEditing: Bool { entry != nil }

    private var calValue: Double { Double(manualCalories) ?? 0 }

    private var isValid: Bool {
        if isManual {
            return calValue > 0
        } else {
            guard selectedDish != nil else { return false }
            if useServingsMode { return (Double(servingsConsumed) ?? 0) > 0 }
            else { return (Double(massConsumed) ?? 0) > 0 }
        }
    }

    // Live preview macros
    private var previewCalories: Double { dishMacroPreview(\.perServingCalories, \.totalCalories, manualVal: Double(manualCalories) ?? 0) }
    private var previewProtein:  Double { dishMacroPreview(\.perServingProtein,  \.totalProtein,  manualVal: Double(manualProtein)  ?? 0) }
    private var previewCarbs:    Double { dishMacroPreview(\.perServingCarbs,    \.totalCarbs,    manualVal: Double(manualCarbs)    ?? 0) }
    private var previewFat:      Double { dishMacroPreview(\.perServingFat,      \.totalFat,      manualVal: Double(manualFat)      ?? 0) }

    private func dishMacroPreview(_ perServing: KeyPath<Dish, Double>, _ total: KeyPath<Dish, Double>, manualVal: Double) -> Double {
        if isManual { return manualVal }
        guard let dish = selectedDish else { return 0 }
        if useServingsMode {
            return dish[keyPath: perServing] * (Double(servingsConsumed) ?? 0)
        } else {
            guard dish.totalMass > 0 else { return 0 }
            return dish[keyPath: total] * ((Double(massConsumed) ?? 0) / dish.totalMass)
        }
    }

    var body: some View {
        Form {
            Section("Label (optional)") {
                TextField("e.g. Breakfast, Snack…", text: $entryName)
            }

            if showTimestamp {
                Section("Date & Time") {
                    DatePicker("When", selection: $entryDate, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section {
                Picker("Source", selection: $isManual) {
                    Text("Saved Dish").tag(false)
                    Text("Estimate").tag(true)
                }
                .pickerStyle(.segmented)
            }

            if isManual {
                Section {
                    macroField("Calories (kcal)", text: $manualCalories, required: true)
                    macroField("Protein (g)",     text: $manualProtein)
                    macroField("Carbs (g)",        text: $manualCarbs)
                    macroField("Fat (g)",          text: $manualFat)
                } header: {
                    Text("Macros Consumed")
                } footer: {
                    if calValue == 0 && !manualCalories.isEmpty {
                        Text("Calories cannot be zero.").foregroundStyle(.red)
                    } else if manualCalories.isEmpty {
                        Text("Calories are required.").foregroundStyle(.secondary)
                    }
                }
            } else {
                Section("Dish") {
                    Button {
                        showingDishPicker = true
                    } label: {
                        HStack {
                            if let dish = selectedDish {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dish.name).foregroundStyle(.primary)
                                    Text("\(fmt(dish.perServingCalories)) kcal / \(fmt(dish.servingSize))g serving")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Select a dish…").foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                        }
                    }
                }

                if selectedDish != nil {
                    Section {
                        Picker("Amount Mode", selection: $useServingsMode) {
                            Text("By Servings").tag(true)
                            Text("By Mass").tag(false)
                        }
                        .pickerStyle(.segmented)

                        if useServingsMode {
                            HStack {
                                Text("Servings")
                                Spacer()
                                TextField("1", text: $servingsConsumed)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        } else {
                            MassInputView(label: "Mass Consumed", grams: $massConsumed)
                        }
                    } header: {
                        Text("Amount")
                    }
                }
            }

            // Live preview
            if isValid || (isManual && calValue > 0) || selectedDish != nil {
                Section("Preview") {
                    MacroBarView(
                        calories: previewCalories,
                        protein:  previewProtein,
                        carbs:    previewCarbs,
                        fat:      previewFat,
                        label:    "This Entry"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Entry" : "Log Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!isValid)
            }
        }
        .sheet(isPresented: $showingDishPicker) {
            DishPickerView(allDishes: allDishes, selected: $selectedDish)
        }
        .onAppear { loadFromEntry() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func macroField(_ label: String, text: Binding<String>, required: Bool = false) -> some View {
        HStack {
            Text(label)
            if required { Text("*").foregroundStyle(.red).font(.caption) }
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func loadFromEntry() {
        guard let entry else { return }
        entryName = entry.name
        entryDate = entry.date
        isManual  = entry.isManual
        if entry.isManual {
            manualCalories = fmtOpt(entry.manualCalories)
            manualProtein  = fmtOpt(entry.manualProtein)
            manualCarbs    = fmtOpt(entry.manualCarbs)
            manualFat      = fmtOpt(entry.manualFat)
        } else {
            // Restore the dish snapshot as if we selected it
            useServingsMode = entry.useServingsMode
            servingsConsumed = fmtOpt(entry.servingsConsumed)
            massConsumed = fmtOpt(entry.massConsumed)
            // Try to find matching dish by name for the picker display
            selectedDish = allDishes.first { $0.name == entry.dishName }
        }
    }

    private func save() {
        let e = entry ?? LogEntry()
        e.name     = entryName.trimmingCharacters(in: .whitespaces)
        e.date     = showTimestamp ? entryDate : Calendar.current.startOfDay(for: entryDate)
        e.isManual = isManual
        e.macrosConfirmed = true

        if isManual {
            e.manualCalories = Double(manualCalories) ?? 0
            e.manualProtein  = Double(manualProtein)  ?? 0
            e.manualCarbs    = Double(manualCarbs)    ?? 0
            e.manualFat      = Double(manualFat)      ?? 0
        } else if let dish = selectedDish {
            e.dishName              = dish.name
            e.dishServingSize       = dish.servingSize
            e.dishTotalMass         = dish.totalMass
            e.dishCalPerServing     = dish.perServingCalories
            e.dishProteinPerServing = dish.perServingProtein
            e.dishCarbsPerServing   = dish.perServingCarbs
            e.dishFatPerServing     = dish.perServingFat
            e.dishTotalCalories     = dish.totalCalories
            e.dishTotalProtein      = dish.totalProtein
            e.dishTotalCarbs        = dish.totalCarbs
            e.dishTotalFat          = dish.totalFat
            e.dishMacrosConfirmed   = !dish.hasIncompleteMacros
            e.useServingsMode       = useServingsMode
            e.servingsConsumed      = Double(servingsConsumed) ?? 1
            e.massConsumed          = Double(massConsumed) ?? 0
        }

        if entry == nil { modelContext.insert(e) }
        dismiss()
    }

    private func fmt(_ v: Double) -> String {
        v >= 100 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
    private func fmtOpt(_ v: Double) -> String {
        v == 0 ? "" :
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }
}

// MARK: - Dish Picker

struct DishPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let allDishes: [Dish]
    @Binding var selected: Dish?

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(allDishes.enumerated()), id: \.offset) { _, dish in
                    dishRow(dish)
                }
            }
            .overlay {
                if allDishes.isEmpty {
                    ContentUnavailableView("No Dishes", systemImage: "fork.knife",
                        description: Text("Create dishes in the Dishes tab first."))
                }
            }
            .navigationTitle("Select Dish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func dishRow(_ dish: Dish) -> some View {
        Button {
            selected = dish
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dish.name).font(.headline).foregroundStyle(.primary)
                    Text("\(fmt(dish.perServingCalories)) kcal · \(fmt(dish.servingSize))g serving · \(fmt(dish.numberOfServings)) servings total")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if dish.hasIncompleteMacros {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange).font(.caption)
                }
                if isSelectedDish(dish) {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func isSelectedDish(_ dish: Dish) -> Bool {
        guard let sel = selected else { return false }
        return sel.name == dish.name && sel.totalMass == dish.totalMass
    }

    private func fmt(_ v: Double) -> String {
        v >= 100 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
