import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            IngredientListView()
                .tabItem { Label("Ingredients", systemImage: "carrot") }

            DishListView()
                .tabItem { Label("Dishes", systemImage: "fork.knife") }

            LogView()
                .tabItem { Label("Log", systemImage: "pencil.and.list.clipboard") }

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
        }
    }
}
