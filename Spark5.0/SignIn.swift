import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SignIn: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSignedIn: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("signin")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -30)

                VStack {
                    Spacer().frame(height: 300)

                  
                    TextField("enter username", text: $username)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .frame(width: 350)
                        .autocapitalization(.none)
                        .padding(.bottom, 10)
                        .shadow(color: .black, radius: 1)

                  
                    SecureField("enter password", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .frame(width: 350)
                        .padding(.bottom, 20)
                        .shadow(color: .black, radius: 1)

                   
                    Button(action: {
                        signInUser()
                    }) {
                        Text("sign in")
                            .font(.headline)
                            .padding()
                            .frame(width: 350)
                            .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 10)

                   
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.bottom, 20)
                    }

                    Spacer()

                    NavigationLink(destination: SignUp()) {
                        Text("**don't have an account? click here to sign up**")
                            .foregroundColor(.black)
                    }
                    .padding(.bottom, 180)
                }

                
                NavigationLink(destination: HomePage(), isActive: $isSignedIn) {
                    EmptyView()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func signInUser() {
        let db = Firestore.firestore()
        

        print("Attempting to sign in user with username: \(username)")
        
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { (querySnapshot, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to fetch user: \(error.localizedDescription)"
                    print("Error fetching user: \(error.localizedDescription)")
                }
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "Username not found"
                    print("Username not found or no documents returned")
                }
                return
            }

            if let email = documents.first?.get("email") as? String {
                print("Found email: \(email), attempting to sign in...")

                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Sign-in failed: \(error.localizedDescription)"
                            print("Sign-in failed: \(error.localizedDescription)")
                        } else {
                            self.errorMessage = nil
                            self.isSignedIn = true
                            print("User signed in successfully!")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to retrieve email from username"
                    print("No email field found for this user")
                }
            }
        }
    }
}

#Preview {
    SignIn()
}
