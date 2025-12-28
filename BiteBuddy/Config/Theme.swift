import SwiftUI

struct Theme {
    struct Colors {
        // Backgrounds
        static let backgroundPrimary = Color(hex: "0F172A") // Rich Navy-Black (Slate 900)
        static let backgroundSecondary = Color(hex: "1E293B") // Dark Charcoal (Slate 800)
        static let backgroundInput = Color(hex: "334155") // Lighter Slate for Inputs
        
        // Accents
        static let primary = Color(hex: "10B981") // Neon Emerald (Wellness/Success)
        static let secondary = Color(hex: "06B6D4") // Cyan (Wellness/Water)
        static let warning = Color(hex: "EF4444") // Red
        
        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "94A3B8") // Slate 400
        static let textTertiary = Color(hex: "64748B") // Slate 500
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "10B981"), Color(hex: "059669")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let brandGradient = LinearGradient(
            colors: [Color(hex: "10B981"), Color(hex: "06B6D4")], // Emerald -> Cyan
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    struct Layout {
        static let cornerRadius: CGFloat = 20
        static let padding: CGFloat = 20
    }
}

// Centralized Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
