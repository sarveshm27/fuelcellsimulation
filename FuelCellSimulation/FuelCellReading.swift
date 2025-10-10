import Foundation

/// Data structure for storing fuel cell readings
/// Matches lab manual table format for Experiment No. 2
struct FuelCellReading: Identifiable, Codable {
    let id: UUID
    let serialNumber: Int
    let flowRate: Double        // L/min
    let voltage: Double         // V
    let current: Double         // A
    let power: Double           // W
    let efficiency: Double      // %
    let temperature: Double     // °C
    
    init(id: UUID = UUID(), serialNumber: Int, flowRate: Double, voltage: Double, current: Double, power: Double, efficiency: Double, temperature: Double) {
        self.id = id
        self.serialNumber = serialNumber
        self.flowRate = flowRate
        self.voltage = voltage
        self.current = current
        self.power = power
        self.efficiency = efficiency
        self.temperature = temperature
    }
    
    /// Create CSV row for this reading
    func toCSVRow() -> String {
        return "\(serialNumber),\(String(format: "%.1f", flowRate)),\(String(format: "%.2f", current)),\(String(format: "%.2f", voltage)),\(String(format: "%.2f", power)),\(String(format: "%.2f", efficiency)),\(String(format: "%.1f", temperature))"
    }
    
    /// CSV header matching lab manual format
    static var csvHeader: String {
        return "S.No.,Hydrogen Flow Rate (L/min),Current (A),Voltage (V),Power (W),Efficiency (%),Temperature (°C)"
    }
}
