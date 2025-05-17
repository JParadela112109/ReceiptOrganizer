import SwiftUI

struct SettingsView: View {
    @AppStorage("accountBalance") private var accountBalance: Double = 0.0
    @State private var inputBalance: String = ""
    @State private var showSaved = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            NavigationView {
                Form {
                    Section(header: Text("Total Account Balance")) {
                        TextField("Enter your total account balance", text: $inputBalance)
                            .keyboardType(.decimalPad)
                        Button("Save") {
                            if let value = Double(inputBalance) {
                                accountBalance = value
                                showSaved = true
                            }
                        }
                    }
                    if showSaved {
                        Text("Saved!")
                            .foregroundColor(.green)
                    }
                    Section {
                        Text("Current Balance: $\(String(format: "%.2f", accountBalance))")
                            .font(.headline)
                    }
                }
                .navigationTitle("Settings")
                .onAppear {
                    inputBalance = String(format: "%.2f", accountBalance)
                }
            }
            TopFade()
        }
    }
} 