import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct User: Identifiable { 
    var id: String
    var username: String
    var bio: String
    var profilePictureUrl: String
    var accomplishments: String
    var strengths: String
    var weaknesses: String
}

struct MatchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [User] = []
    @State private var currentIndex: Int = 0
    @State private var matchedUsers: [String] = []
    @State private var dragOffset: CGSize = .zero
    @State private var swipedUserIds: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)

                if users.isEmpty {
                    Text("No more users")
                        .font(.headline)
                        .foregroundColor(.gray)
                } else {
                    VStack {
                       
                        let user = users[currentIndex]

                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .frame(width: 350, height: 600)
                            .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
                            .overlay(
                                VStack {
                                    AsyncImage(url: URL(string: user.profilePictureUrl)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100) 
                                                .clipShape(Circle())
                                                .padding(.top)
                                        case .failure:
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .padding(.top)
                                                .foregroundColor(.gray)
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    Text(user.username)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    Text(user.bio)
                                        .font(.body)
                                        .padding()
                                        .multilineTextAlignment(.center)
                                    Text("accomplishments 🏅: \(user.accomplishments)")
                                        .font(.footnote)
                                        .padding()
                                        .multilineTextAlignment(.center)
                                    Text("strengths 💪: \(user.strengths)")
                                        .font(.footnote)
                                        .padding()
                                        .multilineTextAlignment(.center)
                                    Text("weaknesses 😥: \(user.weaknesses)")
                                        .font(.footnote)
                                        .padding()
                                        .multilineTextAlignment(.center)
                                }
                            )
                            .offset(x: dragOffset.width, y: 0)
                            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        if value.translation.width > 100 {
                                            swipeRight(user: user)
                                        } else if value.translation.width < -100 {
                                            swipeLeft(user: user)
                                        } else {
                                            dragOffset = .zero
                                        }
                                    }
                            )
                            .animation(.spring(), value: dragOffset)

                        HStack {
                            Button(action: {
                                if currentIndex < users.count {
                                    swipeLeft(user: users[currentIndex])
                                }
                            }) {
                                Image(systemName: "hand.thumbsdown.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.black)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                            Button(action: {
                                if currentIndex < users.count {
                                    swipeRight(user: users[currentIndex])
                                }
                            }) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                            Text("Back")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchSwipedUsers()
        }
    }

    private func fetchSwipedUsers() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(currentUserId)
        userDocRef.getDocument { document, error in
            if let document = document, document.exists {
                if let swipes = document.data()?["swipes"] as? [String: String] {
                    self.swipedUserIds = Array(swipes.keys)
                }
                fetchUsers()
            } else {
                print("User document does not exist.")
            }
        }
    }

    private func fetchUsers() {
        let db = Firestore.firestore()
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            self.users = documents.compactMap { doc -> User? in
                let data = doc.data()
                let username = data["username"] as? String ?? ""
                let bio = data["bio"] as? String ?? ""
                let profilePictureUrl = data["avatar"] as? String ?? ""
                let accomplishments = data["accomplishments"] as? String ?? ""
                let strengths = data["strengths"] as? String ?? ""
                let weaknesses = data["weaknesses"] as? String ?? ""
                return User(id: doc.documentID, username: username, bio: bio, profilePictureUrl: profilePictureUrl, accomplishments: accomplishments, strengths: strengths, weaknesses: weaknesses)
            }
            .filter { $0.id != currentUserId && !swipedUserIds.contains($0.id) }
            
            if users.isEmpty {
                currentIndex = 0
            } else {
                currentIndex = min(currentIndex, users.count - 1)
            }
        }
        
    }

    private func swipeLeft(user: User) { //when a user isn't interested in studying with another user 
        updateSwipes(user: user, direction: "left")
        moveToNextUser()
    }

    private func swipeRight(user: User) { //when a user wants to study with another user
        updateSwipes(user: user, direction: "right")
        ChatManager.shared.checkForMatchAndCreateChat(for: user)
        moveToNextUser()
    }

    private func moveToNextUser() { 
        if currentIndex < users.count {
            users.remove(at: currentIndex)
        }
        
        if currentIndex >= users.count {
            currentIndex = 0
        } else {
           
            currentIndex = min(currentIndex, users.count - 1)
        }
        
       
        dragOffset = .zero
    }

    private func updateSwipes(user: User, direction: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).updateData([
            "swipes.\(user.id)": direction
        ]) { error in
            if let error = error {
                print("Error updating swipes: \(error)")
            }
        }
    }

    private func checkForMatch(user: User) { //checks to see if both users approved each other 
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.id).getDocument { document, error in
            if let document = document, document.exists {
                let swipes = document.data()?["swipes"] as? [String: String] ?? [:]
                if swipes[currentUser.uid] == "right" {
                    self.matchedUsers.append(user.id)
                    
                    createChat(with: user.id)
                }
            }
        }
    }

    private func createChat(with otherUserId: String) { //run when user successfully creates a match (both users approve each other) 
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let chatId = UUID().uuidString
        let chatData: [String: Any] = [
            "userIds": [currentUser.uid, otherUserId],
            "lastMessage": "",
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats").document(chatId).setData(chatData) { error in
            if let error = error {
                print("Error creating chat: \(error)")
            }
        }
    }
}
#Preview {
    MatchView()
}
