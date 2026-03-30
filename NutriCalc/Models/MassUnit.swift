import Foundation

enum MassUnit: String, CaseIterable, Codable, Identifiable {
    case g
    case oz
    case lb
    case kg

    var id: String { rawValue }

    var label: String {
        switch self {
        case .g: return "g"
        case .oz: return "oz"
        case .lb: return "lb"
        case .kg: return "kg"
        }
    }

    /// How many grams one unit equals
    var gramsPerUnit: Double {
        switch self {
        case .g: return 1.0
        case .oz: return 28.3495
        case .lb: return 453.592
        case .kg: return 1000.0
        }
    }

    /// Convert a value in this unit to grams
    func toGrams(_ value: Double) -> Double {
        value * gramsPerUnit
    }

    /// Convert a value in grams to this unit
    func fromGrams(_ grams: Double) -> Double {
        guard gramsPerUnit > 0 else { return 0 }
        return grams / gramsPerUnit
    }

    /// Convert between any two units
    static func convert(_ value: Double, from: MassUnit, to: MassUnit) -> Double {
        let grams = from.toGrams(value)
        return to.fromGrams(grams)
    }
}
