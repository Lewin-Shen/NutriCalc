import SwiftUI
import SwiftData

struct IngredientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @State private var showingAddForm = false

    var body: some View {
        NavigationStack {
            Group {
                if ingredients.isEmpty {
                    ContentUnavailableView(
                        "No Ingredients",
                        systemImage: "carrot",
                        description: Text("Tap + to add your first ingredient.")
                    )
                } else {
                    List {
                        ForEach(ingredients) { ingredient in
                            NavigationLink {
                                IngredientFormView(ingredient: ingredient)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ingredient.name)
                                            .font(.headline)
                                        Text("Per \(formatted(ingredient.servingSize))g: \(formatted(ingredient.calories)) kcal | P: \(formatted(ingredient.protein))g | C: \(formatted(ingredient.carbs))g | F: \(formatted(ingredient.fat))g")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if ingredient.hasIncompleteMacros {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteIngredients)
                    }
                }
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                NavigationStack {
                    IngredientFormView(ingredient: nil)
                }
            }
        }
    }

    private func deleteIngredients(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(ingredients[index])
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
