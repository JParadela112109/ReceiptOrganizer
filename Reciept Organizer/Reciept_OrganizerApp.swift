//
//  Reciept_OrganizerApp.swift
//  Reciept Organizer
//
//  Created by Jonathan Paradela on 5/16/25.
//

import SwiftUI

@main
struct Reciept_OrganizerApp: App {
    init() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.unselectedItemTintColor = UIColor.darkGray
        tabBarAppearance.tintColor = UIColor.darkGray
        tabBarAppearance.backgroundColor = UIColor.clear // We'll use our overlay
    }
    var body: some Scene {
        WindowGroup {
            ZStack {
                TabView {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "gauge")
                            Text("Dashboard")
                        }
                    TransactionsView()
                        .tabItem {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Transactions")
                        }
                    ReceiptScannerView()
                        .tabItem {
                            Image(systemName: "camera.viewfinder")
                            Text("Scan")
                        }
                    CategoriesView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Categories")
                        }
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gear")
                            Text("Settings")
                        }
                }
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(.systemGray5).opacity(0.95))
                                .frame(height: 70)
                                .padding(.horizontal, 8)
                                .shadow(radius: 8)
                                .overlay(
                                    Color.clear
                                )
                            Spacer()
                        }
                        .allowsHitTesting(false)
                        .padding(.bottom, 0)
                    }, alignment: .bottom
                )
            }
        }
    }
}
