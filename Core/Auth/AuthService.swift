
import Foundation
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

enum AuthError: LocalizedError {
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .unknown(let message):
            return message
        }
    }
}

class AuthService {
    
    func signUp(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user.uid
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func logIn(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Google Sign-In (Naya function)
    // Yeh function ek "root view controller" maangta hai kyunki Google Sign-In
    // ek popup/browser screen dikhata hai jiske liye current screen ka reference chahiye
    @MainActor
    func signInWithGoogle(presenting viewController: UIViewController) async throws -> (uid: String, name: String, email: String, isNewUser: Bool) {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Google Client ID nahi mila")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            // Step 1: Google ka login popup dikhao
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.unknown("Google se token nahi mila")
            }
            let accessToken = result.user.accessToken.tokenString
            
            // Step 2: Google ke token ko Firebase credential me convert karo
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            // Step 3: Firebase me sign in karo us credential se
            let authResult = try await Auth.auth().signIn(with: credential)
            
            let name = authResult.user.displayName ?? result.user.profile?.name ?? "User"
            let email = authResult.user.email ?? ""
            
            // Yeh check karta hai ki yeh bilkul naya user hai ya pehle se hai
            let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
            
            return (authResult.user.uid, name, email, isNewUser)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    func logOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut() // Google session bhi clear karo
    }
    
    func currentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
