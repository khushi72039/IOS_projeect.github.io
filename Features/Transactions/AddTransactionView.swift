import SwiftUI
import PhotosUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @StateObject private var categoryViewModel = CategoryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCamera = false
    @State private var showPhotosPicker = false
    @State private var photosPickerItem: PhotosPickerItem? = nil
    
    var filteredCategories: [Category] {
        viewModel.selectedType == .income ? categoryViewModel.incomeCategories : categoryViewModel.expenseCategories
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $viewModel.selectedType) {
                        Text("Expense").tag(CategoryType.expense)
                        Text("Income").tag(CategoryType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedType) { _ in
                        viewModel.selectedCategory = nil
                    }
                }
                
                Section("Amount") {
                    TextField("0", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(.title2.bold())
                }
                
                Section("Category") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 14) {
                        ForEach(filteredCategories) { category in
                            VStack(spacing: 6) {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 46, height: 46)
                                    .background(Color(hex: category.colorHex))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.primaryIndigo, lineWidth: viewModel.selectedCategory?.id == category.id ? 3 : 0)
                                            .padding(-3)
                                    )
                                
                                Text(category.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Date") {
                    DatePicker("Transaction Date", selection: $viewModel.selectedDate, in: ...Date(), displayedComponents: .date)
                }
                
                Section("Note (Optional)") {
                    TextField("Add a note...", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section {
                    Toggle("Make this recurring", isOn: $viewModel.isRecurringEnabled)
                    
                    if viewModel.isRecurringEnabled {
                        Picker("Frequency", selection: $viewModel.recurringFrequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                        }
                    }
                } footer: {
                    if viewModel.isRecurringEnabled {
                        Text("A new transaction will be automatically created each time this repeats, starting from the selected date")
                    }
                }
                
                Section("Receipt Photo (Optional)") {
                    if let image = viewModel.selectedReceiptImage {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button("Remove Photo") {
                                viewModel.selectedReceiptImage = nil
                            }
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.expenseRed)
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button {
                                showCamera = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                    Text("Camera")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .foregroundColor(AppTheme.primaryIndigo)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            Button {
                                showPhotosPicker = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.fill")
                                        .font(.title3)
                                    Text("Gallery")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .foregroundColor(AppTheme.primaryIndigo)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(selectedImage: $viewModel.selectedReceiptImage)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItem, matching: .images)
            .onChange(of: photosPickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.selectedReceiptImage = uiImage
                    }
                }
            }
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    categoryViewModel.setUserId(uid)
                    Task { await categoryViewModel.fetchCategories() }
                }
            }
        }
    }
    
    // Save button ko alag computed property me nikala - compiler ke liye asaan banane ke liye
    private var saveButton: some View {
        Button {
            Task {
                let success = await viewModel.addTransaction()
                if success { dismiss() }
            }
        } label: {
            saveButtonLabel
        }
        .disabled(viewModel.isUploadingImage)
    }
    
    @ViewBuilder
    private var saveButtonLabel: some View {
        if viewModel.isUploadingImage {
            ProgressView()
        } else {
            Text("Save").fontWeight(.bold)
        }
    }
}
