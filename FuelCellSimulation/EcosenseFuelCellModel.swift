import Foundation

/// Ecosense PEM Fuel Cell Training System Model
/// Based on lab manual specifications - Page 6
struct EcosenseFuelCellModel {
    // MARK: - Core Specifications (Lab Manual - Page 6)
    let n_cell: Double = 48.0              // Number of cells
    let ratedPower: Double = 1000.0        // Rated Power (W)
    let ratedVoltage: Double = 28.8        // Performance voltage @ 35A
    let ratedCurrent: Double = 35.0        // Performance current @ 28.8V
    let maxFlowRate: Double = 13.0         // Flow rate at max output (L/min)
    let lowVoltageShutdown: Double = 24.0  // Low voltage shutdown (V)
    let overCurrentShutdown: Double = 42.0 // Over current shutdown (A)
    let overTempShutdown: Double = 65.0    // Over temperature shutdown (°C)
    let stackEfficiency: Double = 40.0     // Efficiency @ 28.8V (%)
    
    // MARK: - Physical Constants
    let A: Double = 76.0                   // Active area per cell (cm²)
    let tau_m: Double = 25e-4              // Membrane thickness (cm)
    let lambda_m: Double = 7.0             // Average water content
    let I_loss: Double = 0.3               // Internal current loss (A)
    
    // MARK: - Nernst Equation Parameters
    let E0: Double = 1.229                 // Standard reversible voltage (V)
    let R: Double = 8.314                  // Universal gas constant (J/mol·K)
    let F: Double = 96485.0                // Faraday constant (C/mol)
    let deltaS: Double = 163.3             // Entropy variation (J/mol·K)
    
    // MARK: - Partial Pressures
    let p_H2: Double = 0.5                 // H2 pressure (bar) - range 0.45-0.55
    let p_O2: Double = 0.21                // O2 pressure (bar) - from atmospheric air
    let p_H2O: Double = 1.0                // Water partial pressure (bar)
    
    // MARK: - Activation Loss Parameters (Tafel equation)
    let xi1: Double = -1.00
    let xi2: Double = -0.0034
    let xi3: Double = -0.000078
    let xi4: Double = 0.000185
    
    // MARK: - Concentration Loss Parameters
    let alpha: Double = 0.5
    let n: Double = 4.0
    let concentrationThreshold: Double = 30.0  // Current threshold for concentration losses (A)
    
    /// Calculate all fuel cell parameters for given flow rate and temperature
    /// - Parameters:
    ///   - flowRate: Hydrogen flow rate (L/min)
    ///   - temperature: Stack temperature (K)
    /// - Returns: Tuple containing voltage, current, power, and efficiency
    func calculate(flowRate: Double, temperature: Double) -> (voltage: Double, current: Double, power: Double, efficiency: Double) {
        // Current Calculation
        let I_ext = (flowRate / maxFlowRate) * ratedCurrent
        let I = I_ext + I_loss
        
        // Nernst Voltage (E_TP)
        let term1 = E0
        let term2 = (R * temperature / (2.0 * F)) * log((p_H2 * pow(p_O2, 0.5)) / p_H2O)
        let term3 = (deltaS / (2.0 * F)) * (temperature - 298.15)
        let E_TP = term1 + term2 - term3
        
        // Activation Losses (Tafel equation)
        let C_O2 = p_O2 / (5.08e6 * exp(-498.0 / temperature))
        let deltaV_act: Double
        if I > 0 {
            deltaV_act = xi1 + xi2 * temperature + xi3 * temperature * log(C_O2) + xi4 * temperature * log(I)
        } else {
            deltaV_act = 0
        }
        
        // Ohmic Losses (Nafion membrane)
        let term1_ohm = 181.6 * (1.0 + 0.03 * (I / A) + 0.062 * pow(temperature / 303.0, 2.0) * pow(I / A, 2.5))
        let term2_ohm = (lambda_m - 0.634 - 3.0 * (I / A)) * exp(4.18 * (temperature - 303.0) / 303.0)
        let R_ion = (tau_m / A) * (term1_ohm / term2_ohm)
        let deltaV_ohm = R_ion * I
        
        // Concentration Losses
        let deltaV_con: Double
        if I > concentrationThreshold {
            let I_L = overCurrentShutdown  // Limiting current = over current shutdown
            deltaV_con = ((1.0 + 1.0 / alpha) * R * temperature / (n * F)) * log(I_L / (I_L - I))
        } else {
            deltaV_con = 0
        }
        
        // Cell and Stack Voltage
        let V_cell = E_TP - abs(deltaV_act) - deltaV_ohm - deltaV_con
        let V_stack = V_cell * n_cell
        
        // Apply low voltage shutdown limit
        let finalVoltage = max(V_stack, lowVoltageShutdown)
        
        // Power Calculation
        let power = finalVoltage * I_ext
        
        // Efficiency Calculation (based on H2 lower heating value)
        let Q_LHV_H2 = 120000.0  // Lower heating value of H2 (J/g)
        let rho_H2 = 0.0899      // Density of H2 (g/L)
        let P_H2 = (flowRate / 60000.0) * rho_H2 * Q_LHV_H2  // Input power from H2 (kW)
        
        let efficiency: Double
        if P_H2 > 0 {
            efficiency = (power / (P_H2 * 1000.0)) * 100.0
        } else {
            efficiency = 0
        }
        
        // Clamp efficiency to reasonable range
        let clampedEfficiency = max(0, min(efficiency, 50.0))
        
        return (voltage: finalVoltage, current: I_ext, power: power, efficiency: clampedEfficiency)
    }
    
    /// Check if operating conditions are within safe limits
    /// - Parameters:
    ///   - voltage: Stack voltage (V)
    ///   - current: External current (A)
    ///   - temperature: Stack temperature (°C)
    /// - Returns: Tuple indicating if each parameter is safe
    func checkSafetyLimits(voltage: Double, current: Double, temperature: Double) -> (voltageSafe: Bool, currentSafe: Bool, temperatureSafe: Bool) {
        let voltageSafe = voltage >= lowVoltageShutdown
        let currentSafe = current <= overCurrentShutdown
        let temperatureSafe = temperature <= overTempShutdown
        
        return (voltageSafe: voltageSafe, currentSafe: currentSafe, temperatureSafe: temperatureSafe)
    }
}
