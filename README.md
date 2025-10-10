# PEM Fuel Cell Training System - iOS/macOS App

A comprehensive SwiftUI application for PEM Fuel Cell performance analysis based on the **Ecosense Fuel Cell Training System** lab manual specifications.

## 🎯 Overview

This production-ready app implements accurate mathematical models and provides an intuitive interface for analyzing PEM fuel cell performance, specifically designed to match the Ecosense 48-cell, 1000W rated power system.

## 📋 Core Specifications (Lab Manual - Page 6)

- **Type**: PEM Fuel Cell
- **Number of cells**: 48
- **Rated Power**: 1000W
- **Performance**: 28.8V @ 35A
- **H₂ Pressure**: 0.45-0.55 bar
- **Hydrogen purity**: ≥99.995% dry H₂
- **Flow rate at max output**: 13 L/min
- **External temperature**: 5 to 30°C
- **Max stack temperature**: 65°C
- **Efficiency of stack**: 40% @ 28.8V
- **Low voltage shut down**: 24V
- **Over current shut down**: 42A
- **Over temperature shut down**: 65°C
- **Humidification**: Self-humidified
- **Cooling**: Air (integrated cooling fan)

## 🧮 Mathematical Model

### Constants
- `n_cell = 48` (number of cells)
- `A = 76.0` (active area per cell in cm²)
- `tau_m = 25e-4` (membrane thickness in cm)
- `lambda_m = 7.0` (average water content)
- `I_loss = 0.3` (internal current loss in A)

### Nernst Equation Parameters
- `E0 = 1.229` (standard reversible voltage)
- `R = 8.314` (universal gas constant J/mol·K)
- `F = 96485.0` (Faraday constant C/mol)
- `deltaS = 163.3` (entropy variation J/mol·K)

### Partial Pressures
- `p_H2 = 0.5 bar` (H₂ pressure range 0.45-0.55 bar)
- `p_O2 = 0.21 bar` (oxygen from atmospheric air)
- `p_H2O = 1.0 bar` (water partial pressure)

### Voltage Calculation

**Current Calculation:**
```
I_ext = (flowRate / 13.0) * 35.0
I = I_ext + I_loss
```

**Nernst Voltage (E_TP):**
```
E_TP = E0 + (R*T/(2*F)) * ln((p_H2 * p_O2^0.5) / p_H2O) - (deltaS/(2*F)) * (T - 298.15)
```

**Activation Losses (Tafel equation):**
```
C_O2 = p_O2 / (5.08e6 * exp(-498/T))
deltaV_act = xi1 + xi2*T + xi3*T*ln(C_O2) + xi4*T*ln(I)
```
Where: `xi1 = -1.00`, `xi2 = -0.0034`, `xi3 = -0.000078`, `xi4 = 0.000185`

**Ohmic Losses (Nafion membrane):**
```
term1 = 181.6 * (1 + 0.03*(I/A) + 0.062*(T/303)^2*(I/A)^2.5)
term2 = (lambda_m - 0.634 - 3*(I/A)) * exp(4.18*(T-303)/303)
R_ion = (tau_m / A) * (term1 / term2)
deltaV_ohm = R_ion * I
```

**Concentration Losses:**
```
I_L = 42.0 (limiting current = over current shutdown)
alpha = 0.5
n = 4.0
deltaV_con = ((1 + 1/alpha) * R * T / (n * F)) * ln(I_L / (I_L - I)) when I > 30A
```

**Final Voltage:**
```
V_cell = E_TP - |deltaV_act| - deltaV_ohm - deltaV_con
V_stack = V_cell * n_cell
Final voltage = max(V_stack, 24V) (low voltage shutdown limit)
```

**Power and Efficiency:**
```
Power = V_stack * I_ext
Efficiency = (Power / P_H2_input) * 100%
Target efficiency: 40% @ 28.8V
```

## 🎨 Features

### 1. **Ecosense Training System Tab**
The main tab featuring the complete lab manual implementation:

#### Header Section
- Title: "PEM Fuel Cell Training System"
- Subtitle: "Ecosense | 48-Cell Stack | 1000W Rated"
- Blue bolt icon

#### Control Panel
- **Hydrogen Flow Rate Slider**: 0.5 to 15 L/min (step: 0.1)
- **Stack Temperature Slider**: 5°C to 65°C (278K to 338K, step: 1K)
- Real-time caption showing lab manual specifications

#### Live Metric Cards (5 cards with gradients)
- **Voltage (V)** - Blue gradient
- **Current (A)** - Green gradient
- **Power (W)** - Orange gradient
- **Efficiency (%)** - Purple gradient
- **Temperature (°C)** - Red gradient

#### Action Buttons
- **Record Button**: Record up to 7 readings (shows count)
- **Export Button**: Export data to CSV (only visible when data exists)
- **Clear Button**: Clear all recorded data (only visible when data exists)

#### Data Table (Experiment No. 2 format)
- Title: "Recorded Observations (Experiment No. 2)"
- Subtitle: "Output power variation of fuel cell with change in Hydrogen supply"
- Columns: S.No., Current (A), Voltage (V), Power (W), H₂ Flow Rate (L/min), Efficiency (%), Action
- Alternating row colors
- Horizontal scrollable
- Delete button for each row
- Auto-reassigns serial numbers after deletion

