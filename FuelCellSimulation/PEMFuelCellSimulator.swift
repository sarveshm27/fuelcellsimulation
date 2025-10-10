import SwiftUI
import Charts

struct FuelCellData: Identifiable {
    let id = UUID()
    let flowRate: Double
    let voltage: Double
    let current: Double
    let power: Double
    let efficiency: Double
    let temperature: Double
}

struct PEMFuelCellSimulator: View {
    @State private var flowRate: Double = 8.5
    @State private var temperature: Double = 338
    @State private var recordedData: [FuelCellData] = []

    var currentPoint: FuelCellData {
        calculateFuelCellParameters(H2_flow: flowRate, Ts: temperature)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    VStack(alignment: .leading) {
                        Text("PEM Fuel Cell Performance Analyzer")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("H-500XP Model | 30-Cell Stack | 500W Rated Power")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
                
                // Controls
                VStack(alignment: .leading, spacing: 25) {
                    Text("Control Panel")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Hydrogen Flow
                    VStack(alignment: .leading) {
                        Text("Hydrogen Flow Rate: \(String(format: "%.1f", flowRate)) L/min")
                            .font(.headline)
                        Slider(value: $flowRate, in: 0.5...15, step: 0.1)
                            .tint(.blue)
                    }

                    // Temperature
                    VStack(alignment: .leading) {
                        Text("Stack Temperature: \(Int(temperature - 273.15)) °C")
                            .font(.headline)
                        Slider(value: $temperature, in: 296...338, step: 1)
                            .tint(.orange)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))

                // Live Readings
                HStack(spacing: 12) {
                    MetricCard(title: "Voltage", value: currentPoint.voltage, unit: "V", color: .blue)
                    MetricCard(title: "Current", value: currentPoint.current, unit: "A", color: .green)
                    MetricCard(title: "Power", value: currentPoint.power, unit: "W", color: .orange)
                    MetricCard(title: "Efficiency", value: currentPoint.efficiency, unit: "%", color: .purple)
                    MetricCard(title: "Temp", value: temperature - 273.15, unit: "°C", color: .red)
                }

                // Buttons
                HStack {
                    Button(action: addReading) {
                        Label("Record Reading (\(recordedData.count)/7)", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    if !recordedData.isEmpty {
                        Button(action: exportData) {
                            Label("Export CSV", systemImage: "square.and.arrow.down.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button(role: .destructive, action: clearAll) {
                            Label("Clear", systemImage: "trash.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Data Table
                if !recordedData.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Recorded Observations")
                            .font(.title2)
                            .fontWeight(.bold)
                        TableView(records: recordedData, deleteAction: deleteReading)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white).shadow(radius: 5))
                }

                // Charts
                if !recordedData.isEmpty {
                    ChartSection(records: recordedData)
                }
            }
            .padding()
        }
        .background(LinearGradient(colors: [.blue.opacity(0.1), .indigo.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    // MARK: - Core Logic
    func calculateFuelCellParameters(H2_flow: Double, Ts: Double) -> FuelCellData {
        let n_cell = 30.0
        let A = 76.0
        let tau_m = 25e-4
        let lambda_m = 7.0
        let I_loss = 0.3
        let E0 = 1.229
        let R = 8.314
        let F = 96485.0
        let deltaS = 163.3
        let p_H2 = 1.5
        let p_O2 = 0.21
        let p_H2O = 1.0

        let I_ext = (H2_flow / 13.0) * 33.5
        let I = I_ext + I_loss
        let E_TP = (E0 + (R * Ts / (2 * F)) * log((p_H2 * pow(p_O2, 0.5)) / p_H2O)
                    - (deltaS / (2 * F)) * (Ts - 298.15))

        let xi1 = -1.00, xi2 = -0.0034, xi3 = -0.000078, xi4 = 0.000185
        let C_O2 = p_O2 / (5.08e6 * exp(-498 / Ts))
        let deltaV_act = I > 0 ? xi1 + xi2 * Ts + xi3 * Ts * log(C_O2) + xi4 * Ts * log(I) : 0

        let term1 = 181.6 * (1 + 0.03 * (I / A) + 0.062 * pow(Ts / 303, 2) * pow(I / A, 2.5))
        let term2 = (lambda_m - 0.634 - 3 * (I / A)) * exp(4.18 * (Ts - 303) / 303)
        let R_ion = (tau_m / A) * (term1 / term2)
        let deltaV_ohm = R_ion * I
        let I_L = 47.0, alpha = 0.5, n = 4.0
        let deltaV_con = I > 25 ? ((1 + 1/alpha) * R * Ts / (n * F)) * log(I_L / (I_L - I)) : 0

        let V_cell = max(E_TP - abs(deltaV_act) - deltaV_ohm - deltaV_con, 0.5)
        let V_stk = V_cell * n_cell
        let finalVoltage = max(V_stk, 15)
        let power = finalVoltage * I_ext
        let Q_LHV_H2 = 120000.0, rho_H2 = 0.0899
        let P_H2 = (H2_flow / 60000) * rho_H2 * Q_LHV_H2
        let P_aux = 36.5 + (52 - 36.5) * ((Ts - 296) / (338 - 296))
        let efficiency = P_H2 > 0 ? ((power - P_aux) / (P_H2 * 1000)) * 100 : 0

        return FuelCellData(
            flowRate: round(H2_flow * 100) / 100,
            voltage: round(finalVoltage * 100) / 100,
            current: round(I_ext * 100) / 100,
            power: round(power * 100) / 100,
            efficiency: max(0, min(efficiency, 50)),
            temperature: Ts
        )
    }

    // MARK: - Actions
    func addReading() {
        if recordedData.contains(where: { abs($0.flowRate - currentPoint.flowRate) < 0.1 }) {
            return
        }
        if recordedData.count >= 7 { return }
        recordedData.append(currentPoint)
        recordedData.sort { $0.flowRate < $1.flowRate }
    }

    func deleteReading(at index: Int) {
        recordedData.remove(at: index)
    }

    func clearAll() {
        recordedData.removeAll()
    }

    func exportData() {
        let header = "Flow Rate (L/min),Voltage (V),Current (A),Power (W),Efficiency (%)\n"
        let rows = recordedData.map {
            "\($0.flowRate),\($0.voltage),\($0.current),\($0.power),\($0.efficiency)"
        }.joined(separator: "\n")
        let csv = header + rows
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fuel_cell_data.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        print("CSV exported at: \(url)")
    }
}

// MARK: - Subviews
struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundColor(.white.opacity(0.9))
            Text(String(format: "%.2f", value))
                .font(.title2)
                .bold()
            Text(unit).font(.caption2).opacity(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct TableView: View {
    let records: [FuelCellData]
    let deleteAction: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(records.enumerated()), id: \.element.id) { index, data in
                HStack {
                    Text("\(index + 1). \(String(format: "%.1f", data.flowRate)) L/min")
                    Spacer()
                    Text("V: \(data.voltage) | A: \(data.current) | P: \(data.power) | Eff: \(data.efficiency)%")
                    Spacer()
                    Button(role: .destructive) {
                        deleteAction(index)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }
}

struct ChartSection: View {
    let records: [FuelCellData]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance Characteristics")
                .font(.title2)
                .fontWeight(.bold)

            Chart(records) {
                LineMark(x: .value("Flow Rate", $0.flowRate),
                         y: .value("Current (A)", $0.current))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
            .frame(height: 200)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))

            Chart(records) {
                LineMark(x: .value("Flow Rate", $0.flowRate),
                         y: .value("Voltage (V)", $0.voltage))
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
            .frame(height: 200)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))

            Chart(records) {
                LineMark(x: .value("Flow Rate", $0.flowRate),
                         y: .value("Power (W)", $0.power))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
            .frame(height: 200)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
        }
        .padding()
    }
}

#Preview {
    PEMFuelCellSimulator()
}
