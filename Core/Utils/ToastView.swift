//
//  ToastView.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 15/07/26.
//

import SwiftUI

struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            LinearGradient(colors: [Color(red: 0.05, green: 0.5, blue: 0.45),
                                     Color(red: 0.04, green: 0.4, blue: 0.4)],
                           startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }
}
