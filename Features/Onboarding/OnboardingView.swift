import SwiftUI

struct OnboardingPage {
    let mainIcon: String
    let floatingIcons: [String]
    let title: String
    let subtitle: String
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            mainIcon: "indianrupeesign.circle.fill",
            floatingIcons: ["cart.fill", "fork.knife", "car.fill"],
            title: "Track Every Rupee",
            subtitle: "Log your income and expenses in seconds. See exactly where your money goes, every single day."
        ),
        OnboardingPage(
            mainIcon: "chart.pie.fill",
            floatingIcons: ["target", "flag.checkered.circle.fill", "arrow.up.right.circle.fill"],
            title: "Smart Budgets",
            subtitle: "Set monthly limits for each category and get alerted before you overspend — not after."
        ),
        OnboardingPage(
            mainIcon: "lightbulb.fill",
            floatingIcons: ["chart.bar.fill", "star.fill", "gauge.with.dots.needle.67percent"],
            title: "Personalized Insights",
            subtitle: "Understand your spending habits with a Financial Score and tips tailored just for you."
        ),
        OnboardingPage(
            mainIcon: "lock.shield.fill",
            floatingIcons: ["checkmark.seal.fill", "icloud.fill", "faceid"],
            title: "Private & Secure",
            subtitle: "Your financial data stays protected with secure cloud backup. No bank linking required."
        )
    ]
    
    var body: some View {
        ZStack {
            // Simple, straight full-screen gradient - koi curve/rounded shape nahi
            AppTheme.heroCardGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                        .padding()
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 26 : 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 26)
                
                // Next / Get Started Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut) {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                        Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark.circle.fill")
                            .font(.headline)
                    }
                    .foregroundColor(.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(AppTheme.ctaGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        withAnimation {
            showOnboarding = false
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var animateMain = false
    @State private var animateFloat1 = false
    @State private var animateFloat2 = false
    @State private var animateFloat3 = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 240, height: 240)
                
                Circle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.floatingIcons[0])
                    .font(.system(size: 22))
                    .foregroundColor(.black.opacity(0.75))
                    .padding(12)
                    .background(AppTheme.ctaGradient)
                    .clipShape(Circle())
                    .offset(x: -95, y: -70)
                    .scaleEffect(animateFloat1 ? 1 : 0.4)
                    .opacity(animateFloat1 ? 1 : 0)
                
                Image(systemName: page.floatingIcons[1])
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(11)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                    .offset(x: 90, y: -85)
                    .scaleEffect(animateFloat2 ? 1 : 0.4)
                    .opacity(animateFloat2 ? 1 : 0)
                
                Image(systemName: page.floatingIcons[2])
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.75))
                    .padding(11)
                    .background(AppTheme.ctaGradient)
                    .clipShape(Circle())
                    .offset(x: 85, y: 80)
                    .scaleEffect(animateFloat3 ? 1 : 0.4)
                    .opacity(animateFloat3 ? 1 : 0)
                
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white)
                    .frame(width: 130, height: 130)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
                
                Image(systemName: page.mainIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(AppTheme.primaryIndigo)
            }
            .scaleEffect(animateMain ? 1.0 : 0.6)
            .opacity(animateMain ? 1.0 : 0.0)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 8)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            animateMain = false
            animateFloat1 = false
            animateFloat2 = false
            animateFloat3 = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                    animateMain = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                    animateFloat1 = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                    animateFloat2 = true
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4)) {
                    animateFloat3 = true
                }
            }
        }
    }
}
