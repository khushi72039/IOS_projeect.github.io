//
//  SplashView.swift
//  Finace_tracker_khushi
//
//  Created by Mobile5 on 15/07/26.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        if isActive {
            AuthCheckView()
        } else {
            ZStack {
                AppTheme.heroCardGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // TODO: Jab asli logo mil jaye, is Image ko replace kar dena:
                    // Image("AppLogo") // Assets.xcassets me logo add karke
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 130, height: 130)
                        Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    Text("Finance Tracker")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                    
                    Text("Insights • Budgets • Control")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(logoOpacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                // 2.5 second baad AuthCheckView par chale jao
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
