import SwiftUI

struct DataEntryView: View {
    @Binding var load1: LoadData
    @Binding var load2: LoadData
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Input Data")
                .font(.title2)
                .bold()
            
            Group {
                Text("Load 1")
                dataFields(for: $load1)
                Divider()
                Text("Load 2")
                dataFields(for: $load2)
            }
            Spacer()
        }
        .padding()
    }
    
    func dataFields(for load: Binding<LoadData>) -> some View {
        HStack {
            VStack {
                Text("Hydrogen Flow")
                TextField("Comma separated", text: Binding(
                    get: { load.wrappedValue.hydrogenFlow.map { String($0) }.joined(separator: ", ") },
                    set: { load.wrappedValue.hydrogenFlow = $0.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) } }
                ))
            }
            VStack {
                Text("Current (A)")
                TextField("Comma separated", text: Binding(
                    get: { load.wrappedValue.current.map { String($0) }.joined(separator: ", ") },
                    set: { load.wrappedValue.current = $0.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) } }
                ))
            }
            VStack {
                Text("Voltage (V)")
                TextField("Comma separated", text: Binding(
                    get: { load.wrappedValue.voltage.map { String($0) }.joined(separator: ", ") },
                    set: { load.wrappedValue.voltage = $0.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) } }
                ))
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .frame(width: 550)
    }
}

