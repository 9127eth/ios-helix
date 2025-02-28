//
//  SubscriptionView.swift
//  Helix
//
//  Created by Richard Waithe on 10/17/24.
//

import SwiftUI
import StoreKit
import Firebase
import FirebaseAuth

struct SubscriptionView: View {
    @Binding var isPro: Bool
    @State private var selectedPlan: PlanType = .lifetime
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentUserPlan: PlanType?
    @State private var animateCards = false
    
    enum PlanType {
        case lifetime
        case yearly
        case monthly
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.background,
                    AppColors.mainSubBackground
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                LoadingView(message: "Loading subscription options...")
            } else if let error = errorMessage {
                ErrorView(message: error)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with close button
                        headerView
                        
                        // Hero section
                        heroSection
                        
                        // Plan selection
                        if !isPro {
                            planSelectionView
                        }
                        
                        // Plan cards
                        planCardsView
                        
                        // Testimonials
                        testimonialsView
                        
                        // FAQ
                        faqSection
                        
                        // Restore purchases button
                        restorePurchasesButton
                        
                        // Terms and privacy
                        termsAndPrivacyText
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            Task {
                await loadProducts()
                await loadCurrentPlan()
                
                // Animate cards after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateCards = true
                    }
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
            }
        }
        .padding(.top, 16)
    }
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image("subscription")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .padding()
                .background(
                    Circle()
                        .fill(AppColors.helixPro.opacity(0.1))
                )
            
            Text("Elevate Your Networking Experience with Helix Pro")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Text("Join the many professionals who use Helix Pro to streamline their networking, manage digital cards, and make lasting impressions")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
    
    private var planSelectionView: some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            Picker("Plan", selection: $selectedPlan) {
                Text("Lifetime").tag(PlanType.lifetime)
                Text("Yearly").tag(PlanType.yearly)
                Text("Monthly").tag(PlanType.monthly)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
    
    private var planCardsView: some View {
        VStack(spacing: 20) {
            // Pro Plan Card
            EnhancedPlanCard(
                title: "Helix Pro",
                price: priceForSelectedPlan,
                savings: savingsText,
                features: [
                    "Up to 10 business cards",
                    "AI powered business card scanning",
                    "CV/Resume Upload",
                    "Link to physical card via NFC",
                    "Add to Apple Wallet"
                ],
                isPopular: true,
                isCurrentPlan: isPro,
                iconName: "lightening",
                action: {
                    if !isPro {
                        purchaseSubscription(for: selectedPlan)
                    }
                }
            )
            .offset(y: animateCards ? 0 : 100)
            .opacity(animateCards ? 1 : 0)
            
            // Free Plan Card
            EnhancedPlanCard(
                title: "Free Plan",
                price: "Free",
                features: [
                    "1 free business card",
                    "Link to physical card via NFC",
                    "Add to Apple Wallet"
                ],
                disabledFeatures: [
                    "Up to 10 business cards",
                    "AI powered business card scanning",
                    "CV/Resume Upload"
                ],
                isCurrentPlan: !isPro,
                iconName: "cardsNavi",
                action: { }
            )
            .offset(y: animateCards ? 0 : 100)
            .opacity(animateCards ? 1 : 0)
            .scaleEffect(0.95)
        }
    }
    
    private var testimonialsView: some View {
        VStack(spacing: 16) {
            Text("What Our Users Say")
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(testimonials, id: \.name) { testimonial in
                        TestimonialCard(testimonial: testimonial)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 10)
    }
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
            
            VStack(spacing: 12) {
                FAQItem(question: "Can I cancel anytime?", answer: "Yes, you can cancel your subscription at any time through your App Store settings.")
                
                FAQItem(question: "Can Helix Pro save me money?", answer: "Absolutely! You'll save on printing costs for physical cards, card holders, and most importantly, the countless hours spent managing contacts manually. The AI scanning feature alone can save you hours of data entry time.")
                
                FAQItem(question: "Is the Lifetime plan really one-time?", answer: "Yes! Pay once and enjoy Helix Pro features forever with no recurring charges.")
            }
        }
        .padding(.vertical, 10)
    }
    
    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                do {
                    try await subscriptionManager.restorePurchases()
                    if !subscriptionManager.purchasedSubscriptions.isEmpty || subscriptionManager.isLifetime {
                        isPro = true
                        presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    errorMessage = "Failed to restore: \(error.localizedDescription)"
                }
            }
        }) {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundColor(AppColors.helixPro)
        }
        .padding(.vertical, 10)
    }
    
    private var termsAndPrivacyText: some View {
        Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.")
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
            .padding(.horizontal)
    }
    
    // MARK: - Helper Properties
    
    private var priceForSelectedPlan: String {
        if isPro {
            return currentUserPlan == .monthly ? "$2.99/month" : 
                   currentUserPlan == .yearly ? "$12.99/year" : 
                   "Lifetime Pro"
        } else {
            return selectedPlan == .monthly ? "$2.99/month" : 
                   selectedPlan == .yearly ? "$12.99/year" : 
                   "$19.99 one-time"
        }
    }
    
    private var savingsText: String? {
        if selectedPlan == .yearly {
            return "Save 64% vs monthly"
        } else if selectedPlan == .lifetime {
            return "Best value"
        }
        return nil
    }
    
    // MARK: - Data Loading Methods
    
    @MainActor
    private func loadProducts() async {
        isLoading = true
        do {
            try await subscriptionManager.loadProducts()
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    @MainActor
    private func loadCurrentPlan() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let subscriptionId = doc.data()?["stripeSubscriptionId"] as? String {
                currentUserPlan = subscriptionId.contains("monthly") ? .monthly : .yearly
            }
        } catch {
            print("Error loading current plan: \(error)")
        }
    }
    
    @MainActor
    private func purchaseSubscription(for planType: PlanType) {
        Task {
            do {
                let productId = switch planType {
                    case .yearly: "001"
                    case .monthly: "002"
                    case .lifetime: "003"
                }
                
                if let product = subscriptionManager.products.first(where: { $0.id == productId }) {
                    try await subscriptionManager.purchase(product)
                    isPro = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    print("Product not found: \(productId)")
                    errorMessage = "Product not available for purchase."
                }
            } catch {
                print("Failed to purchase: \(error)")
                errorMessage = "Failed to purchase: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Supporting Views

struct EnhancedPlanCard: View {
    let title: String
    let price: String
    var savings: String? = nil
    let features: [String]
    var disabledFeatures: [String] = []
    var isPopular: Bool = false
    let isCurrentPlan: Bool
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isPopular {
                    Text("POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.helixPro)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // Price
            VStack(alignment: .leading, spacing: 4) {
                Text(price)
                    .font(.system(size: 24, weight: .bold))
                
                if let savingsText = savings {
                    Text(savingsText)
                        .font(.caption)
                        .foregroundColor(AppColors.helixPro)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.helixPro.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.helixPro)
                            .font(.system(size: 16))
                        Text(feature)
                            .font(.subheadline)
                    }
                }
                
                ForEach(disabledFeatures, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Button
            Button(action: action) {
                HStack {
                    if title == "Helix Pro" && !isCurrentPlan {
                        Image("lightening")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    Text(buttonText)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(buttonBackground)
                .foregroundColor(buttonForeground)
                .cornerRadius(12)
                .shadow(color: title == "Helix Pro" && !isCurrentPlan ? AppColors.helixPro.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
            }
            .disabled(isButtonDisabled)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.cardSubBackground))
                .shadow(color: isPopular ? AppColors.helixPro.opacity(0.1) : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPopular ? AppColors.helixPro.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
    }
    
    private var buttonText: String {
        if isCurrentPlan {
            return "Current Plan"
        } else if title == "Helix Pro" {
            return "Get Helix Pro"
        } else {
            return "Free Plan"
        }
    }
    
    private var isButtonDisabled: Bool {
        isCurrentPlan || (title == "Free Plan") // Disable button for Free Plan regardless
    }
    
    private var buttonBackground: Color {
        if title == "Helix Pro" && !isCurrentPlan {
            return AppColors.helixPro
        } else {
            return isButtonDisabled ? Color.gray.opacity(0.2) : AppColors.buttonBackground
        }
    }
    
    private var buttonForeground: Color {
        if title == "Helix Pro" && !isCurrentPlan {
            return .white
        } else {
            return isButtonDisabled ? .primary : AppColors.buttonText
        }
    }
}

struct TestimonialCard: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(AppColors.helixPro.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(testimonial.name)
                        .font(.headline)
                    Text(testimonial.title)
                        .font(.caption)
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.7))
                }
            }
            
            Text("""
                \(testimonial.comment)
                """)
                .font(.subheadline)
                .foregroundColor(AppColors.bodyPrimaryText.opacity(0.9))
                .lineSpacing(4)
            
            HStack {
                ForEach(0..<5) { i in
                    Image(systemName: i < testimonial.rating ? "star.fill" : "star")
                        .foregroundColor(i < testimonial.rating ? AppColors.helixPro : Color.gray.opacity(0.3))
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.cardSubBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.bodyPrimaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppColors.bodyPrimaryText.opacity(0.6))
                        .font(.system(size: 14))
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.cardSubBackground))
        )
    }
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.headline)
                .foregroundColor(AppColors.bodyPrimaryText)
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.bodyPrimaryText.opacity(0.8))
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Data Models

struct Testimonial {
    let name: String
    let title: String
    let comment: String
    let rating: Int
}

// Sample testimonials
let testimonials = [
    Testimonial(
        name: "Robert Johnson",
        title: "Pharmacy Student",
        comment: "The CV upload feature helped me stand out at ASHP Midyear. Love this app!",
        rating: 5
    ),
    Testimonial(
        name: "Brian Gomez",
        title: "Sales Director",
        comment: "The AI card scanning feature has saved our team hours of manual data entry. Worth every penny!",
        rating: 5
    ),
    Testimonial(
        name: "Alice Foster",
        title: "Freelance Designer",
        comment: "I love being able to manage multiple business cards for different clients. The lifetime plan was a no-brainer!",
        rating: 5
    )
]

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView(isPro: .constant(false))
    }
}
