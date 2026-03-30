import Foundation
import SwiftData

@Model
final class Ingredient {
    var id: UUID
    var name: String
    var servingSize: Double
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    /// True once the user has saved this ingredient via the form — distinguishes
    /// "intentionally left at zero" from "never filled in".
    var macrosConfirmed: Bool

    init(name: String, servingSize: Double, calories: Double, protein: Double, carbs: Double, fat: Double, macrosConfirmed: Bool = false) {
        self.id = UUID()
        self.name = name
        self.servingSize = servingSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.macrosConfirmed = macrosConfirmed
    }

    var hasIncompleteMacros: Bool { !macrosConfirmed }
}
