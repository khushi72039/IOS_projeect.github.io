//
//  User.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 09/07/26.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String            // Firebase UID
    var name: String
    var email: String
    var currencyCode: String  // default "INR"
    var createdAt: Date
}
