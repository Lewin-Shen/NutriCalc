import SwiftUI
import SwiftData

struct DishListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dish.name) private var dishes: [Dish]
    @State private var showingAddForm = false

    var body: some View {
        NavigationStack {
            Group {
                if dishes.isEmpty {
                    ContentUnavailableView(
                        "No Dishes",
                        systemImage: "fork.knife",
                        description: Text("Tap + to create your first dish.")
                    )
                } else {
                    List {
                        ForEach(dishes) { dish in
                            NavigationLink {
                                DishDetailView(dish: dish)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(dish.name)
                                            .font(.headline)
                                        Text("\(formatted(dish.perServingCalories)) kcal per \(formatted(dish.servingSize))g serving")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if dish.hasIncompleteMacros {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteDishes)
                    }
                }
            }
            .navigationTitle("Dishes")
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
                    DishFormView(dish: nil)
                }
            }
        }
    }

    private func deleteDishes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(dishes[index])
        }
    }

    private func formatted(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
