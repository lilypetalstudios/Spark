//
//  ChatMessage.swift
//  Spark5.0
//
//  Created by sayuri patel on 10/21/24.
//

import Foundation

struct ChatMessage: Identifiable {
    var id: String 
    var senderId: String
    var content: String
    var timestamp: Date
}

