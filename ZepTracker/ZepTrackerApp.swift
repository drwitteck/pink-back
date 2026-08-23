import SwiftUI
import SwiftData

@main
struct ZepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: LogEntry.self)
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }

            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }
        }
        .tint(.teal)
    }
}
