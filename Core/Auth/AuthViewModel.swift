import Foundation
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var selectedCurrency: String = "INR"
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var toastMessage: String? = nil
    
    private let authService = AuthService()
    private let userRepository = UserRepository()
    
    init() {
        self.isLoggedIn = authService.currentUserId() != nil
        
        if let uid = authService.currentUserId() {
            Task {
                await fetchCurrentUser(uid: uid)
            }
        }
    }
    
    // MARK: - Signup Logic
    func signUp() async {
        errorMessage = nil
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        do {
            let uid = try await authService.signUp(email: email, password: password)
            
            let newUser = User(
                id: uid,
                name: name,
                email: email,
                currencyCode: selectedCurrency,
                createdAt: Date()
            )
            try await userRepository.createUser(newUser)
            
            print("DEBUG: Seeding categories for new signup user: \(uid)")
            let categoryRepository = CategoryRepository()
            let budgetRepository = BudgetRepository()
            do {
                let createdCategories = try await categoryRepository.seedDefaultCategories(userId: uid)
                print("DEBUG: Categories seeded: \(createdCategories.count)")
                try await budgetRepository.seedDefaultBudgets(userId: uid, categories: createdCategories)
                print("DEBUG: Budgets seeded successfully")
            } catch {
                print("DEBUG: Seeding failed with error: \(error.localizedDescription)")
            }
            
            self.currentUser = newUser
            isLoggedIn = true
            toastMessage = "Account Created Successfully! 🎉"
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                toastMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Login Logic
    func logIn() async {
        errorMessage = nil
        guard isValidEmail(email), !password.isEmpty else {
            errorMessage = "Please enter a valid email and password"
            return
        }
        
        isLoading = true
        do {
            let uid = try await authService.logIn(email: email, password: password)
            
            await fetchCurrentUser(uid: uid)
            
            isLoggedIn = true
            toastMessage = "Login Successful! ✅"
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                toastMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Fetch Current User from Firestore
    private func fetchCurrentUser(uid: String) async {
        do {
            self.currentUser = try await userRepository.fetchUser(userId: uid)
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Forgot Password Logic
    func resetPassword() async -> Bool {
        errorMessage = nil
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        isLoading = true
        do {
            try await authService.resetPassword(email: email)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - Google Sign-In Logic
    func signInWithGoogle() async {
        errorMessage = nil
        isLoading = true
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find the current screen"
            isLoading = false
            return
        }
        
        do {
            let result = try await authService.signInWithGoogle(presenting: rootVC)
            
            print("DEBUG: Google sign-in result - isNewUser: \(result.isNewUser), uid: \(result.uid)")
            
            if result.isNewUser {
                let newUser = User(
                    id: result.uid,
                    name: result.name,
                    email: result.email,
                    currencyCode: "INR",
                    createdAt: Date()
                )
                try await userRepository.createUser(newUser)
                
                print("DEBUG: Seeding categories for new Google user: \(result.uid)")
                let categoryRepository = CategoryRepository()
                let budgetRepository = BudgetRepository()
                do {
                    let createdCategories = try await categoryRepository.seedDefaultCategories(userId: result.uid)
                    print("DEBUG: Categories seeded: \(createdCategories.count)")
                    try await budgetRepository.seedDefaultBudgets(userId: result.uid, categories: createdCategories)
                    print("DEBUG: Budgets seeded successfully")
                } catch {
                    print("DEBUG: Seeding failed with error: \(error.localizedDescription)")
                }
                
                self.currentUser = newUser
            } else {
                print("DEBUG: Existing user detected, skipping seed")
                await fetchCurrentUser(uid: result.uid)
            }
            
            isLoggedIn = true
            toastMessage = "Login Successful! ✅"
            
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                toastMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Logout
    func logOut() {
        try? authService.logOut()
        isLoggedIn = false
        currentUser = nil
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
