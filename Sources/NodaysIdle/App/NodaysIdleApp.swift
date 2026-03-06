import SwiftUI
import AppKit

struct NodaysIdleApp: App {
    @State private var persistence = PersistenceController.shared
    private let autoEdge = AutoEdgeDiscovery()

    var body: some Scene {
        WindowGroup {
            Group {
                if persistence.loadError != nil {
                    storeErrorView
                } else {
                    MainView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                }
            }
            .preferredColorScheme(.dark)
            .task {
                guard persistence.loadError == nil else { return }
                await runIntelligenceCycle()
                NotificationCenter.default.post(name: .intelligenceComplete, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                persistence.save()
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

    private var storeErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(LatticeTheme.coral)

            Text("Unable to load data store")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(LatticeTheme.textPrimary)

            Text(persistence.loadError?.localizedDescription ?? "Unknown error")
                .font(.system(size: 13))
                .foregroundStyle(LatticeTheme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Text("Try restarting the app. If the problem persists, your data store may need to be reset.")
                .font(.system(size: 12))
                .foregroundStyle(LatticeTheme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LatticeTheme.void)
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
    static let openNoteInEditor = Notification.Name("openNoteInEditor")
}
