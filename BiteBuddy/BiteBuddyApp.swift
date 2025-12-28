import SwiftUI
import SwiftData

@main
struct BiteBuddyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
            UserPreferences.self,
            DailyLog.self,
            MealEntry.self,
            SavedFoodItem.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Migration failed - delete old data and create fresh container
            print("⚠️ Migration failed: \(error). Creating fresh database.")
            
            // Try to delete the old store
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            
            // Try again with fresh database
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after cleanup: \(error)")
            }
        }
    }()

    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1) // Ensure it sits on top during transition
                } else {
                    ChatView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showSplash)
            .onAppear {
                // Dismiss splash after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showSplash = false
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
