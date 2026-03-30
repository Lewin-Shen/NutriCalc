import SwiftUI

/// A text field with an inline unit picker. Stores/returns value in grams.
struct MassInputView: View {
    let label: String
    /// The value in grams (source of truth)
    @Binding var grams: String
    @State private var selectedUnit: MassUnit = .g
    @State private var displayValue: String = ""
    @State private var isUpdating = false

    var body: some View {
        HStack {
            if !label.isEmpty {
                Text(label)
                Spacer()
            }
            TextField("0", text: $displayValue)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .onChange(of: displayValue) { _, newValue in
                    guard !isUpdating else { return }
                    // Convert display value back to grams
                    let numericValue = Double(newValue) ?? 0
                    let gramsValue = selectedUnit.toGrams(numericValue)
                    isUpdating = true
                    grams = formatNum(gramsValue)
                    isUpdating = false
                }
            Menu {
                ForEach(MassUnit.allCases) { unit in
                    Button {
                        switchUnit(to: unit)
                    } label: {
                        HStack {
                            Text(unit.label)
                            if unit == selectedUnit {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(selectedUnit.label)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
            }
        }
        .onAppear {
            // Initialize display from grams binding
            let gramsValue = Double(grams) ?? 0
            displayValue = formatDisplay(selectedUnit.fromGrams(gramsValue))
        }
        .onChange(of: grams) { _, newValue in
            guard !isUpdating else { return }
            let gramsValue = Double(newValue) ?? 0
            isUpdating = true
            displayValue = formatDisplay(selectedUnit.fromGrams(gramsValue))
            isUpdating = false
        }
    }

    private func switchUnit(to newUnit: MassUnit) {
        let gramsValue = Double(grams) ?? 0
        selectedUnit = newUnit
        displayValue = formatDisplay(newUnit.fromGrams(gramsValue))
    }

    private func formatDisplay(_ value: Double) -> String {
        if value == 0 { return "" }
        if value.truncatingRemainder(dividingBy: 1) < 0.01 {
            return String(format: "%.0f", value)
        } else if value < 10 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func formatNum(_ value: Double) -> String {
        if value == 0 { return "" }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}
