# NutriCalc

A macro nutrition tracking app for iOS built with SwiftUI and SwiftData.

---

## Features

### Ingredients
- Define ingredients with their macro nutrition facts (calories, protein, carbs, fat) per serving size
- Supports mass unit input in **g, oz, lb, kg**
- Warning indicator for ingredients saved without fully confirmed macro data
- Calories are required — all other macros are optional

### Dishes
- Build dishes by combining ingredients at specific amounts
- Or enter whole-dish macros directly (great for packaged food like protein bars)
- Live per-serving macro preview as you build
- Adjust serving size at any time from the dish detail view
- Calculates per-serving macros based on total dish mass and serving size

### Daily Log
- Log food from your saved dishes or enter a quick manual estimate
- Dish entries support **servings mode** (default) or **mass consumed** mode
- Dashboard showing today's total calories, protein, carbs, and fat
- Set optional daily goals for any combination of the 4 macros — with progress bars and remaining/over indicators
- Goals can be updated or removed at any time
- Swipe left to delete any log entry; tap to edit

### History
- Browse all past days with total macro summaries
- Expand any day to see every individual entry

### Settings
- Toggle timestamps on log entries (one-time preference)

---

## Tech Stack

| | |
|---|---|
| **Platform** | iOS 17+ |
| **UI** | SwiftUI |
| **Persistence** | SwiftData |
| **Language** | Swift 5 |

---

## Getting Started

1. Clone the repo
2. Open `NutriCalc.xcodeproj` in Xcode
3. Select a simulator or connected iPhone as the run target
4. Hit **Cmd+R**

No third-party dependencies — runs entirely on-device.

---

## Screenshots

*Coming soon*
