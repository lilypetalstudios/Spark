import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    @State private var chats: [Chat] = []
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("**your**")
                        .font(.system(size: 40))
                        .foregroundColor(Color.black)
                        .offset(y: 10)
                    Text("**chats**")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                        .offset(y: 10)
                }
                .padding()

                if isLoading {
                    ProgressView("loading chats...")
                } else {
                    List(chats) { chat in
                        NavigationLink(destination: DMView(chatId: chat.id, otherUserId: chat.otherUserId)) {
                            ChatRow(chat: chat)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color.white)
            .onAppear(perform: fetchUserChats)
        }
    }

    private func fetchUserChats() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("chats").whereField("userIds", arrayContains: userId).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching chats: \(error)")
                isLoading = false
                return
            }

            guard let documents = snapshot?.documents else {
                isLoading = false
                return
            }

            var fetchedChats: [Chat] = []
            let group = DispatchGroup()

            for document in documents {
                let data = document.data()
                let userIds = data["userIds"] as? [String] ?? []
                
                if userIds.count == 2, let otherUserId = userIds.first(where: { $0 != userId }) {
                    group.enter()
                    db.collection("users").document(otherUserId).getDocument { userSnapshot, error in
                        if let userSnapshot = userSnapshot, userSnapshot.exists,
                           let userData = userSnapshot.data(),
                           let otherUserName = userData["username"] as? String,
                           let avatarUrl = userData["avatar"] as? String {
                            let chat = Chat(id: document.documentID, otherUserId: otherUserId, otherUserName: otherUserName, avatarUrl: avatarUrl)
                            fetchedChats.append(chat)
                        } else {
                            print("Error fetching user data for \(otherUserId): \(error?.localizedDescription ?? "Unknown error")")
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                chats = fetchedChats
                isLoading = false
            }
        }
    }
}

struct Chat: Identifiable {
    var id: String
    var otherUserId: String
    var otherUserName: String
    var avatarUrl: String
}

struct ChatRow: View {
    var chat: Chat

    var body: some View {
        HStack {
            
            AsyncImage(url: URL(string: chat.avatarUrl)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.circle.fill") /
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 10)

            VStack(alignment: .leading) {
                Text(chat.otherUserName)
                    .font(.headline)

            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ChatView()
}
