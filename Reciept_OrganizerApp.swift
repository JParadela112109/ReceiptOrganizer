import SwiftUI

@main
struct Reciept_OrganizerApp: App {
    init() {
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.unselectedItemTintColor = UIColor.black
        tabBarAppearance.tintColor = UIColor.black
        tabBarAppearance.backgroundColor = UIColor.clear
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .clear
            appearance.stackedLayoutAppearance.selected.iconColor = .black
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
            appearance.stackedLayoutAppearance.normal.iconColor = .black
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black]
            tabBarAppearance.standardAppearance = appearance
            tabBarAppearance.scrollEdgeAppearance = appearance
        }
    }
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                // Place the rounded rectangle behind the tab bar
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemGray5).opacity(0.95))
                    .frame(height: 70)
                    .padding(.horizontal, 8)
                    .shadow(radius: 8)
                    .ignoresSafeArea(edges: .bottom)
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
            }
        }
    }
} 