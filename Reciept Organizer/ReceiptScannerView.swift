import SwiftUI
import Vision
import UIKit

struct ReceiptScannerView: View {
    @State private var image: UIImage?
    @State private var recognizedText: String = ""
    @State private var extractedAmount: String = ""
    @State private var extractedStore: String = ""
    @State private var selectedCategoryName: String = "Groceries"
    @State private var categories: [Category] = Category.defaultCategories()
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var isIncome = false
    @AppStorage("accountBalance") private var accountBalance: Double = 0.0
    
    let categoriesKey = "categoriesKey"
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack {
                Spacer(minLength: 40)
                VStack(spacing: 20) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(radius: 8)
                    }
                    Button(action: showImagePicker) {
                        Label("Take or Choose Receipt", systemImage: "camera.fill")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    if !recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Extracted Text:")
                                .font(.headline)
                            ScrollView {
                                Text(recognizedText)
                                    .font(.callout)
                                    .padding(8)
                                    .background(Color(.systemGray5).opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .frame(maxHeight: 80)
                            Divider()
                            Picker("Type", selection: $isIncome) {
                                Text("Expense").tag(false)
                                Text("Income").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 4)
                            if isIncome {
                                HStack {
                                    Text("Source:")
                                        .font(.subheadline)
                                    TextField("Source", text: $extractedStore)
                                        .textFieldStyle(.roundedBorder)
                                }
                            } else {
                                HStack {
                                    Text("Store:")
                                        .font(.subheadline)
                                    TextField("Store", text: $extractedStore)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                            HStack {
                                Text("Amount:")
                                    .font(.subheadline)
                                TextField("Amount", text: $extractedAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                            if !isIncome {
                                Picker("Category", selection: $selectedCategoryName) {
                                    ForEach(categories, id: \ .name) { cat in
                                        Text(cat.name)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 4)
                            }
                            Button(action: saveTransaction) {
                                Label("Save Transaction", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor.opacity(0.2))
                                    .foregroundColor(.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(radius: 18)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                Spacer()
            }
            .padding(.top, 10)
            .navigationTitle("Receipt Scanner")
            .alert(isPresented: $showSaveAlert) {
                Alert(title: Text("Saved"), message: Text(saveMessage), dismissButton: .default(Text("OK")))
            }
            TopFade()
        }
        .onAppear(perform: loadCategories)
    }
    
    // MARK: - Image Picker
    func showImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = UIImagePickerCoordinator { uiImage in
            self.image = uiImage
            recognizeText(from: uiImage)
        }
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }
    
    // MARK: - Text Recognition & Parsing
    func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async {
                self.recognizedText = text
                self.parseText(text)
            }
        }
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
    }
    
    // Basic text parsing
    func parseText(_ text: String) {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        // Store extraction: skip lines with numbers, dates, or keywords
        let storeKeywords = ["total", "amount", "change", "cashier", "date", "time", "receipt", "balance", "tax", "item", "qty", "price"]
        let dateRegex = try? NSRegularExpression(pattern: #"\d{1,2}[/-]\d{1,2}[/-]\d{2,4}"#)
        let storeLine = lines.first(where: { line in
            let lower = line.lowercased()
            guard !storeKeywords.contains(where: { lower.contains($0) }) else { return false }
            guard dateRegex?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) == nil else { return false }
            guard line.rangeOfCharacter(from: .decimalDigits) == nil else { return false }
            return true
        })
        extractedStore = storeLine ?? lines.first ?? "Unknown"
        // Amount extraction: prefer lines with 'total' or 'amount due'
        let totalLine = lines.first(where: { $0.lowercased().contains("total") || $0.lowercased().contains("amount due") })
        let amountsFromTotal = totalLine != nil ? matches(for: #"(\d+[.,]?\d{0,2})"#, in: totalLine!) : []
        if let amt = amountsFromTotal.compactMap({ Double($0.replacingOccurrences(of: ",", with: ".")) }).max(), amt > 0 {
            extractedAmount = String(format: "%.2f", amt)
        } else {
            // fallback: largest number in all text
            let amounts = matches(for: #"(\d+[.,]?\d{0,2})"#, in: text)
            if let maxAmount = amounts.map({ Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }).max(), maxAmount > 0 {
                extractedAmount = String(format: "%.2f", maxAmount)
            }
        }
    }
    
    // Regex helper
    func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch {
            print("Invalid regex: \(error)")
            return []
        }
    }
    
    // MARK: - Persistence
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
    
    // MARK: - Save Transaction
    func saveTransaction() {
        guard let amount = Double(extractedAmount), amount > 0 else {
            saveMessage = "Invalid amount."
            showSaveAlert = true
            return
        }
        if isIncome {
            accountBalance += amount
            saveMessage = "Income added to account balance!"
            showSaveAlert = true
        } else {
            guard let idx = categories.firstIndex(where: { $0.name == selectedCategoryName }) else {
                saveMessage = "Category not found."
                showSaveAlert = true
                return
            }
            let tx = Transaction(amount: amount, store: extractedStore, date: Date(), categoryName: selectedCategoryName)
            categories[idx].transactions.append(tx)
            categories[idx].balance -= amount
            accountBalance -= amount // Deduct from account balance for expenses
            saveCategories()
            saveMessage = "Transaction saved to \(selectedCategoryName)!"
            showSaveAlert = true
        }
        // Reset UI
        image = nil
        recognizedText = ""
        extractedAmount = ""
        extractedStore = ""
        isIncome = false
    }
}

// MARK: - UIKit Picker Coordinator
class UIImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let onImagePicked: (UIImage) -> Void
    init(onImagePicked: @escaping (UIImage) -> Void) {
        self.onImagePicked = onImagePicked
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uiImage = info[.originalImage] as? UIImage {
            onImagePicked(uiImage)
        }
        picker.dismiss(animated: true)
    }
}

// VisualEffectBlur for SwiftUI (for macOS Monterey/iOS 15 compatibility)
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 