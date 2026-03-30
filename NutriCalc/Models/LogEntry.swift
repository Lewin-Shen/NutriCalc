import Foundation
import SwiftData

@Model
final class LogEntry {
    var id: UUID
    var date: Date
    var name: String        // optional label; empty = unnamed

    // Source
    var isManual: Bool

    // Dish snapshot fields (populated when !isManual)
    var dishName: String
    var dishServingSize: Double
    var dishTotalMass: Double
    var dishCalPerServing: Double
    var dishProteinPerServing: Double
    var dishCarbsPerServing: Double
    var dishFatPerServing: Double
    var dishTotalCalories: Double
    var dishTotalProtein: Double
    var dishTotalCarbs: Double
    var dishTotalFat: Double
    var dishMacrosConfirmed: Bool

    // Consumption (dish mode)
    var useServingsMode: Bool   // true = servings count, false = mass consumed
    var servingsConsumed: Double
    var massConsumed: Double    // grams

    // Manual estimate fields
    var manualCalories: Double
    var manualProtein: Double
    var manualCarbs: Double
    var manualFat: Double
    var macrosConfirmed: Bool   // true once user has saved the form

    init(date: Date = .now, name: String = "") {
        self.id = UUID()
        self.date = date
        self.name = name
        self.isManual = true
        self.dishName = ""
        self.dishServingSize = 0
        self.dishTotalMass = 0
        self.dishCalPerServing = 0
        self.dishProteinPerServing = 0
        self.dishCarbsPerServing = 0
        self.dishFatPerServing = 0
        self.dishTotalCalories = 0
        self.dishTotalProtein = 0
        self.dishTotalCarbs = 0
        self.dishTotalFat = 0
        self.dishMacrosConfirmed = true
        self.useServingsMode = true
        self.servingsConsumed = 1
        self.massConsumed = 0
        self.manualCalories = 0
        self.manualProtein = 0
        self.manualCarbs = 0
        self.manualFat = 0
        self.macrosConfirmed = false
    }

    // MARK: - Computed totals

    var totalCalories: Double {
        if isManual { return manualCalories }
        if useServingsMode {
            return dishCalPerServing * servingsConsumed
        } else {
            guard dishTotalMass > 0 else { return 0 }
            return dishTotalCalories * (massConsumed / dishTotalMass)
        }
    }

    var totalProtein: Double {
        if isManual { return manualProtein }
        if useServingsMode {
            return dishProteinPerServing * servingsConsumed
        } else {
            guard dishTotalMass > 0 else { return 0 }
            return dishTotalProtein * (massConsumed / dishTotalMass)
        }
    }

    var totalCarbs: Double {
        if isManual { return manualCarbs }
        if useServingsMode {
            return dishCarbsPerServing * servingsConsumed
        } else {
            guard dishTotalMass > 0 else { return 0 }
            return dishTotalCarbs * (massConsumed / dishTotalMass)
        }
    }

    var totalFat: Double {
        if isManual { return manualFat }
        if useServingsMode {
            return dishFatPerServing * servingsConsumed
        } else {
            guard dishTotalMass > 0 else { return 0 }
            return dishTotalFat * (massConsumed / dishTotalMass)
        }
    }

    var hasIncompleteMacros: Bool {
        if isManual { return !macrosConfirmed }
        return !dishMacrosConfirmed
    }

    /// "YYYY-MM-DD" used for day-level grouping
    var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static var todayKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }
}
