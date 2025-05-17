import SwiftUI

struct CategoriesView: View {
    @State private var categories: [Category] = Category.defaultCategories()
    @State private var selectedCategory: Category?
    @State private var addAmount: String = ""
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryBalance = ""
    
    // Persistence keys
    let categoriesKey = "categoriesKey"
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            NavigationView {
                List {
                    ForEach(categories) { category in
                        CategoryRowView(
                            category: category,
                            isSelected: selectedCategory?.id == category.id,
                            addAmount: $addAmount,
                            onAddMoney: { cat, amount in
                                addMoney(to: cat, amount: amount)
                            },
                            onSelect: {
                                if selectedCategory?.id == category.id {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }
                        )
                    }
                    .onDelete(perform: deleteCategory)
                }
                .navigationTitle("Categories")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showAddCategory = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showAddCategory) {
                    VStack(spacing: 20) {
                        Text("Add Category").font(.headline)
                        TextField("Category Name", text: $newCategoryName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        TextField("Starting Balance (optional)", text: $newCategoryBalance)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        HStack {
                            Button("Cancel") {
                                showAddCategory = false
                                newCategoryName = ""
                                newCategoryBalance = ""
                            }
                            Spacer()
                            Button("Add") {
                                addCategory()
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
                .onAppear(perform: loadCategories)
                .onChange(of: categories) { _ in
                    saveCategories()
                }
            }
            TopFade()
        }
    }
    
    func addMoney(to category: Category, amount: Double) {
        if let idx = categories.firstIndex(where: { $0.id == category.id }) {
            categories[idx].balance += amount
        }
    }
    
    func addCategory() {
        let name = newCategoryName.trimmingCharacters(in: .whitespaces)
        let balance = Double(newCategoryBalance) ?? 0.0
        let newCat = Category(name: name, balance: balance)
        categories.append(newCat)
        showAddCategory = false
        newCategoryName = ""
        newCategoryBalance = ""
    }
    
    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
    
    // Persistence
    func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: categoriesKey)
        }
    }
    
    func loadCategories() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let saved = try? JSONDecoder().decode([Category].self, from: data) {
            categories = saved
        }
    }
} 