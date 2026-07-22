import SwiftUI

struct AuthCheckView: View {
    @EnvironmentObject var viewModel: AuthViewModel   // StateObject ki jagah ab EnvironmentObject
    
    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
