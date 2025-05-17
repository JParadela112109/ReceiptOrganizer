import SwiftUI
import Charts

// MARK: - Pie Chart Wrapper
struct PieChartSwiftUIView: UIViewRepresentable {
    var entries: [PieChartDataEntry]
    func makeUIView(context: Context) -> PieChartView {
        let chart = PieChartView()
        chart.legend.enabled = true
        chart.holeRadiusPercent = 0.4
        chart.transparentCircleColor = .clear
        return chart
    }
    func updateUIView(_ uiView: PieChartView, context: Context) {
        let dataSet = PieChartDataSet(entries: entries, label: "Spending by Category")
        dataSet.colors = ChartColorTemplates.material()
        dataSet.valueTextColor = .black
        let data = PieChartData(dataSet: dataSet)
        uiView.data = data
        uiView.notifyDataSetChanged()
    }
}

// MARK: - Bar Chart Wrapper
struct BarChartSwiftUIView: UIViewRepresentable {
    var entries: [BarChartDataEntry]
    var labels: [String]
    func makeUIView(context: Context) -> BarChartView {
        let chart = BarChartView()
        chart.legend.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.rightAxis.enabled = false
        chart.leftAxis.axisMinimum = 0
        return chart
    }
    func updateUIView(_ uiView: BarChartView, context: Context) {
        let dataSet = BarChartDataSet(entries: entries, label: "Spending by Month")
        dataSet.colors = [NSUIColor.systemBlue]
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(.black)
        uiView.data = data
        uiView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        uiView.xAxis.granularity = 1
        uiView.notifyDataSetChanged()
    }
}

// MARK: - Store Spending Bar Chart Wrapper
struct StoreBarChartSwiftUIView: UIViewRepresentable {
    var entries: [BarChartDataEntry]
    var labels: [String]
    func makeUIView(context: Context) -> BarChartView {
        let chart = BarChartView()
        chart.legend.enabled = false
        chart.xAxis.labelPosition = .bottom
        chart.rightAxis.enabled = false
        chart.leftAxis.axisMinimum = 0
        return chart
    }
    func updateUIView(_ uiView: BarChartView, context: Context) {
        let dataSet = BarChartDataSet(entries: entries, label: "Spending by Store")
        dataSet.colors = [NSUIColor.systemGreen]
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(.black)
        uiView.data = data
        uiView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        uiView.xAxis.granularity = 1
        uiView.notifyDataSetChanged()
    }
}

struct DashboardView: View {
    @State private var categories: [Category] = Category.defaultCategories()
    let categoriesKey = "categoriesKey"
    @AppStorage("accountBalance") private var accountBalance: Double = 0.0
    
    var totalBalance: Double {
        categories.reduce(0) { $0 + $1.balance }
    }
    var totalSpent: Double {
        categories.flatMap { $0.transactions }.reduce(0) { $0 + $1.amount }
    }
    var recentTransactions: [Transaction] {
        categories.flatMap { $0.transactions }
            .sorted { $0.date > $1.date }
            .prefix(5).map { $0 }
    }
    // Pie chart data: spending by category
    var spendingByCategory: [(String, Double)] {
        categories.map { cat in
            (cat.name, cat.transactions.reduce(0) { $0 + $1.amount })
        }.filter { $0.1 > 0 }
    }
    var pieChartEntries: [PieChartDataEntry] {
        spendingByCategory.map { PieChartDataEntry(value: $0.1, label: $0.0) }
    }
    // Bar chart data: spending per month
    var spendingByMonth: [(String, Double)] {
        let txs = categories.flatMap { $0.transactions }
        let grouped = Dictionary(grouping: txs) { tx in
            let comps = Calendar.current.dateComponents([.year, .month], from: tx.date)
            return String(format: "%04d-%02d", comps.year ?? 0, comps.month ?? 0)
        }
        return grouped.map { (month, txs) in
            (month, txs.reduce(0) { $0 + $1.amount })
        }.sorted { $0.0 < $1.0 }
    }
    var barChartEntries: [BarChartDataEntry] {
        spendingByMonth.enumerated().map { BarChartDataEntry(x: Double($0.offset), y: $0.element.1) }
    }
    var barChartLabels: [String] {
        spendingByMonth.map { $0.0 }
    }
    // Store spending data
    var spendingByStore: [(String, Double)] {
        let txs = categories.flatMap { $0.transactions }
        let grouped = Dictionary(grouping: txs) { $0.store }
        return grouped.map { (store, txs) in
            (store, txs.reduce(0) { $0 + $1.amount })
        }.sorted { $0.1 > $1.1 }
    }
    var storeBarChartEntries: [BarChartDataEntry] {
        spendingByStore.enumerated().map { BarChartDataEntry(x: Double($0.offset), y: $0.element.1) }
    }
    var storeBarChartLabels: [String] {
        spendingByStore.map { $0.0 }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 10)
                    Text("Account Balance: $\(String(format: "%.2f", accountBalance))")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Balance")
                                .font(.headline)
                            Text(String(format: "$%.2f", totalBalance))
                                .font(.title)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("Total Spent")
                                .font(.headline)
                            Text(String(format: "$%.2f", totalSpent))
                                .font(.title)
                        }
                    }
                    Divider()
                    // Pie Chart: Spending by Category
                    if !pieChartEntries.isEmpty {
                        SectionHeader(title: "Spending by Category")
                        BlurredCard {
                            PieChartSwiftUIView(entries: pieChartEntries)
                                .frame(height: 260)
                        }
                    }
                    // Bar Chart: Spending by Month
                    if !barChartEntries.isEmpty {
                        SectionHeader(title: "Spending by Month")
                        BlurredCard {
                            BarChartSwiftUIView(entries: barChartEntries, labels: barChartLabels)
                                .frame(height: 220)
                        }
                    }
                    // Bar Chart: Spending by Store
                    if !storeBarChartEntries.isEmpty {
                        SectionHeader(title: "Spending by Store")
                        BlurredCard {
                            StoreBarChartSwiftUIView(entries: storeBarChartEntries, labels: storeBarChartLabels)
                                .frame(height: 220)
                        }
                    }
                    Divider()
                    Text("Recent Transactions")
                        .font(.headline)
                    if recentTransactions.isEmpty {
                        Text("No transactions yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(recentTransactions, id: \ .id) { tx in
                            HStack {
                                Text(tx.store)
                                Spacer()
                                Text(tx.categoryName)
                                    .foregroundColor(.blue)
                                Text(String(format: "-$%.2f", tx.amount))
                                    .foregroundColor(.red)
                                Text(tx.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding([.horizontal, .bottom])
            }
            TopFade()
        }
        .onAppear(perform: loadCategories)
    }
    
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let saved = try? JSONDecoder().decode([Category].self, from: data) {
            categories = saved
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3.bold())
            .foregroundColor(.primary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }
}

struct BlurredCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(radius: 14)
            .padding(.vertical, 4)
    }
} 