#### Performance Charts (Three separate charts)
- **Chart 1**: Current vs. Hydrogen Flow Rate (Green line with dots)
- **Chart 2**: Voltage vs. Hydrogen Flow Rate (Blue line with dots)
- **Chart 3**: Power vs. Hydrogen Flow Rate (Orange line with dots)
- All charts use 3px line width and symbol size 80

#### Specifications Section
Displays all lab manual specifications in grid cards:
- Cells: 48
- Rated Power: 1000 W
- Performance: 28.8V @ 35A
- H₂ Pressure: 0.45-0.55 bar
- Stack Efficiency: 40%
- Low V Shutdown: 24 V
- Over Current: 42 A
- Over Temp: 65°C

#### Footer
"Ecosense Sustainable Solutions Pvt. Ltd."

### 2. **Performance Analyzer Tab**
Alternative fuel cell simulator with different parameters.

### 3. **Basic Simulator Tab**
Simple fuel cell simulation interface.

## 📊 Data Management

### FuelCellReading Structure
```swift
struct FuelCellReading: Identifiable, Codable {
    let id: UUID
    let serialNumber: Int
    let flowRate: Double        // L/min
    let voltage: Double         // V
    let current: Double         // A
    let power: Double           // W
    let efficiency: Double      // %
    let temperature: Double     // °C
}
```

### Features
- ✅ Record up to 7 readings maximum
- ✅ Prevent duplicate flow rates (within 0.1 L/min tolerance)
- ✅ Auto-sort by flow rate
- ✅ Auto-reassign serial numbers after deletion
- ✅ CSV export with lab manual format

### CSV Export Format
```
S.No.,Hydrogen Flow Rate (L/min),Current (A),Voltage (V),Power (W),Efficiency (%),Temperature (°C)
1,5.0,13.46,28.32,381.23,35.67,30.0
2,8.5,21.88,27.89,610.45,38.21,30.0
...
```

File saved to: `Documents/fuel_cell_experiment_data.csv`

## 🎯 Error Handling & Alerts

- ✅ Alert when trying to record duplicate flow rate
- ✅ Alert when maximum 7 readings reached
- ✅ Alert on successful CSV export with file path
- ✅ Alert on export failure with error message

## 🎨 Design Guidelines

### Color Scheme
- **Blue**: Voltage measurements
- **Green**: Current measurements
- **Orange**: Power measurements
- **Purple**: Efficiency measurements
- **Red**: Temperature measurements
- **Gray**: Borders and backgrounds

### Styling
- White cards with rounded corners (15px)
- Shadow radius: 5
- Gradients for metric cards
- Grid layouts for responsive design
- Proper spacing between sections (20px)
- iOS design guidelines compliant

## 🛠 Technical Stack

- **Framework**: SwiftUI
- **Charts**: SwiftUI Charts framework
- **Minimum iOS**: iOS 16+
- **Minimum macOS**: macOS 14.2+
- **Language**: Swift 5

## 📁 Project Structure

```
FuelCellSimulation/
├── FuelCellSimulationApp.swift          # App entry point with TabView
├── EcosenseFuelCellView.swift           # Main Ecosense training system view
├── EcosenseFuelCellModel.swift          # Mathematical model implementation
├── FuelCellReading.swift                # Data model for readings
├── PEMFuelCellSimulator.swift           # Alternative simulator
├── ContentView.swift                    # Basic simulator
├── FuelCellModel.swift                  # Alternative model
├── chartView.swift                      # Chart visualization
├── dataentryview.swift                  # Data entry utilities
└── loadData.swift                       # Data loading utilities
```

## 🚀 Building & Running

### Requirements
- Xcode 15.2 or later
- macOS 14.2 or later
- Swift 5

### Build Instructions
```bash
cd /Users/imacu20/Desktop/FuelCellSimulation
xcodebuild -project FuelCellSimulation.xcodeproj -scheme FuelCellSimulation -destination 'platform=macOS' build
```

### Run Instructions
```bash
open /Users/imacu20/Library/Developer/Xcode/DerivedData/FuelCellSimulation-*/Build/Products/Debug/FuelCellSimulation.app
```

Or simply open the project in Xcode and press `Cmd+R`.

## 📖 Usage Guide

### Recording Data
1. Adjust the **Hydrogen Flow Rate** slider (0.5-15 L/min)
2. Adjust the **Stack Temperature** slider (5-65°C)
3. Observe live metrics updating in real-time
4. Click **Record** button to save the current reading
5. Repeat for up to 7 different flow rates

### Viewing Results
- Recorded data appears in the **Data Table**
- Three **Performance Charts** automatically update
- Charts show relationships between flow rate and Current/Voltage/Power

### Exporting Data
1. Click the **Export** button
2. Data is saved as CSV to Documents folder
3. Alert shows the exact file path
4. Open in Excel, Numbers, or any spreadsheet application

### Clearing Data
- Click the **Clear** button to remove all recorded readings
- Charts and table will be hidden until new data is recorded

## 🔬 Lab Manual Compliance

This app is specifically designed to match the **Ecosense Fuel Cell Training System** lab manual:
- ✅ Exact specifications from Page 6
- ✅ Accurate mathematical models
- ✅ Experiment No. 2 table format
- ✅ Safety limits (voltage, current, temperature)
- ✅ Professional UI matching lab equipment

## 📝 License

This project is created for educational purposes based on the Ecosense Fuel Cell Training System lab manual.

## 👥 Credits

**Ecosense Sustainable Solutions Pvt. Ltd.** - Original fuel cell system and lab manual specifications.

---

**Built with ❤️ using SwiftUI**
