import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct DMView: View {
    var chatId: String
    var otherUserId: String

    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    
    @State private var otherUserName: String = ""
    @State private var otherUserAvatarURL: String = ""

    var body: some View {
        VStack {
            HStack {
                if !otherUserAvatarURL.isEmpty, let url = URL(string: otherUserAvatarURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 50, height: 50)
                    }
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                }
                
                Text(otherUserName)
                    .font(.headline)
                    .padding(.leading, 10)
                
                Spacer()
            }
            .padding()
            
            List(messages) { message in
                HStack {
                    if message.senderId == Auth.auth().currentUser?.uid {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(message.content)
                                .padding(10)
                                .background(Color(red: 0.9686, green: 0.8235, blue: 0.5412))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            Text("\(message.timestamp, formatter: itemFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(message.content)
                                .padding(10)
                                .background(Color(red: 209/255, green: 211/255, blue: 212/255))
                                .foregroundColor(.black)
                                .cornerRadius(10)
                            Text("\(message.timestamp, formatter: itemFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                }
            }
            .onAppear(perform: loadMessages)
            
            HStack {
                TextField("send a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    HStack {
                        Image(systemName: "paperplane.circle.fill")
                            .foregroundColor(.black)
                            .font(.system(size: 40))
                    }
                    .padding()
                }
            }
            .padding()
        }
        .onAppear(perform: loadOtherUserProfile)
    }
    
    private func loadOtherUserProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                otherUserName = data?["username"] as? String ?? "Unknown User"
                otherUserAvatarURL = data?["avatar"] as? String ?? ""
            } else {
                print("Error loading user profile: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    private func loadMessages() {
        let db = Firestore.firestore()
        
        db.collection("chats").document(chatId).collection("messages").order(by: "timestamp").addSnapshotListener { querySnapshot, error in
            if let error = error {
                print("Error loading messages: \(error)")
                return
            }

            messages = querySnapshot?.documents.compactMap { document in
                let data = document.data()
                let content = data["content"] as? String ?? ""
                let senderId = data["senderId"] as? String ?? ""
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                
                return ChatMessage(id: document.documentID, senderId: senderId, content: content, timestamp: timestamp)
            } ?? []
        }
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let db = Firestore.firestore()
        let messageData: [String: Any] = [
            "content": newMessage,
            "senderId": Auth.auth().currentUser?.uid ?? "",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("chats").document(chatId).collection("messages").addDocument(data: messageData) { error in
            if let error = error {
                print("Error sending message: \(error)")
            } else {
                newMessage = "" 
            }
        }
    }
}

private var itemFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}

#Preview {
    DMView(chatId: "sampleChatId", otherUserId: "sampleUserId")
}
