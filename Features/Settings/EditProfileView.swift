import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var photosPickerItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $photosPickerItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let image = viewModel.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.primaryIndigo.opacity(0.15))
                                            .frame(width: 100, height: 100)
                                        Text(viewModel.name.prefix(1).uppercased())
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(AppTheme.primaryIndigo)
                                    }
                                }
                                
                                Image(systemName: "camera.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.primaryIndigo)
                                    .background(Circle().fill(.white))
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Profile Details") {
                    TextField("Full Name", text: $viewModel.name)
                    
                    Picker("Currency", selection: $viewModel.currencyCode) {
                        ForEach(viewModel.currencies, id: \.self) { Text($0) }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.updateProfile()
                            if success { dismiss() }
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(viewModel.isLoading)
                }
            }
            .onChange(of: photosPickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.profileImage = uiImage
                    }
                }
            }
        }
    }
}
