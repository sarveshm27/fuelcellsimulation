import SwiftUI
import Charts

enum ChartValueType {
    case current, voltage, power
}

struct ChartView: View {
    let title: String
    let data: [(flow: Double, current: Double, voltage: Double, power: Double)]
    let valueType: ChartValueType
    
    // Computed properties for mathematical analysis
    private var yValues: [Double] {
        switch valueType {
        case .current: return data.map { $0.current }
        case .voltage: return data.map { $0.voltage }
        case .power: return data.map { $0.power }
        }
    }
    
    private var xValues: [Double] {
        data.map { $0.flow }
    }
    
    private var minY: Double { yValues.min() ?? 0 }
    private var maxY: Double { yValues.max() ?? 0 }
    private var minX: Double { xValues.min() ?? 0 }
    private var maxX: Double { xValues.max() ?? 0 }
    private var avgY: Double { yValues.isEmpty ? 0 : yValues.reduce(0, +) / Double(yValues.count) }
    
    // Calculate slope (derivative) at different points
    private var initialSlope: Double {
        guard data.count >= 2 else { return 0 }
        let dy = yValues[1] - yValues[0]
        let dx = xValues[1] - xValues[0]
        return dx != 0 ? dy / dx : 0
    }
    
    private var finalSlope: Double {
        guard data.count >= 2 else { return 0 }
        let dy = yValues[data.count - 1] - yValues[data.count - 2]
        let dx = xValues[data.count - 1] - xValues[data.count - 2]
        return dx != 0 ? dy / dx : 0
    }
    
    // Standard deviation
    private var standardDeviation: Double {
        guard !yValues.isEmpty else { return 0 }
        let mean = avgY
        let variance = yValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(yValues.count)
        return sqrt(variance)
    }
    
    // Chart color based on type
    private var chartColor: Color {
        switch valueType {
        case .current: return Color(red: 0.2, green: 0.6, blue: 0.9)
        case .voltage: return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .power: return Color(red: 0.9, green: 0.5, blue: 0.2)
        }
    }
    
    private var yAxisLabel: String {
        switch valueType {
        case .current: return "Current (A)"
        case .voltage: return "Voltage (V)"
        case .power: return "Power (W)"
        }
    }
    
    private var unit: String {
        switch valueType {
        case .current: return "A"
        case .voltage: return "V"
        case .power: return "W"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Title
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(alignment: .top, spacing: 20) {
                // Chart Section
                VStack(alignment: .leading, spacing: 10) {
                    Chart(data, id: \.flow) { point in
                        // Line with gradient
                        LineMark(
                            x: .value("H₂ Flow (L/min)", point.flow),
                            y: .value(yAxisLabel, getValue(point))
                        )
                        .foregroundStyle(chartColor)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        
                        // Area under curve
                        AreaMark(
                            x: .value("H₂ Flow (L/min)", point.flow),
                            y: .value(yAxisLabel, getValue(point))
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [chartColor.opacity(0.3), chartColor.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Data points
                        PointMark(
                            x: .value("H₂ Flow (L/min)", point.flow),
                            y: .value(yAxisLabel, getValue(point))
                        )
                        .foregroundStyle(chartColor)
                        .symbolSize(50)
                    }
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .foregroundStyle(Color.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.gray)
                            AxisValueLabel {
                                if let flow = value.as(Double.self) {
                                    Text(String(format: "%.1f", flow))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .foregroundStyle(Color.gray.opacity(0.3))
                            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color.gray)
                            AxisValueLabel {
                                if let yVal = value.as(Double.self) {
                                    Text(String(format: "%.2f", yVal))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 350)
                    
                    // Axis Labels
                    HStack {
                        Spacer()
                        Text("H₂ Flow Rate (L/min)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Mathematical Analysis Panel
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mathematical Analysis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 5)
                    
                    Divider()
                    
                    // Statistical Properties
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistical Properties")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(chartColor)
                        
                        StatRow(label: "Maximum", value: maxY, unit: unit, formula: "max(y)")
                        StatRow(label: "Minimum", value: minY, unit: unit, formula: "min(y)")
                        StatRow(label: "Mean (μ)", value: avgY, unit: unit, formula: "Σy/n")
                        StatRow(label: "Std Dev (σ)", value: standardDeviation, unit: unit, formula: "√(Σ(y-μ)²/n)")
                        StatRow(label: "Range (Δy)", value: maxY - minY, unit: unit, formula: "max-min")
                    }
                    
                    Divider()
                    
                    // Calculus Properties
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calculus Properties")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(chartColor)
                        
                        StatRow(label: "Initial Slope", value: initialSlope, unit: "\(unit)/(L/min)", formula: "dy/dx|₀")
                        StatRow(label: "Final Slope", value: finalSlope, unit: "\(unit)/(L/min)", formula: "dy/dx|ₙ")
                        
                        let slopeChange = finalSlope - initialSlope
                        HStack(alignment: .top, spacing: 4) {
                            Text("Trend:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(slopeChange > 0 ? "Accelerating ↗" : slopeChange < 0 ? "Decelerating ↘" : "Linear →")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(slopeChange > 0 ? .green : slopeChange < 0 ? .orange : .blue)
                        }
                    }
                    
                    Divider()
                    
                    // Domain & Range
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Domain & Range")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(chartColor)
                        
                        HStack(alignment: .top, spacing: 4) {
                            Text("Domain:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("x ∈ [\(String(format: "%.2f", minX)), \(String(format: "%.2f", maxX))]")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 4) {
                            Text("Range:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("y ∈ [\(String(format: "%.2f", minY)), \(String(format: "%.2f", maxY))]")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Divider()
                    
                    // Data Points
                    HStack(alignment: .top, spacing: 4) {
                        Text("Data Points:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("\(data.count) samples")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(15)
                .frame(width: 280)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(chartColor.opacity(0.3), lineWidth: 2)
                )
            }
        }
    }
    
    private func getValue(_ point: (flow: Double, current: Double, voltage: Double, power: Double)) -> Double {
        switch valueType {
        case .current: return point.current
        case .voltage: return point.voltage
        case .power: return point.power
        }
    }
}

// Statistical Row Component
struct StatRow: View {
    let label: String
    let value: Double
    let unit: String
    let formula: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label + ":")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.3f", value))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Text(formula)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.gray)
                .italic()
        }
    }
}
