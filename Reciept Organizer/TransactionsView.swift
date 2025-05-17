import SwiftUI

struct TransactionsView: View {
    @State private var categories: [Category] = Category.defaultCategories()
    @State private var selectedCategory: String = "All"
    let categoriesKey = "categoriesKey"
    @AppStorage("accountBalance") private var accountBalance: Double = 0.0
    
    // Add Transaction Sheet State
    @State private var showAddTransaction = false
    @State private var newStore = ""
    @State private var newAmount = ""
    @State private var newDate = Date()
    @State private var newCategory = ""
    @State private var isIncome = false
    
    var allCategoryNames: [String] {
        ["All"] + categories.map { $0.name }
    }
    var filteredTransactions: [Transaction] {
        let allTx = categories.flatMap { $0.transactions }
        let sortedTx = allTx.sorted { $0.date > $1.date }
        if selectedCategory == "All" {
            return sortedTx
        } else {
            return sortedTx.filter { $0.categoryName == selectedCategory }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            NavigationView {
                VStack {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(allCategoryNames, id: \ .self) { name in
                            Text(name)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    if filteredTransactions.isEmpty {
                        Spacer()
                        Text("No transactions found.")
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List(filteredTransactions) { tx in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(tx.store)
                                        .font(.headline)
                                    Spacer()
                                    Text(String(format: "-$%.2f", tx.amount))
                                        .foregroundColor(.red)
                                }
                                HStack {
                                    Text(tx.categoryName)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Text(tx.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("Transactions")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddTransaction = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddTransaction) {
                    NavigationView {
                        Form {
                            Section(header: Text("Type")) {
                                Picker("Type", selection: $isIncome) {
                                    Text("Expense").tag(false)
                                    Text("Income").tag(true)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            Section(header: Text("Store")) {
                                TextField("Store Name", text: $newStore)
                            }
                            Section(header: Text("Amount")) {
                                TextField("Amount", text: $newAmount)
                                    .keyboardType(.decimalPad)
                            }
                            Section(header: Text("Date")) {
                                DatePicker("Date", selection: $newDate, displayedComponents: .date)
                            }
                            if !isIncome {
                                Section(header: Text("Category")) {
                                    Picker("Category", selection: $newCategory) {
                                        ForEach(categories.map { $0.name }, id: \ .self) { name in
                                            Text(name)
                                        }
                                    }
                                }
                            }
                        }
                        .navigationTitle("Add Transaction")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showAddTransaction = false
                                    clearForm()
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    addTransaction()
                                }
                                .disabled(newStore.trimmingCharacters(in: .whitespaces).isEmpty || Double(newAmount) == nil || (!isIncome && newCategory.isEmpty))
                            }
                        }
                    }
                }
                .onAppear(perform: loadCategories)
            }
            TopFade()
        }
    }
    
    func addTransaction() {
        guard let amount = Double(newAmount), amount > 0 else { return }
        if isIncome {
            accountBalance += amount
            // Optionally, you could save income as a special transaction somewhere if you want a record
        } else {
            guard let idx = categories.firstIndex(where: { $0.name == newCategory }) else { return }
            let tx = Transaction(amount: amount, store: newStore, date: newDate, categoryName: newCategory)
            categories[idx].transactions.append(tx)
            categories[idx].balance -= amount
            saveCategories()
        }
        showAddTransaction = false
        clearForm()
    }
    
    func clearForm() {
        newStore = ""
        newAmount = ""
        newDate = Date()
        newCategory = categories.first?.name ?? ""
        isIncome = false
    }
    
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let saved = try? JSONDecoder().decode([Category].self, from: data) {
            categories = saved
        }
        // Set default for newCategory
        if newCategory.isEmpty, let first = categories.first?.name {
            newCategory = first
        }
    }
    
    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: categoriesKey)
        }
    }
} 