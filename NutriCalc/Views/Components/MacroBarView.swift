import SwiftUI

struct MacroBarView: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    var label: String = "Per Serving"
    var showWarning: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)

            HStack(spacing: 16) {
                MacroItem(value: calories, unit: "kcal", name: "Calories", color: .orange)
                MacroItem(value: protein, unit: "g", name: "Protein", color: .red)
                MacroItem(value: carbs, unit: "g", name: "Carbs", color: .blue)
                MacroItem(value: fat, unit: "g", name: "Fat", color: .yellow)
            }

            if showWarning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Some macro values are zero — data may be incomplete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct MacroItem: View {
    let value: Double
    let unit: String
    let name: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(formatted)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var formatted: String {
        if value >= 100 {
            return String(format: "%.0f", value)
        } else if value >= 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}
