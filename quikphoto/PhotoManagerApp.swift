import SwiftUI

@main
struct PhotoManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("View") {
                Button("Sort by Date") {
                    NotificationCenter.default.post(name: .sortByDate, object: nil)
                }
                .keyboardShortcut("D", modifiers: [.command])
                
                Button("Sort by Size") {
                    NotificationCenter.default.post(name: .sortBySize, object: nil)
                }
                .keyboardShortcut("S", modifiers: [.command])
                
                Button("Find Similar Photos") {
                    NotificationCenter.default.post(name: .findSimilar, object: nil)
                }
                .keyboardShortcut("F", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let sortByDate = Notification.Name("sortByDate")
    static let sortBySize = Notification.Name("sortBySize")
    static let findSimilar = Notification.Name("findSimilar")
}
