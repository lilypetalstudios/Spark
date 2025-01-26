//
//  ChatManager.swift
//  Spark5.0
//
//  Created by sayuri patel on 10/21/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ChatManager {
    static let shared = ChatManager()
    
    private init() {}

    func checkForMatchAndCreateChat(for user: User) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.id).getDocument { document, error in
            if let document = document, document.exists {
                let swipes = document.data()?["swipes"] as? [String: String] ?? [:]
                if swipes[currentUser.uid] == "right" {
                    // Mutual match found
                    self.createChat(with: user.id)
                }
            }
        }
    }

    private func createChat(with otherUserId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let chatId = UUID().uuidString // Generate a unique chat ID
        let chatData: [String: Any] = [
            "userIds": [currentUser.uid, otherUserId],
            "lastMessage": "",
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("chats").document(chatId).setData(chatData) { error in
            if let error = error {
                print("Error creating chat: \(error)")
            } else {
                print("Chat created successfully between \(currentUser.uid) and \(otherUserId)")
                // Notify that a chat has been created, if needed
            }
        }
    }
}
