import SwiftUI
import Firebase
import FirebaseAuth

struct SignUpP2: View {
    @State private var bio: String = ""
    @State private var accomplishments: String = ""
    @State private var strengths: String = ""
    @State private var weaknesses: String = ""
    @State private var successMessage: String? = nil
    @State private var errorMessage: String? = nil
    @State private var isSaving: Bool = false
    @State private var navigateToNextScreen: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Image("signup")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -30)

                VStack {
                    Spacer().frame(height: 260)

               
                    TextEditor(text: $bio) //asks user to provide some information about themselves (hobbies, fun facts, etc.) 
                        .frame(width: 300, height: 50)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .placeholder(when: bio.isEmpty) {
                            Text("bio/fun facts about yourself!")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                    Spacer().frame(height: 20)

                 
                    TextEditor(text: $accomplishments) //asks user to input any accomplishments to let other users know their academic strengths 
                        .frame(width: 300, height: 50)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .placeholder(when: accomplishments.isEmpty) {
                            Text("some accomplishments")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                    Spacer().frame(height: 20)

                 
                    TextEditor(text: $strengths) //asks user to input any academic strengths or interests they may have 
                        .frame(width: 300, height: 50)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .placeholder(when: strengths.isEmpty) {
                            Text("some strengths")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                    Spacer().frame(height: 20)

                 
                    TextEditor(text: $weaknesses) //asks user to input any academic weaknesses they may have 
                        .frame(width: 300, height: 50)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .placeholder(when: weaknesses.isEmpty) {
                            Text("some weaknesses")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                    Spacer().frame(height: 30)
                    NavigationLink(destination: SignUpP3(), isActive: $navigateToNextScreen) {
                        Text("continue")
                            .font(.headline)
                            .padding()
                            .frame(width: 300)
                            .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            print("Continue button tapped")
                            isSaving = true
                            saveUserData()
                        }
                    )

                    if isSaving {
                        ProgressView("Saving...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }

                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    func saveUserData() {
        print("saveUserData() called")
            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "User is not logged in."
                print("Error: User not logged in.")
                return
            }

            print("Authenticated user ID: \(uid)")

        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "bio": bio,
            "accomplishments": accomplishments,
            "strengths": strengths,
            "weaknesses": weaknesses
        ], merge: true) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Error saving data: \(error.localizedDescription)"
            } else {
                successMessage = "Information saved successfully!"
                clearFields()
                navigateToNextScreen = true
            }
        }
    }

    func clearFields() {
        bio = ""
        accomplishments = ""
        strengths = ""
        weaknesses = ""
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            self
            if shouldShow {
                placeholder()
            }
        }
    }
}

#Preview {
    SignUpP2()
}
