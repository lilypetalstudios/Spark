import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ChatListView: View {
    @State private var chats: [String] = []
    @State private var errorMessage: AlertItem?
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            List {
                ForEach(chats, id: \.self) { chatId in
                    NavigationLink(destination: ChatView()) {
                        Text("Chat with User")
                    }
                }
            }
            .navigationTitle("Chats 💬")
            .onAppear {
                fetchUserChats()
            }
        }
        
    }

    func fetchUserChats() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("chats").whereField("users", arrayContains: currentUserId).getDocuments { snapshot, error in
            if let error = error {
                errorMessage = AlertItem(title: "Error", message: "Failed to fetch user chats: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            self.chats = documents.map { $0.documentID } 
        }
    }
}
#Preview {
    ChatListView()
}
