//
//  FuelCellSimulationApp.swift
//  FuelCellSimulation
//
//  Created by imac u20 on 09/10/25.
//

import SwiftUI

@main
struct FuelCellSimulationApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            EcosenseFuelCellView()
                .tabItem {
                    Label("Ecosense Training System", systemImage: "bolt.shield.fill")
                }
            
            PEMFuelCellSimulator()
                .tabItem {
                    Label("Performance Analyzer", systemImage: "bolt.fill")
                }
            
            ContentView()
                .tabItem {
                    Label("Basic Simulator", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}
