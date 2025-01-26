import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import SwiftUI

class MessagesManager: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastMessageId = ""
    let db = Firestore.firestore()
    var chatId: String = ""
    
    
    func getMessages(for chatId: String) {
        self.chatId = chatId
        db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.messages = documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                }
                
                self.messages.sort { $0.timestamp < $1.timestamp }
                if let id = self.messages.last?.id {
                    self.lastMessageId = id
                }
            }
    }
    
    func sendMessage(text: String) {
        do {
            let newMessage = Message(id: UUID().uuidString, text: text, received: false, timestamp: Date())
            try db.collection("chats").document(chatId).collection("messages").document().setData(from: newMessage)
        } catch {
            print("Error adding message to Firestore \(error)")
        }
    }
}
