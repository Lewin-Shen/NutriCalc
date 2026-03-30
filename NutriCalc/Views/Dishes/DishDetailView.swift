import SwiftUI

struct DishDetailView: View {
    @Bindable var dish: Dish
    @State private var showingEditForm = false
    @State private var servingSizeText: String = ""
    @State private var servingUnit: MassUnit = .g

    var body: some View {
        List {
            Section {
                MacroBarView(
                    calories: dish.perServingCalories,
                    protein: dish.perServingProtein,
                    carbs: dish.perServingCarbs,
                    fat: dish.perServingFat,
                    label: "Per \(formatted(dish.servingSize))g Serving",
                    showWarning: dish.hasIncompleteMacros
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Serving Size") {
                HStack {
                    Text("Serving")
                    Spacer()
                    TextField("0", text: $servingSizeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .onChange(of: servingSizeText) { _, newValue in
                            let displayVal = Double(newValue) ?? 0
                            dish.servingSize = servingUnit.toGrams(displayVal)
                        }
                    Menu {
                        ForEach(MassUnit.allCases) { unit in
                            Button {
                                switchServingUnit(to: unit)
                            } label: {
                                HStack {
                                    Text(unit.label)
                                    if unit == servingUnit {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Text(servingUnit.label)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .leading)
                    }
                }

                LabeledContent("Servings", value: formatted(dish.numberOfServings))
            }

            Section("Dish Info") {
                LabeledContent("Total Mass", value: "\(formatted(dish.totalMass))g")
                if dish.isManualEntry {
                    LabeledContent("Entry Mode", value: "Manual")
                }
            }

            Section("Total Macros (Whole Dish)") {
                LabeledContent("Calories", value: "\(formatted(dish.totalCalories)) kcal")
                LabeledContent("Protein", value: "\(formatted(dish.totalProtein))g")
                LabeledContent("Carbs", value: "\(formatted(dish.totalCarbs))g")
                LabeledContent("Fat", value: "\(formatted(dish.totalFat))g")
            }

            if !dish.isManualEntry && !dish.dishIngredients.isEmpty {
                Section("Ingredients") {
                    ForEach(dish.dishIngredients) { di in
                        HStack {
                            Text(di.ingredientName)
                            if di.hasIncompleteMacros {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption2)
                            }
                            Spacer()
                            Text("\(formatted(di.amountUsed))g")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(dish.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationStack {
                DishFormView(dish: dish)
            }
        }
        .onAppear {
            servingSizeText = formatDisplay(servingUnit.fromGrams(dish.servingSize))
        }
    }

    private func switchServingUnit(to newUnit: MassUnit) {
        servingUnit = newUnit
        servingSizeText = formatDisplay(newUnit.fromGrams(dish.servingSize))
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func formatDisplay(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.truncatingRemainder(dividingBy: 1) < 0.01 {
            return String(format: "%.0f", value)
        } else if value < 10 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}
