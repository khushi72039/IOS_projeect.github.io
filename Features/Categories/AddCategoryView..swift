import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    
    let availableIcons = [
        "tag.fill", "fork.knife", "car.fill", "popcorn.fill", "bag.fill",
        "doc.text.fill", "cross.case.fill", "banknote.fill", "house.fill",
        "gift.fill", "airplane", "book.fill", "gamecontroller.fill",
        "pawprint.fill", "graduationcap.fill", "wrench.fill"
    ]
    
   
    let availableColors = [
        "FF9F43", "54A0FF", "A55EEA", "FD79A8", "778CA3",
        "26DE81", "20BF6B", "EE5A6F", "FC5C65", "45AAF2"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $viewModel.newCategoryName)
                    
                    Picker("Type", selection: $viewModel.newCategoryType) {
                        Text("Expense").tag(CategoryType.expense)
                        Text("Income").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Choose Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(viewModel.newCategoryIcon == icon ? .white : AppTheme.primaryIndigo)
                                .frame(width: 44, height: 44)
                                .background(
                                    viewModel.newCategoryIcon == icon
                                        ? Color(hex: viewModel.newCategoryColorHex)
                                        : AppTheme.fieldBackground
                                )
                                .clipShape(Circle())
                                .onTapGesture {
                                    viewModel.newCategoryIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Choose Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: viewModel.newCategoryColorHex == colorHex ? 3 : 0)
                                )
                                .onTapGesture {
                                    viewModel.newCategoryColorHex = colorHex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Add Category")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.addCategory()
                            if success { dismiss() }
                        }
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}
