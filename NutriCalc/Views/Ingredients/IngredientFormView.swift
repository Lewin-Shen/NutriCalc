import SwiftUI
import SwiftData

struct IngredientFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let ingredient: Ingredient?

    @State private var name: String = ""
    @State private var servingSize: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    private var isEditing: Bool { ingredient != nil }

    private var caloriesValue: Double { Double(calories) ?? 0 }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(servingSize) ?? 0) > 0
            && caloriesValue > 0
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("e.g. Chicken Breast", text: $name)
            }

            Section("Serving Size") {
                MassInputView(label: "", grams: $servingSize)
            }

            Section {
                macroField("Calories (kcal)", text: $calories, required: true)
                macroField("Protein (g)", text: $protein)
                macroField("Carbs (g)", text: $carbs)
                macroField("Fat (g)", text: $fat)
            } header: {
                Text("Macros (per serving size above)")
            } footer: {
                if caloriesValue == 0 && !calories.isEmpty {
                    Text("Calories cannot be zero.")
                        .foregroundStyle(.red)
                } else if calories.isEmpty {
                    Text("Calories are required.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Ingredient" : "New Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!isValid)
            }
        }
        .onAppear {
            if let ingredient {
                name = ingredient.name
                servingSize = formatNum(ingredient.servingSize)
                calories = formatNum(ingredient.calories)
                protein = formatNum(ingredient.protein)
                carbs = formatNum(ingredient.carbs)
                fat = formatNum(ingredient.fat)
            }
        }
    }

    @ViewBuilder
    private func macroField(_ label: String, text: Binding<String>, required: Bool = false) -> some View {
        HStack {
            Text(label)
            if required {
                Text("*").foregroundStyle(.red).font(.caption)
            }
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let s   = Double(servingSize) ?? 0
        let cal = Double(calories) ?? 0
        let p   = Double(protein)  ?? 0
        let c   = Double(carbs)    ?? 0
        let f   = Double(fat)      ?? 0

        if let ingredient {
            ingredient.name = trimmedName
            ingredient.servingSize = s
            ingredient.calories = cal
            ingredient.protein = p
            ingredient.carbs = c
            ingredient.fat = f
            ingredient.macrosConfirmed = true
        } else {
            let ing = Ingredient(name: trimmedName, servingSize: s, calories: cal,
                                 protein: p, carbs: c, fat: f, macrosConfirmed: true)
            modelContext.insert(ing)
        }
        dismiss()
    }

    private func formatNum(_ value: Double) -> String {
        value == 0 ? "" :
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
