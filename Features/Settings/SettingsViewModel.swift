import Foundation
import UIKit

@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var name: String = ""
    @Published var currencyCode: String = "INR"
    @Published var profileImage: UIImage? = nil
    @Published var dailySpendingLimitText: String = "500"
    @Published var notificationsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                Task {
                    _ = await NotificationService.shared.requestAuthorization()
                }
            }
        }
    }
    @Published var isLoading: Bool = false
    @Published var toastMessage: String? = nil
    @Published var errorMessage: String? = nil
    @Published var updatedUser: User? = nil
    
    let currencies = ["INR", "USD", "EUR", "GBP"]
    
    private let userRepository = UserRepository()
    private var userId: String?
    
    func loadUser(_ user: User) {
        self.userId = user.id
        self.name = user.name
        self.currencyCode = user.currencyCode
        self.dailySpendingLimitText = String(format: "%.0f", user.dailySpendingLimit)
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        
        if let base64 = user.profileImageBase64 {
            self.profileImage = ImageHelper.imageFromBase64(base64)
        }
    }
    
    // MARK: - Update Profile (Name + Currency + Photo)
    func updateProfile() async -> Bool {
        guard let userId = userId else { return false }
        errorMessage = nil
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty"
            return false
        }
        
        isLoading = true
        do {
            if var user = try await userRepository.fetchUser(userId: userId) {
                user.name = trimmedName
                user.currencyCode = currencyCode
                
                if let image = profileImage {
                    user.profileImageBase64 = ImageHelper.compressToBase64(image)
                }
                
                try await userRepository.updateUser(user)
                updatedUser = user
                toastMessage = "Profile Updated Successfully! ✅"
                
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    toastMessage = nil
                }
                isLoading = false
                return true
            }
        } catch {
            errorMessage = "Failed to update profile"
        }
        isLoading = false
        return false
    }
    
    // MARK: - Update Daily Spending Limit (Widget ke liye)
    func updateDailySpendingLimit() async -> Bool {
        guard let userId = userId else { return false }
        errorMessage = nil
        
        guard let limit = Double(dailySpendingLimitText), limit > 0 else {
            errorMessage = "Please enter a valid amount"
            return false
        }
        
        isLoading = true
        do {
            if var user = try await userRepository.fetchUser(userId: userId) {
                user.dailySpendingLimit = limit
                try await userRepository.updateUser(user)
                updatedUser = user
                
                // Widget data turant refresh karo nayi limit ke saath
                await SharedDataManager.shared.syncWidgetData(userId: userId, dailyLimit: limit)
                
                toastMessage = "Daily Limit Updated! ✅"
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    toastMessage = nil
                }
                isLoading = false
                return true
            }
        } catch {
            errorMessage = "Failed to update daily limit"
        }
        isLoading = false
        return false
    }
}
