//
//  FAQView.swift
//  Helix
//
//  Created by Richard Waithe on 11/3/24.
//

import SwiftUI

struct FAQView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedQuestions: Set<String> = []
    
    // FAQ data structure
    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
    
    let faqItems: [FAQItem] = [
        FAQItem(
            question: "What is a digital business card?",
            answer: "A digital business card is a modern alternative to traditional paper business cards. It's a digital representation of your contact information and professional profile that can be easily shared via a link, QR code, or NFC technology."
        ),
        FAQItem(
            question: "How does a digital business card work?",
            answer: "Your digital business card lives online and can be accessed through a unique URL or by scanning a QR code. When someone accesses your card, they'll see your contact information, social media links, and any other content you've chosen to share. They can save your information directly to their phone contacts or connect with you through your social media profiles."
        ),
        FAQItem(
            question: "Why should I use a digital business card instead of a traditional one?",
            answer: "Digital business cards offer several advantages: they're eco-friendly, always up-to-date, never run out, can be shared instantly, include interactive elements like direct links to your social profiles, and can be updated anytime. Plus, you can track when people view your card and include much more information than a traditional paper card. Most importantly, by providing a rich, interactive experience with your professional profile, social links, and additional content, digital business cards help create more meaningful and memorable connections with your network."
        ),
        FAQItem(
            question: "What information can I include on my digital business card?",
            answer: "You can include your name, title, company, contact information (phone, email), social media links, profile photo, about me section, pronouns, custom message, and even upload documents like your CV (available in Pro version)."
        ),
        FAQItem(
            question: "Do you have a mobile app?",
            answer: "Yes! We have an iOS app available on the App Store. Our Android app is currently in development and coming soon. In the meantime, Android users can access all features through our mobile-responsive website."
        ),
        FAQItem(
            question: "Will my digital business card work on all devices?",
            answer: "Yes, your digital business card is fully responsive and works on all modern devices and browsers, including smartphones, tablets, and computers."
        ),
        FAQItem(
            question: "Can I have multiple digital cards under one account?",
            answer: "Free users can create one business card. Pro users can create up to 10 different cards, perfect for managing different jobs, roles, and side hustles."
        ),
        FAQItem(
            question: "How do I share my card?",
            answer: "You can share your card by clicking on the 'Share' button on your card's page. You can share via email, social media, or by generating a QR code. You can also add your card to a physical NFC card. You'll need to download the HelixCard app to do this."
        ),
        FAQItem(
            question: "What is an NFC card and how does it work?",
            answer: "An NFC (Near Field Communication) card contains a small chip that wirelessly shares your digital business card when tapped with a smartphone. For iPhone users, simply hold the card near the top of your phone. For Android users, ensure NFC is enabled in settings and tap the card against the back of your phone. When tapped, your phone will instantly receive a notification to view the digital business card - no app download required."
        ),
        FAQItem(
            question: "Will my digital business card automatically update if I make changes?",
            answer: "Yes! Any changes you make to your digital business card are updated instantly, and all shared links will automatically display the most current information."
        ),
        FAQItem(
            question: "What should I do if my card isn't displaying correctly?",
            answer: "First, try refreshing your browser or clearing your cache. If the issue persists, please contact our support team via email or text, and we'll help resolve the problem."
        ),
        FAQItem(
            question: "What is the difference between free and pro accounts?",
            answer: "Free accounts include one digital business card and up to 2 contacts with basic features like profile image upload and NFC sharing. Pro accounts ($2.99/month or $12.99/year) unlock premium features including: up to 10 business cards, unlimited contacts, AI powered business card scanning, CV/resume upload capability, and future updates and capabilities."
        ),
        FAQItem(
            question: "Can I cancel my subscription anytime?",
            answer: "Yes, you can cancel your Pro subscription at any time. Your Pro features will remain active until the end of your current billing period."
        ),
        FAQItem(
            question: "What is your refund policy?",
            answer: "We do not offer refunds on subscription payments. You can cancel your subscription at any time to prevent future charges."
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Add header section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequently Asked Questions")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.bodyPrimaryText)
                        
                        Text("Quick answers to common questions")
                            .font(.subheadline)
                            .foregroundColor(AppColors.bodySecondaryText)
                    }
                    .padding(.bottom, 24)
                    
                    ForEach(faqItems) { item in
                        faqItem(item)
                    }
                }
                .padding()
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func faqItem(_ item: FAQItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedQuestions.contains(item.question) {
                        expandedQuestions.remove(item.question)
                    } else {
                        expandedQuestions.insert(item.question)
                    }
                }
            }) {
                HStack {
                    Text(item.question)
                        .font(.headline)
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.bodyPrimaryText)
                        .rotationEffect(.degrees(
                            expandedQuestions.contains(item.question) ? 90 : 0
                        ))
                        .animation(.easeInOut(duration: 0.3), value: expandedQuestions.contains(item.question))
                }
            }
            
            if expandedQuestions.contains(item.question) {
                Text(item.answer)
                    .font(.body)
                    .foregroundColor(AppColors.bodySecondaryText)
                    .padding(.top, 4)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: expandedQuestions.contains(item.question))
            }
            
            Divider()
                .padding(.top, 8)
        }
    }
}

#Preview {
    FAQView()
}