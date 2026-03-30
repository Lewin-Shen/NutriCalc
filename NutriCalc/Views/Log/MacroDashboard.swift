import SwiftUI

struct MacroDashboard: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    @AppStorage("goalCalEnabled")     var goalCalEnabled     = false
    @AppStorage("goalCal")            var goalCal            = 2000.0
    @AppStorage("goalProteinEnabled") var goalProteinEnabled = false
    @AppStorage("goalProtein")        var goalProtein        = 150.0
    @AppStorage("goalCarbEnabled")    var goalCarbEnabled    = false
    @AppStorage("goalCarb")           var goalCarb           = 250.0
    @AppStorage("goalFatEnabled")     var goalFatEnabled     = false
    @AppStorage("goalFat")            var goalFat            = 65.0

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MacroTile(label: "Calories", unit: "kcal",
                          consumed: calories,
                          goal: goalCalEnabled ? goalCal : nil,
                          color: .orange)
                MacroTile(label: "Protein", unit: "g",
                          consumed: protein,
                          goal: goalProteinEnabled ? goalProtein : nil,
                          color: .red)
            }
            HStack(spacing: 12) {
                MacroTile(label: "Carbs", unit: "g",
                          consumed: carbs,
                          goal: goalCarbEnabled ? goalCarb : nil,
                          color: .blue)
                MacroTile(label: "Fat", unit: "g",
                          consumed: fat,
                          goal: goalFatEnabled ? goalFat : nil,
                          color: .yellow)
            }
        }
        .padding(.horizontal)
    }
}

private struct MacroTile: View {
    let label: String
    let unit: String
    let consumed: Double
    let goal: Double?
    let color: Color

    private var remaining: Double? {
        guard let goal else { return nil }
        return goal - consumed
    }

    private var progress: Double {
        guard let goal, goal > 0 else { return 0 }
        return min(consumed / goal, 1.0)
    }

    private var tileColor: Color {
        guard let rem = remaining else { return color }
        if rem < 0 { return .red }
        if rem < (goal ?? 0) * 0.1 { return .orange }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let rem = remaining {
                    Text(rem >= 0 ? "\(fmt(rem)) left" : "\(fmt(-rem)) over")
                        .font(.caption2)
                        .foregroundStyle(rem < 0 ? .red : .secondary)
                }
            }

            Text("\(fmt(consumed))")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(tileColor)
            + Text(" \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let goal {
                VStack(alignment: .leading, spacing: 2) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tileColor)
                                .frame(width: geo.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("of \(fmt(goal)) \(unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func fmt(_ v: Double) -> String {
        v >= 100
            ? String(format: "%.0f", v)
            : String(format: "%.1f", v)
    }
}
