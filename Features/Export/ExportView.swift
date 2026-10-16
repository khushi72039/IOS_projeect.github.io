import SwiftUI

struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Date Range") {
                    DatePicker("From", selection: $viewModel.startDate, in: ...Date(), displayedComponents: .date)
                    DatePicker("To", selection: $viewModel.endDate, in: ...Date(), displayedComponents: .date)
                }
                
                Section {
                    Button {
                        Task { await viewModel.generateCSV() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isGenerating {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("Generate Export")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isGenerating)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let fileURL = viewModel.generatedFileURL {
                    Section("Export Ready") {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.incomeGreen)
                            Text("\(viewModel.exportedCount) transactions ready to export")
                                .font(.subheadline)
                        }
                        
                        ShareLink(item: fileURL) {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("Share CSV File")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .tint(AppTheme.primaryIndigo)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What's included")
                            .font(.caption.bold())
                        Text("Date, Type, Category, Amount, and Note for each transaction in the selected range")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .navigationTitle("Export Data")
            .onChange(of: viewModel.startDate) { _ in viewModel.resetExport() }
            .onChange(of: viewModel.endDate) { _ in viewModel.resetExport() }
            .onAppear {
                if let uid = authViewModel.currentUser?.id {
                    viewModel.setUserId(uid)
                }
            }
        }
    }
}
