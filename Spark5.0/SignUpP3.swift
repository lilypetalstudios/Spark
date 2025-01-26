import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseAuth

struct SignUpP3: View {
    @State private var selectedAvatar: String? = nil
    
  
    let avatarOptions = [
        "avatar1", "avatar2", "avatar3", "avatar4", "avatar5",
        "avatar6", "avatar7", "avatar8", "avatar9", "avatar10"]

    var body: some View {
        NavigationStack {
            ZStack {
                Image("signup")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .offset(x: -30)

                VStack {
                    Spacer()
                        .frame(height: 100)

  
                    Text("**select an avatar!**")
                        .offset(y: 180)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(avatarOptions, id: \.self) { avatar in
                                Button(action: {
                                    selectedAvatar = avatar
                                    saveAvatarToFirebase(avatar: avatar)
                                }) {
                                    Image(avatar)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(selectedAvatar == avatar ? Color.black : Color.clear, lineWidth: 4)
                                        )
                                }
                            }
                        }
                    }
                    .offset(y: 235)

                    NavigationLink(destination: HomePage()) {
                        Text("continue")
                            .font(.headline)
                            .padding()
                            .frame(width: 250)
                            .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                    .offset(x: -20, y: 300)
                    .padding(.leading, 40)
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    
    func saveAvatarToFirebase(avatar: String) {
        guard let image = UIImage(named: avatar) else {
            print("Error: Image not found.")
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to data.")
            return
        }
        
        let userId = Auth.auth().currentUser?.uid ?? UUID().uuidString
        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload avatar: \(error.localizedDescription)")
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let urlString = url?.absoluteString else {
                    print("Error: URL is nil.")
                    return
                }
                
                Firestore.firestore().collection("users").document(userId).setData([
                    "avatar": urlString
                ], merge: true) { error in
                    if let error = error {
                        print("Failed to save avatar URL: \(error.localizedDescription)")
                    } else {
                        print("Avatar URL saved successfully!")
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpP3()
}
