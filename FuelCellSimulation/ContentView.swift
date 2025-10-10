import SwiftUI
import Charts

struct ContentView: View {
    @State private var flowRateInput: String = ""
    @State private var simulationData: [(flow: Double, current: Double, voltage: Double, power: Double)] = []
    @State private var selectedChartType: ChartValueType = .current
    @State private var model = PEMFuelCellModel()
    @State private var currentResult: Double = 0.0
    @State private var voltageResult: Double = 0.0
    @State private var powerResult: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.88, green: 0.92, blue: 0.98)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 8) {
                    Text("PEM Fuel Cell Simulator")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.4, blue: 0.8), Color(red: 0.1, green: 0.6, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Real-time hydrogen flow analysis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                
                // Input Card
                VStack(spacing: 20) {
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("H₂ Flow Rate")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("Enter value", text: $flowRateInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        .frame(width: 200)
                        
                        Text("L/min")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                        
                        Button(action: runSimulation) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                Text("Simulate")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 20)
                    }
                }
                .padding(25)
                .background(Color.white.opacity(0.8))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 40)
                
                if !simulationData.isEmpty {
                    // Results Cards
                    HStack(spacing: 20) {
                        ResultCard(title: "Current", value: currentResult, unit: "A", color: Color(red: 0.2, green: 0.6, blue: 0.9))
                        ResultCard(title: "Voltage", value: voltageResult, unit: "V", color: Color(red: 0.3, green: 0.7, blue: 0.4))
                        ResultCard(title: "Power", value: powerResult, unit: "W", color: Color(red: 0.9, green: 0.5, blue: 0.2))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 25)
                    
                    // Chart Section
                    VStack(spacing: 15) {
                        ChartView(title: chartTitle, data: simulationData, valueType: selectedChartType)
                            .padding(20)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
                        
                        // Chart Type Selector
                        HStack(spacing: 15) {
                            ChartButton(title: "Current vs Flow", icon: "bolt.fill", isSelected: selectedChartType == .current, color: Color(red: 0.2, green: 0.6, blue: 0.9)) {
                                selectedChartType = .current
                            }
                            
                            ChartButton(title: "Voltage vs Flow", icon: "waveform.path.ecg", isSelected: selectedChartType == .voltage, color: Color(red: 0.3, green: 0.7, blue: 0.4)) {
                                selectedChartType = .voltage
                            }
                            
                            ChartButton(title: "Power vs Flow", icon: "flame.fill", isSelected: selectedChartType == .power, color: Color(red: 0.9, green: 0.5, blue: 0.2)) {
                                selectedChartType = .power
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
        }
    }
    
    private var chartTitle: String {
        switch selectedChartType {
        case .current:
            return "Current vs H₂ Flow Rate"
        case .voltage:
            return "Voltage vs H₂ Flow Rate"
        case .power:
            return "Power vs H₂ Flow Rate"
        }
    }
    
    private func runSimulation() {
        guard let flowRate = Double(flowRateInput), flowRate > 0 else { return }
        
        // Generate data points from 0 to the input flow rate
        let steps = 20
        let flowRates = (0...steps).map { Double($0) * flowRate / Double(steps) }
        simulationData = model.simulate(forFlowRates: flowRates)
        
        // Get the result at the specified flow rate
        if let result = simulationData.last {
            currentResult = result.current
            voltageResult = result.voltage
            powerResult = result.power
        }
    }
}

// Result Card Component
struct ResultCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", value))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// Chart Button Component
struct ChartButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? 
                    AnyView(color) :
                    AnyView(Color.white.opacity(0.8))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isSelected ? 0 : 2)
            )
            .shadow(color: isSelected ? color.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

