import SwiftUI

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("goalCalEnabled")     var goalCalEnabled     = false
    @AppStorage("goalCal")            var goalCal            = 2000.0
    @AppStorage("goalProteinEnabled") var goalProteinEnabled = false
    @AppStorage("goalProtein")        var goalProtein        = 150.0
    @AppStorage("goalCarbEnabled")    var goalCarbEnabled    = false
    @AppStorage("goalCarb")           var goalCarb           = 250.0
    @AppStorage("goalFatEnabled")     var goalFatEnabled     = false
    @AppStorage("goalFat")            var goalFat            = 65.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goals") {
                    GoalRow(label: "Calories", unit: "kcal", enabled: $goalCalEnabled,
                            value: $goalCal, color: .orange)
                    GoalRow(label: "Protein",  unit: "g",    enabled: $goalProteinEnabled,
                            value: $goalProtein, color: .red)
                    GoalRow(label: "Carbs",    unit: "g",    enabled: $goalCarbEnabled,
                            value: $goalCarb, color: .blue)
                    GoalRow(label: "Fat",      unit: "g",    enabled: $goalFatEnabled,
                            value: $goalFat, color: .yellow)
                }

                Section {
                    Button(role: .destructive) {
                        goalCalEnabled = false
                        goalProteinEnabled = false
                        goalCarbEnabled = false
                        goalFatEnabled = false
                    } label: {
                        Label("Remove All Goals", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct GoalRow: View {
    let label: String
    let unit: String
    @Binding var enabled: Bool
    @Binding var value: Double
    let color: Color

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .tint(color)

            Text(label)
                .foregroundStyle(enabled ? .primary : .secondary)

            Spacer()

            if enabled {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .onChange(of: text) { _, v in
                        if let d = Double(v) { value = d }
                    }
                Text(unit).foregroundStyle(.secondary)
            }
        }
        .onAppear {
            text = value.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", value)
                : String(format: "%.1f", value)
        }
        .onChange(of: enabled) { _, isOn in
            if isOn {
                text = value.truncatingRemainder(dividingBy: 1) == 0
                    ? String(format: "%.0f", value)
                    : String(format: "%.1f", value)
            }
        }
    }
}
