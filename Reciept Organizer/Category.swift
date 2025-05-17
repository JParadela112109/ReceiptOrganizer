import Foundation

struct Category: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var balance: Double
    var transactions: [Transaction]
    
    init(name: String, balance: Double = 0.0, transactions: [Transaction] = []) {
        self.id = UUID()
        self.name = name
        self.balance = balance
        self.transactions = transactions
    }
    
    static func defaultCategories() -> [Category] {
        return [
            Category(name: "Groceries"),
            Category(name: "Dining"),
            Category(name: "Electronics"),
            Category(name: "Clothing"),
            Category(name: "Other")
        ]
    }
} 