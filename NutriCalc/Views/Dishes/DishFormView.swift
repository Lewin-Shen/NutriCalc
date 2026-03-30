import SwiftUI
import SwiftData

struct DishFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Ingredient.name) private var allIngredients: [Ingredient]

    let dish: Dish?

    @State private var name: String = ""
    @State private var totalMass: String = ""
    @State private var servingSize: String = ""
    @State private var entries: [IngredientEntry] = []
    @State private var showingIngredientPicker = false

    @State private var isManualEntry: Bool = false
    @State private var manualCalories: String = ""
    @State private var manualProtein: String = ""
    @State private var manualCarbs: String = ""
    @State private var manualFat: String = ""

    private var isEditing: Bool { dish != nil }

    private var manualCaloriesValue: Double { Double(manualCalories) ?? 0 }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              (Double(totalMass) ?? 0) > 0,
              (Double(servingSize) ?? 0) > 0 else { return false }
        if isManualEntry {
            return manualCaloriesValue > 0
        }
        return !entries.isEmpty
    }

    private var liveFactor: Double {
        let tm = Double(totalMass) ?? 0
        let ss = Double(servingSize) ?? 0
        guard tm > 0 else { return 0 }
        return ss / tm
    }

    // Ingredient-mode live totals
    private func liveTotal(_ kp: KeyPath<Ingredient, Double>) -> Double {
        entries.reduce(0) { sum, entry in
            guard entry.ingredient.servingSize > 0 else { return sum }
            let amt = Double(entry.amount) ?? 0
            return sum + entry.ingredient[keyPath: kp] * (amt / entry.ingredient.servingSize)
        }
    }

    var body: some View {
        Form {
            Section("Dish Name") {
                TextField("e.g. Garlic Chicken", text: $name)
            }

            Section {
                Picker("Entry Mode", selection: $isManualEntry) {
                    Text("From Ingredients").tag(false)
                    Text("Enter Macros Directly").tag(true)
                }
                .pickerStyle(.segmented)
            }

            if isManualEntry {
                Section {
                    manualMacroField("Calories (kcal)", text: $manualCalories, required: true)
                    manualMacroField("Protein (g)",     text: $manualProtein)
                    manualMacroField("Carbs (g)",       text: $manualCarbs)
                    manualMacroField("Fat (g)",         text: $manualFat)
                } header: {
                    Text("Whole-Dish Macros (total for entire dish)")
                } footer: {
                    if manualCaloriesValue == 0 && !manualCalories.isEmpty {
                        Text("Calories cannot be zero.").foregroundStyle(.red)
                    } else if manualCalories.isEmpty {
                        Text("Calories are required.").foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    ForEach($entries) { $entry in
                        HStack {
                            Text(entry.ingredient.name).lineLimit(1)
                            Spacer()
                            MassInputView(label: "", grams: $entry.amount)
                        }
                    }
                    .onDelete { offsets in entries.remove(atOffsets: offsets) }
                    Button { showingIngredientPicker = true } label: {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Ingredients Used")
                } footer: {
                    if allIngredients.isEmpty {
                        Text("Add ingredients in the Ingredients tab first.")
                    }
                }
            }

            Section("Finished Dish") {
                MassInputView(label: "Total Mass",    grams: $totalMass)
                MassInputView(label: "Serving Size",  grams: $servingSize)
            }

            // Live preview
            if liveFactor > 0 {
                let cal = isManualEntry ? (Double(manualCalories) ?? 0) : liveTotal(\.calories)
                let pro = isManualEntry ? (Double(manualProtein)  ?? 0) : liveTotal(\.protein)
                let crb = isManualEntry ? (Double(manualCarbs)    ?? 0) : liveTotal(\.carbs)
                let fat = isManualEntry ? (Double(manualFat)      ?? 0) : liveTotal(\.fat)
                let hasEntries = isManualEntry ? !manualCalories.isEmpty : !entries.isEmpty

                if hasEntries {
                    Section("Live Preview") {
                        MacroBarView(
                            calories: cal * liveFactor,
                            protein:  pro * liveFactor,
                            carbs:    crb * liveFactor,
                            fat:      fat * liveFactor,
                            label:    "Per \(formatNum(Double(servingSize) ?? 0))g Serving"
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Dish" : "New Dish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }.disabled(!isValid)
            }
        }
        .sheet(isPresented: $showingIngredientPicker) {
            IngredientPickerView(allIngredients: allIngredients, entries: $entries)
        }
        .onAppear { loadFromDish() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func manualMacroField(_ label: String, text: Binding<String>, required: Bool = false) -> some View {
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

    private func loadFromDish() {
        guard let dish else { return }
        name = dish.name
        totalMass = formatNum(dish.totalMass)
        servingSize = formatNum(dish.servingSize)
        isManualEntry = dish.isManualEntry
        if dish.isManualEntry {
            manualCalories = formatNum(dish.overrideCalories)
            manualProtein  = formatNum(dish.overrideProtein)
            manualCarbs    = formatNum(dish.overrideCarbs)
            manualFat      = formatNum(dish.overrideFat)
        } else {
            entries = dish.dishIngredients.map { di in
                let ing = di.ingredient ?? Ingredient(
                    name: di.ingredientName, servingSize: di.ingredientServingSize,
                    calories: di.ingredientCalories, protein: di.ingredientProtein,
                    carbs: di.ingredientCarbs, fat: di.ingredientFat, macrosConfirmed: di.ingredientMacrosConfirmed)
                return IngredientEntry(ingredient: ing, amount: formatNum(di.amountUsed))
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let tm = Double(totalMass) ?? 0
        let ss = Double(servingSize) ?? 0

        if let dish {
            dish.name = trimmedName; dish.totalMass = tm; dish.servingSize = ss
            dish.isManualEntry = isManualEntry; dish.macrosConfirmed = true
            if isManualEntry {
                dish.overrideCalories = Double(manualCalories) ?? 0
                dish.overrideProtein  = Double(manualProtein)  ?? 0
                dish.overrideCarbs    = Double(manualCarbs)    ?? 0
                dish.overrideFat      = Double(manualFat)      ?? 0
                dish.dishIngredients.forEach { modelContext.delete($0) }
                dish.dishIngredients = []
            } else {
                dish.overrideCalories = 0; dish.overrideProtein = 0
                dish.overrideCarbs = 0;    dish.overrideFat = 0
                dish.dishIngredients.forEach { modelContext.delete($0) }
                dish.dishIngredients = []
                applyEntries(to: dish)
            }
        } else {
            let newDish = Dish(name: trimmedName, totalMass: tm, servingSize: ss, isManualEntry: isManualEntry)
            newDish.macrosConfirmed = true
            modelContext.insert(newDish)
            if isManualEntry {
                newDish.overrideCalories = Double(manualCalories) ?? 0
                newDish.overrideProtein  = Double(manualProtein)  ?? 0
                newDish.overrideCarbs    = Double(manualCarbs)    ?? 0
                newDish.overrideFat      = Double(manualFat)      ?? 0
            } else {
                applyEntries(to: newDish)
            }
        }
        dismiss()
    }

    private func applyEntries(to dish: Dish) {
        for entry in entries {
            let amt = Double(entry.amount) ?? 0
            let di = DishIngredient(ingredient: entry.ingredient, amountUsed: amt)
            di.dish = dish
            dish.dishIngredients.append(di)
        }
    }

    private func formatNum(_ value: Double) -> String {
        value == 0 ? "" :
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

// MARK: - Supporting types (shared with LogEntryFormView)

struct IngredientEntry: Identifiable {
    let id = UUID()
    let ingredient: Ingredient
    var amount: String
}

struct IngredientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let allIngredients: [Ingredient]
    @Binding var entries: [IngredientEntry]

    var body: some View {
        NavigationStack {
            List {
                if allIngredients.isEmpty {
                    ContentUnavailableView("No Ingredients", systemImage: "carrot",
                        description: Text("Create ingredients in the Ingredients tab first."))
                } else {
                    ForEach(allIngredients) { ingredient in
                        Button {
                            entries.append(IngredientEntry(ingredient: ingredient, amount: ""))
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ingredient.name).font(.headline).foregroundStyle(.primary)
                                    Text("Per \(fmt(ingredient.servingSize))g · \(fmt(ingredient.calories)) kcal")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if ingredient.hasIncompleteMacros {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange).font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pick Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", v) : String(format: "%.1f", v)
    }
}
