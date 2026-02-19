import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var vault = VaultViewModel()
    @State private var graph = GraphViewModel()
    @State private var showGraph = true
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(vault: vault, graph: graph)
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            ZStack {
                LatticeTheme.void
                    .ignoresSafeArea()

                if showGraph {
                    GraphCanvasView(graph: graph, vault: vault)
                        .transition(.opacity)
                } else if let note = vault.selectedNote {
                    NoteEditorView(note: note, vault: vault)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    emptyState
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showGraph)
            .animation(.easeInOut(duration: 0.25), value: vault.selectedNote?.id)
        }
        .background(LatticeTheme.void)
        .toolbar {
            toolbarButtons
        }
        .onAppear {
            vault.bind(context: context)
            graph.bind(context: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            vault.createNote()
            showGraph = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .importVault)) { _ in
            vault.showImportPanel = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .intelligenceComplete)) { _ in
            vault.reload()
            graph.reload()
        }
        .fileImporter(
            isPresented: $vault.showImportPanel,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                vault.importVault(url: url)
                graph.reload()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Wordmark — large, ultra-light, wide tracked
                VStack(spacing: 10) {
                    Text("NODAYSIDLE")
                        .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(LatticeTheme.textPrimary)

                    Text("Your knowledge, always working.")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .tracking(0.2)
                        .foregroundStyle(LatticeTheme.textSecondary)
                }

                // Thin divider as a visual pause
                Rectangle()
                    .fill(LatticeTheme.border)
                    .frame(width: 40, height: 1)

                // Action buttons
                VStack(spacing: 10) {
                    actionButton(
                        icon: "plus",
                        title: "Create a Note",
                        color: LatticeTheme.mint
                    ) {
                        vault.createNote()
                        showGraph = false
                    }

                    actionButton(
                        icon: "arrow.down.to.line",
                        title: "Import Obsidian Vault",
                        color: LatticeTheme.lavender
                    ) {
                        vault.showImportPanel = true
                    }
                }
            }

            Spacer()

            // Quiet version tag at the bottom
            Text("Knowledge Graph")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(LatticeTheme.textMuted)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func actionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .default))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LatticeTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(LatticeTheme.border, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showGraph.toggle()
                }
            } label: {
                Image(systemName: showGraph ? "doc.text" : "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LatticeTheme.mint)
                    .contentTransition(.symbolEffect(.replace))
            }
            .help(showGraph ? "Show Editor" : "Show Graph")
        }

        ToolbarItem {
            Button {
                vault.createNote()
                showGraph = false
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LatticeTheme.mint)
            }
            .help("New Note")
        }
    }
}
