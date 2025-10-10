//
//  loadData.swift
//  FuelCellSimulation
//
//  Created by imac u20 on 09/10/25.
//

import Foundation

struct LoadData: Identifiable {
    let id = UUID()             // Unique ID (needed for SwiftUI Charts)
    var label: String           // e.g., "Load 1"
    var hydrogenFlow: [Double]
    var current: [Double]
    var voltage: [Double]
    
    // Derived quantity
    var power: [Double] {
        zip(current, voltage).map { $0 * $1 }
    }
    
    // Combines all data points into tuples for plotting
    var dataPoints: [(flow: Double, current: Double, voltage: Double, power: Double)] {
        var points: [(Double, Double, Double, Double)] = []
        for i in 0..<min(hydrogenFlow.count, current.count, voltage.count) {
            points.append((hydrogenFlow[i], current[i], voltage[i], power[i]))
        }
        return points
    }
}
