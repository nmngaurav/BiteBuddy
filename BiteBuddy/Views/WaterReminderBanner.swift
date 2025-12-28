import SwiftUI

/// In-app water reminder banner
struct WaterReminderBanner: View {
    @Binding var isShowing: Bool
    let onTap: () -> Void
    
    @State private var offset: CGFloat = -100
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hydration Reminder")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("Time for a water break!")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    onTap()
                    dismiss()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding()
            .background(Theme.Colors.backgroundSecondary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .padding(.horizontal)
            .offset(y: offset)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                offset = 20
            }
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShowing = false
        }
    }
}
