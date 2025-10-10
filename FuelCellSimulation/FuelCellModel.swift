import Foundation

struct PEMFuelCellModel {
    // Stack/config parameters (tweak as needed)
    var numberOfCells: Int = 50                // cells in series
    var activeArea_cm2: Double = 100           // per cell active area
    var temperature_K: Double = 298.15         // 25 C
    var pressure_atm: Double = 1.0             // ambient

    // Kinetics/transport params (per cell)
    var reversibleVoltage_perCell: Double = 1.23        // approx at standard conditions
    var tafelSlope_V_per_dec: Double = 0.05             // cathode-dominant Tafel slope (b)
    var exchangeCurrent_A_per_cm2: Double = 1e-6        // i0
    var areaSpecificResistance_Ohm_cm2: Double = 0.2    // ASR
    var limitingCurrentDensity_A_per_cm2: Double = 2.0  // i_lim

    // Utilization: fraction of supplied H2 that reacts (rest unused/purged)
    var hydrogenUtilization: Double = 0.8

    // Physical constants
    private let F: Double = 96485.33212  // C/mol (Faraday)
    private let R: Double = 8.314462618  // J/(mol·K)

    // Gas molar volume at ~25 C, 1 atm (L/mol). For a more exact model, use ideal gas: Vm = R*T/P
    private var molarVolume_L_per_mol: Double {
        // Vm = (R*T)/P, with R = 0.082057 L·atm/(mol·K)
        let R_L_atm = 0.082057
        return R_L_atm * temperature_K / pressure_atm
    }

    // Main API: given flow rates in L/min, compute (flow, current, voltage, power)
    func simulate(forFlowRates flowRates_L_per_min: [Double]) -> [(flow: Double, current: Double, voltage: Double, power: Double)] {
        flowRates_L_per_min.map { flow in
            // Convert H2 volumetric flow (L/min) -> mol/s
            let n_H2_in_mol_per_s = (flow / molarVolume_L_per_mol) / 60.0
            // Max current available from H2 feed given utilization (I = 2F * n_H2_consumed)
            let I_max_from_flow = 2.0 * F * n_H2_in_mol_per_s * hydrogenUtilization

            // Also enforce transport limit: I_lim = i_lim * A
            let I_lim_transport = limitingCurrentDensity_A_per_cm2 * activeArea_cm2

            // Choose operating current: limited by feed and transport
            let I_operating = max(0.0, min(I_max_from_flow, I_lim_transport * 0.999)) // slight margin from i_lim

            // Compute stack voltage at this current
            let V_stack = stackVoltage(forCurrent: I_operating)
            let P_stack = I_operating * V_stack

            return (flow: flow, current: I_operating, voltage: V_stack, power: P_stack)
        }
    }

    // MARK: - Voltage Model
    private func stackVoltage(forCurrent I: Double) -> Double {
        let i = currentDensity(I: I) // A/cm^2
        if i <= 0 {
            return Double(numberOfCells) * reversibleVoltage_perCell
        }

        // Nernst adjustment (simple): use provided reversibleVoltage_perCell as baseline
        // For added realism, you could add small dependence on pressure/temperature.
        let E = reversibleVoltage_perCell

        // Activation losses (Tafel): eta_act = b * log10(i/i0)
        let eta_act_perCell: Double = tafelSlope_V_per_dec * log10Safe(i / exchangeCurrent_A_per_cm2)

        // Ohmic losses: eta_ohm = i * ASR
        let eta_ohm_perCell: Double = i * areaSpecificResistance_Ohm_cm2

        // Concentration losses: eta_conc = -m * ln(1 - i/i_lim). Use m ≈ 0.03 V typical
        let m_conc: Double = 0.03
        let i_ratio = min(i / limitingCurrentDensity_A_per_cm2, 0.999)
        let eta_conc_perCell: Double = -m_conc * logSafe(1.0 - i_ratio)

        let V_cell = max(0.0, E - eta_act_perCell - eta_ohm_perCell - eta_conc_perCell)
        return Double(numberOfCells) * V_cell
    }

    private func currentDensity(I: Double) -> Double {
        // For a series-connected stack, current is same through each cell; area is per cell area
        return I / activeArea_cm2
    }

    // Safe log helpers
    private func log10Safe(_ x: Double) -> Double {
        if x <= 1e-12 { return log(1e-12)/log(10.0) }
        return log(x)/log(10.0)
    }
    private func logSafe(_ x: Double) -> Double {
        if x <= 1e-12 { return log(1e-12) }
        return log(x)
    }
}
