import Foundation
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var selectedCurrency: String = "INR"   // Naya add kiya
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var toastMessage: String? = nil    // Naya add kiya - success message ke liye
    // Naya add kiya - Firestore se aaya hua data
    
    private let authService = AuthService()
    private let userRepository = UserRepository()       // Naya add kiya
    
    init() {
        self.isLoggedIn = authService.currentUserId() != nil
        
        // Agar pehle se login hai, to Firestore se user ka data bhi fetch kar lo
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
            // Step 1: Firebase Authentication me account banao
            let uid = try await authService.signUp(email: email, password: password)
            
            // Step 2: Firestore me User document banao (naam, currency, email save karne ke liye)
            let newUser = User(
                id: uid,
                name: name,
                email: email,
                currencyCode: selectedCurrency,
                createdAt: Date()
            )
            try await userRepository.createUser(newUser)
                        
                        // Naye user ke liye default categories bhi bana do
                        let categoryRepository = CategoryRepository()
                        try? await categoryRepository.seedDefaultCategories(userId: uid)
                        
                        self.currentUser = newUser
                        isLoggedIn = true
                        toastMessage = "Account Created Successfully! 🎉"
                        
                        // 2 second baad toast apne aap gayab ho jaye
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
            
            // Login ke baad Firestore se user ka poora data (naam, currency) fetch karo
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
            print("Error fetching user:  \(error.localizedDescription)")
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
    
    // MARK: - Logout
    func logOut() {
        try? authService.logOut()
        isLoggedIn = false
        currentUser = nil
    }
    
    
    // MARK: - Google Sign-In Logic
        func signInWithGoogle() async {
            errorMessage = nil
            isLoading = true
            
            // Current screen ka UIViewController dhoondhna (SwiftUI me thoda manual karna padta hai)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                errorMessage = "Unable to find the current screen"
                isLoading = false
                return
            }
            
            do {
                let result = try await authService.signInWithGoogle(presenting: rootVC)
                
                if result.isNewUser {
                    // Naya user hai to Firestore me User document banao
                    let newUser = User(
                        id: result.uid,
                        name: result.name,
                        email: result.email,
                        currencyCode: "INR", // Google Sign-In me currency picker nahi hai, isliye default
                        createdAt: Date()
                    )
                    try await userRepository.createUser(newUser)
                    self.currentUser = newUser
                } else {
                    // Purana user hai to Firestore se uska data fetch karo
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
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}
