import SwiftUI
import Charts

struct EcosenseFuelCellView: View {
    // MARK: - State Variables
    @State private var flowRate: Double = 8.5
    @State private var temperature: Double = 303.0  // 30°C in Kelvin
    @State private var recordedData: [FuelCellReading] = []
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private let model = EcosenseFuelCellModel()
    private let maxReadings = 7
    
    // MARK: - Computed Properties
    private var currentReading: (voltage: Double, current: Double, power: Double, efficiency: Double) {
        model.calculate(flowRate: flowRate, temperature: temperature)
    }
    
    private var temperatureCelsius: Double {
        temperature - 273.15
    }
    
    private var hasData: Bool {
        !recordedData.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Header Section
                    headerSection
                    
                    // MARK: - Control Panel
                    controlPanel
                    
                    // MARK: - Live Metric Cards
                    metricCards
                    
                    // MARK: - Action Buttons
                    actionButtons
                    
                    // MARK: - Data Table
                    if hasData {
                        dataTable
                    }
                    
                    // MARK: - Performance Charts
                    if hasData {
                        performanceCharts
                    }
                    
                    // MARK: - Specifications Section
                    specificationsSection
                    
                    // MARK: - Footer
                    footer
                }
                .padding()
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.97))
            .navigationTitle("PEM Fuel Cell Simulator")
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PEM Fuel Cell Training System")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Ecosense | 48-Cell Stack | 1000W Rated")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // MARK: - Control Panel
    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Control Panel")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Hydrogen Flow Rate Slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Hydrogen Flow Rate: \(String(format: "%.1f", flowRate)) L/min")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Max: 13 L/min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress track
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: max(0, geometry.size.width * CGFloat((flowRate - 0.5) / 14.5)), height: 8)
                    }
                }
                .frame(height: 8)
                
                Slider(value: $flowRate, in: 0.5...15.0, step: 0.1)
                    .accentColor(.blue)
                    .tint(.blue)
                
                Text("Flow rate at max output: 13 L/min (Lab Manual)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
            
            // Stack Temperature Slider
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Stack Temperature: \(Int(temperatureCelsius))°C")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Range: 5-65°C")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress track
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(width: max(0, geometry.size.width * CGFloat((temperature - 278) / 60)), height: 8)
                    }
                }
                .frame(height: 8)
                
                Slider(value: $temperature, in: 278.0...338.0, step: 1.0)
                    .accentColor(.orange)
                    .tint(.orange)
                
                Text("External temp: 5-30°C | Max stack temp: 65°C (Lab Manual)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Metric Cards
    private var metricCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            EcosenseMetricCard(
                title: "Voltage",
                value: currentReading.voltage,
                unit: "V",
                gradient: [Color.blue, Color.blue.opacity(0.7)]
            )
            
            EcosenseMetricCard(
                title: "Current",
                value: currentReading.current,
                unit: "A",
                gradient: [Color.green, Color.green.opacity(0.7)]
            )
            
            EcosenseMetricCard(
                title: "Power",
                value: currentReading.power,
                unit: "W",
                gradient: [Color.orange, Color.orange.opacity(0.7)]
            )
            
            EcosenseMetricCard(
                title: "Efficiency",
                value: currentReading.efficiency,
                unit: "%",
                gradient: [Color.purple, Color.purple.opacity(0.7)]
            )
            
            EcosenseMetricCard(
                title: "Temperature",
                value: temperatureCelsius,
                unit: "°C",
                gradient: [Color.red, Color.red.opacity(0.7)]
            )
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: recordReading) {
                Label("Record (\(recordedData.count)/\(maxReadings))", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
            if hasData {
                Button(action: exportToCSV) {
                    Label("Export", systemImage: "square.and.arrow.down.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: clearAllData) {
                    Label("Clear", systemImage: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Data Table
    private var dataTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recorded Observations (Experiment No. 2)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Output power variation of fuel cell with change in Hydrogen supply")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        TableHeaderCell(text: "S.No.", width: 80)
                        TableHeaderCell(text: "Current (A)", width: 120)
                        TableHeaderCell(text: "Voltage (V)", width: 120)
                        TableHeaderCell(text: "Power (W)", width: 120)
                        TableHeaderCell(text: "H₂ Flow Rate\n(L/min)", width: 140)
                        TableHeaderCell(text: "Efficiency (%)", width: 140)
                        TableHeaderCell(text: "Action", width: 100)
                    }
                    
                    // Table Rows
                    ForEach(Array(recordedData.enumerated()), id: \.element.id) { index, reading in
                        HStack(spacing: 0) {
                            TableCell(text: "\(reading.serialNumber)", width: 80)
                            TableCell(text: String(format: "%.2f", reading.current), width: 120)
                            TableCell(text: String(format: "%.2f", reading.voltage), width: 120)
                            TableCell(text: String(format: "%.2f", reading.power), width: 120)
                            TableCell(text: String(format: "%.1f", reading.flowRate), width: 140)
                            TableCell(text: String(format: "%.2f", reading.efficiency), width: 140)
                            
                            Button(action: { deleteReading(at: index) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .frame(width: 100)
                        }
                        .background(index % 2 == 0 ? Color.white : Color.gray.opacity(0.1))
                    }
                }
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Performance Charts
    private var performanceCharts: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Results: Current, Voltage and Power vs Hydrogen Flow Rate")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            // Chart 1: Current vs Flow Rate
            VStack(alignment: .leading, spacing: 8) {
                Text("Current vs. Hydrogen Flow Rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Chart(recordedData) { reading in
                    LineMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Current (A)", reading.current)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Current (A)", reading.current)
                    )
                    .foregroundStyle(Color.green)
                    .symbolSize(80)
                }
                .frame(height: 250)
                .chartXAxisLabel("Hydrogen Flow Rate (L/min)")
                .chartYAxisLabel("Current (A)")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            // Chart 2: Voltage vs Flow Rate
            VStack(alignment: .leading, spacing: 8) {
                Text("Voltage vs. Hydrogen Flow Rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Chart(recordedData) { reading in
                    LineMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Voltage (V)", reading.voltage)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Voltage (V)", reading.voltage)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(80)
                }
                .frame(height: 250)
                .chartXAxisLabel("Hydrogen Flow Rate (L/min)")
                .chartYAxisLabel("Voltage (V)")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            // Chart 3: Power vs Flow Rate
            VStack(alignment: .leading, spacing: 8) {
                Text("Power vs. Hydrogen Flow Rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Chart(recordedData) { reading in
                    LineMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Power (W)", reading.power)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Hydrogen Flow Rate (L/min)", reading.flowRate),
                        y: .value("Power (W)", reading.power)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(80)
                }
                .frame(height: 250)
                .chartXAxisLabel("Hydrogen Flow Rate (L/min)")
                .chartYAxisLabel("Power (W)")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Specifications Section
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Specifications (Lab Manual)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                SpecCard(title: "Cells", value: "48")
                SpecCard(title: "Rated Power", value: "1000 W")
                SpecCard(title: "Performance", value: "28.8V @ 35A")
                SpecCard(title: "H₂ Pressure", value: "0.45-0.55 bar")
                SpecCard(title: "Stack Efficiency", value: "40%")
                SpecCard(title: "Low V Shutdown", value: "24 V")
                SpecCard(title: "Over Current", value: "42 A")
                SpecCard(title: "Over Temp", value: "65°C")
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    // MARK: - Footer
    private var footer: some View {
        Text("Ecosense Sustainable Solutions Pvt. Ltd.")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }
    
    // MARK: - Actions
    private func recordReading() {
        // Check if maximum readings reached
        if recordedData.count >= maxReadings {
            showAlertMessage(title: "Maximum Readings Reached", message: "You can only record up to \(maxReadings) readings. Please delete some readings to add new ones.")
            return
        }
        
        // Check for duplicate flow rate
        if recordedData.contains(where: { abs($0.flowRate - flowRate) < 0.1 }) {
            showAlertMessage(title: "Duplicate Flow Rate", message: "A reading with this flow rate (±0.1 L/min) already exists. Please use a different flow rate.")
            return
        }
        
        // Create new reading
        let reading = FuelCellReading(
            serialNumber: recordedData.count + 1,
            flowRate: flowRate,
            voltage: currentReading.voltage,
            current: currentReading.current,
            power: currentReading.power,
            efficiency: currentReading.efficiency,
            temperature: temperatureCelsius
        )
        
        recordedData.append(reading)
        
        // Sort by flow rate
        recordedData.sort { $0.flowRate < $1.flowRate }
        
        // Reassign serial numbers
        reassignSerialNumbers()
    }
    
    private func deleteReading(at index: Int) {
        recordedData.remove(at: index)
        reassignSerialNumbers()
    }
    
    private func clearAllData() {
        recordedData.removeAll()
    }
    
    private func reassignSerialNumbers() {
        for (index, _) in recordedData.enumerated() {
            recordedData[index] = FuelCellReading(
                id: recordedData[index].id,
                serialNumber: index + 1,
                flowRate: recordedData[index].flowRate,
                voltage: recordedData[index].voltage,
                current: recordedData[index].current,
                power: recordedData[index].power,
                efficiency: recordedData[index].efficiency,
                temperature: recordedData[index].temperature
            )
        }
    }
    
    private func exportToCSV() {
        let csvContent = FuelCellReading.csvHeader + "\n" + recordedData.map { $0.toCSVRow() }.joined(separator: "\n")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("fuel_cell_experiment_data.csv")
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            showAlertMessage(title: "Export Successful", message: "Data exported successfully to:\n\(fileURL.path)")
        } catch {
            showAlertMessage(title: "Export Failed", message: "Failed to export data: \(error.localizedDescription)")
        }
    }
    
    private func showAlertMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Supporting Views

struct EcosenseMetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Text(String(format: "%.2f", value))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct TableHeaderCell: View {
    let text: String
    let width: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: width, height: 50)
            .multilineTextAlignment(.center)
            .background(Color.blue)
    }
}

struct TableCell: View {
    let text: String
    let width: CGFloat
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.black)
            .frame(width: width, height: 40)
            .multilineTextAlignment(.center)
    }
}

struct SpecCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    EcosenseFuelCellView()
}
