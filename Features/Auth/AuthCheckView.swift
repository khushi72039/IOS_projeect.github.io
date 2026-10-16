import SwiftUI

struct AuthCheckView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            // App me pehli baar login hone par notification permission maango
            _ = await NotificationService.shared.requestAuthorization()
        }
    }
}
