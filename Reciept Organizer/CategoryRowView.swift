import SwiftUI

struct CategoryRowView: View {
    var category: Category
    var isSelected: Bool
    @Binding var addAmount: String
    var onAddMoney: (Category, Double) -> Void
    var onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(category.name)
                    .font(.headline)
                Spacer()
                Text(String(format: "$%.2f", category.balance))
                    .font(.subheadline)
            }
            if isSelected {
                HStack {
                    TextField("Add money", text: $addAmount)
                        .keyboardType(.decimalPad)
                        .frame(width: 100)
                    Button("Add") {
                        if let amount = Double(addAmount) {
                            onAddMoney(category, amount)
                            addAmount = ""
                        }
                    }
                }
            }
            if !category.transactions.isEmpty {
                Text("Transactions:")
                    .font(.caption)
                    .foregroundColor(.gray)
                ForEach(category.transactions) { tx in
                    HStack {
                        Text(tx.store)
                        Spacer()
                        Text(String(format: "-$%.2f", tx.amount))
                            .foregroundColor(.red)
                        Text(tx.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
} 