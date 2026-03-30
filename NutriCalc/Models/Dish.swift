import Foundation
import SwiftData

@Model
final class DishIngredient {
    var id: UUID
    var ingredient: Ingredient?
    var amountUsed: Double
    var dish: Dish?

    var ingredientName: String
    var ingredientServingSize: Double
    var ingredientCalories: Double
    var ingredientProtein: Double
    var ingredientCarbs: Double
    var ingredientFat: Double
    var ingredientMacrosConfirmed: Bool

    init(ingredient: Ingredient, amountUsed: Double) {
        self.id = UUID()
        self.ingredient = ingredient
        self.amountUsed = amountUsed
        self.ingredientName = ingredient.name
        self.ingredientServingSize = ingredient.servingSize
        self.ingredientCalories = ingredient.calories
        self.ingredientProtein = ingredient.protein
        self.ingredientCarbs = ingredient.carbs
        self.ingredientFat = ingredient.fat
        self.ingredientMacrosConfirmed = ingredient.macrosConfirmed
    }

    var scaledCalories: Double {
        guard ingredientServingSize > 0 else { return 0 }
        return ingredientCalories * (amountUsed / ingredientServingSize)
    }

    var scaledProtein: Double {
        guard ingredientServingSize > 0 else { return 0 }
        return ingredientProtein * (amountUsed / ingredientServingSize)
    }

    var scaledCarbs: Double {
        guard ingredientServingSize > 0 else { return 0 }
        return ingredientCarbs * (amountUsed / ingredientServingSize)
    }

    var scaledFat: Double {
        guard ingredientServingSize > 0 else { return 0 }
        return ingredientFat * (amountUsed / ingredientServingSize)
    }

    var hasIncompleteMacros: Bool { !ingredientMacrosConfirmed }
}

@Model
final class Dish {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \DishIngredient.dish)
    var dishIngredients: [DishIngredient]
    var totalMass: Double
    var servingSize: Double

    var isManualEntry: Bool
    var overrideCalories: Double
    var overrideProtein: Double
    var overrideCarbs: Double
    var overrideFat: Double
    var macrosConfirmed: Bool

    init(name: String, totalMass: Double, servingSize: Double, isManualEntry: Bool = false) {
        self.id = UUID()
        self.name = name
        self.dishIngredients = []
        self.totalMass = totalMass
        self.servingSize = servingSize
        self.isManualEntry = isManualEntry
        self.overrideCalories = 0
        self.overrideProtein = 0
        self.overrideCarbs = 0
        self.overrideFat = 0
        self.macrosConfirmed = false
    }

    var totalCalories: Double {
        isManualEntry ? overrideCalories : dishIngredients.reduce(0) { $0 + $1.scaledCalories }
    }
    var totalProtein: Double {
        isManualEntry ? overrideProtein : dishIngredients.reduce(0) { $0 + $1.scaledProtein }
    }
    var totalCarbs: Double {
        isManualEntry ? overrideCarbs : dishIngredients.reduce(0) { $0 + $1.scaledCarbs }
    }
    var totalFat: Double {
        isManualEntry ? overrideFat : dishIngredients.reduce(0) { $0 + $1.scaledFat }
    }

    var servingFactor: Double {
        guard totalMass > 0 else { return 0 }
        return servingSize / totalMass
    }

    var perServingCalories: Double { totalCalories * servingFactor }
    var perServingProtein: Double  { totalProtein  * servingFactor }
    var perServingCarbs: Double    { totalCarbs    * servingFactor }
    var perServingFat: Double      { totalFat      * servingFactor }

    var numberOfServings: Double {
        guard servingSize > 0 else { return 0 }
        return totalMass / servingSize
    }

    var hasIncompleteMacros: Bool {
        if isManualEntry { return !macrosConfirmed }
        return dishIngredients.contains { $0.hasIncompleteMacros }
    }
}
