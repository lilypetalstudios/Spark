import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignUp: View {
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    @State private var navigateToSignUpP2 = false
    @State private var navigateToSignIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("signup")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -30)

                VStack {
                    TextField("enter your email", text: $email) //takes email input from user 
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 40)
                        .offset(y: 80)
                        .shadow(color: .black, radius: 1)

                    TextField("enter your username", text: $username) //takes username input from user 
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 40)
                        .offset(y: 80)
                        .shadow(color: .black, radius: 1)

                    SecureField("enter your password", text: $password) //takes password input from user 
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .padding(.horizontal, 40)
                        .offset(y: 80)
                        .shadow(color: .black, radius: 1)

                    SecureField("confirm your password", text: $confirmPassword) //takes password input from user again 
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .padding(.horizontal, 40)
                        .offset(y: 80)
                        .shadow(color: .black, radius: 1)

                    Button(action: {
                        signUpUser()
                    }) {
                        Text("continue")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.black)
                            .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    .offset(y: 100)
                    .disabled(email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)

                    // Display error messages
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding()
                    }

                    if let successMessage = successMessage {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.subheadline)
                            .padding()
                    }

                    Button(action: {
                        navigateToSignIn = true
                    }) {
                        Text("**already have an account? click here.**")
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 30)
                    .offset(y: 130)

                    NavigationLink(destination: SignUpP2(), isActive: $navigateToSignUpP2) {
                        EmptyView()
                    }

                    NavigationLink(destination: SignIn(), isActive: $navigateToSignIn) {
                        EmptyView()
                    }
                }
                .padding(.top, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    func signUpUser() {
        errorMessage = nil
        successMessage = nil

        guard isValidEmail(email) else {
            errorMessage = "invalid email format"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "passwords do not match"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "password must be at least 6 characters long"
            return
        }

        checkEmailAvailability(email) { emailAvailable in
            if !emailAvailable {
                errorMessage = "email is already in use"
                return
            }

            self.checkUsernameAvailability(username) { usernameAvailable in
                if !usernameAvailable {
                    errorMessage = "username is already in use"
                    return
                }

                self.createUserInFirebase()
            }
        }
    }

    func createUserInFirebase() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = "failed to create user: \(error.localizedDescription)"
            } else {
                if let uid = authResult?.user.uid {
                    self.saveUserData(uid: uid, email: email, username: username)
                }
                successMessage = "user registered successfully"
                self.navigateToSignUpP2 = true
            }
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Z|a-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }
    
    func checkEmailAvailability(_ email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
            if let error = error {
                errorMessage = "error checking email: \(error.localizedDescription)"
                completion(false)
            } else {
                completion(methods?.isEmpty ?? true)
            }
        }
    }
    
    func checkUsernameAvailability(_ username: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "error checking username: \(error.localizedDescription)"
                completion(false)
            } else {
                let isAvailable = snapshot?.isEmpty ?? false
                completion(isAvailable)
            }
        }
    }

    func saveUserData(uid: String, email: String, username: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "email": email,
            "username": username
        ]) { error in
            if let error = error {
                errorMessage = "error saving user data: \(error.localizedDescription)"
            }
        }
    }
    
}

#Preview {
    SignUp()
}
