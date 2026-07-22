import SwiftUI
import FirebaseCore

@main
struct FinanceTrackerApp: App {
    @StateObject private var authViewModel = AuthViewModel()   // Yahan ek hi baar banaya
    // Firebase ko app start hote hi configure karne ke liye
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView().environmentObject(authViewModel)
        }
    }
}
