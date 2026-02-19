import SwiftUI

struct NodaysIdleApp: App {
    @State private var persistence = PersistenceController.shared
    private let autoEdge = AutoEdgeDiscovery()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .preferredColorScheme(.dark)
                .task {
                    await runIntelligenceCycle()
                }
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1400, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .createNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Canvas") {
                    NotificationCenter.default.post(name: .createNewCanvas, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Divider()

                Button("Import Obsidian Vault...") {
                    NotificationCenter.default.post(name: .importVault, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }

            CommandGroup(after: .toolbar) {
                Button("Run Intelligence Scan") {
                    Task {
                        await runIntelligenceCycle()
                        NotificationCenter.default.post(name: .intelligenceComplete, object: nil)
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }

    private func runIntelligenceCycle() async {
        let ctx = persistence.container.viewContext
        RipenessEngine.computeRipeness(context: ctx)
        await autoEdge.discoverEdges(context: ctx)
    }
}

extension Notification.Name {
    static let createNewNote = Notification.Name("createNewNote")
    static let importVault = Notification.Name("importVault")
    static let intelligenceComplete = Notification.Name("intelligenceComplete")
    static let createNewCanvas = Notification.Name("createNewCanvas")
}
