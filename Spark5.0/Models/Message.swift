//
//  Message.swift
//  Spark5.0
//
//  Created by sayuri patel on 10/21/24.
//

import Foundation

struct Message: Identifiable, Codable {
    var id: String
    var text: String
    var received: Bool
    var timestamp: Date
}
