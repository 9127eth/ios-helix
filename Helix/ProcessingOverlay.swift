import SwiftUI

struct ProcessingOverlay: View {
    var message: String = "Processing Image..."
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                Text(message)
                    .foregroundColor(.white)
                    .padding(.top)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
} 