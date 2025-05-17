import Foundation

struct Transaction: Codable, Identifiable, Equatable {
    let id: UUID
    let amount: Double
    let store: String
    let date: Date
    let categoryName: String
    
    init(amount: Double, store: String, date: Date = Date(), categoryName: String) {
        self.id = UUID()
        self.amount = amount
        self.store = store
        self.date = date
        self.categoryName = categoryName
    }
} 