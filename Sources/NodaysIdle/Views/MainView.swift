import SwiftUI
import CoreData

enum ViewMode {
    case graph
    case editor
    case whiteboard
}

struct MainView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var vault = VaultViewModel()
    @State private var graph = GraphViewModel()
    @State private var whiteboard = WhiteboardViewModel()
    @State private var viewMode: ViewMode = .graph
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(vault: vault, graph: graph, whiteboard: whiteboard, onSelectCanvas: { canvas in
                whiteboard.selectCanvas(canvas)
                viewMode = .whiteboard
            })
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
        } detail: {
            ZStack {
                LatticeTheme.void
                    .ignoresSafeArea()

                switch viewMode {
                case .graph:
                    GraphCanvasView(graph: graph, vault: vault)
                        .transition(.opacity)
                case .editor:
                    if let note = vault.selectedNote {
                        NoteEditorView(note: note, vault: vault)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        emptyState
                    }
                case .whiteboard:
                    if whiteboard.selectedCanvas != nil {
                        WhiteboardView(whiteboard: whiteboard)
                            .transition(.opacity)
                    } else {
                        canvasEmptyState
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewMode)
            .animation(.easeInOut(duration: 0.25), value: vault.selectedNote?.id)
        }
        .background(LatticeTheme.void)
        .toolbar {
            toolbarButtons
        }
        .onAppear {
            vault.bind(context: context)
            graph.bind(context: context)
            whiteboard.bind(context: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewNote)) { _ in
            vault.createNote()
            graph.reload()
            viewMode = .editor
        }
        .onReceive(NotificationCenter.default.publisher(for: .importVault)) { _ in
            vault.showImportPanel = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .intelligenceComplete)) { _ in
            vault.reload()
            graph.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewCanvas)) { _ in
            if let canvas = whiteboard.createCanvas() {
                whiteboard.selectCanvas(canvas)
            }
            viewMode = .whiteboard
        }
        .onReceive(NotificationCenter.default.publisher(for: .openNoteInEditor)) { _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewMode = .editor
            }
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
        .confirmationDialog(
            "Delete Note",
            isPresented: $vault.showDeleteConfirmation,
            presenting: vault.noteToDelete
        ) { note in
            Button("Delete", role: .destructive) {
                vault.deleteNote(note)
                graph.reload()
            }
            Button("Cancel", role: .cancel) {}
        } message: { note in
            Text("Are you sure you want to delete \"\(note.displayTitle)\"? This will also remove all its edges.")
        }
        .onChange(of: viewMode) { _, newMode in
            if newMode == .graph {
                graph.reload()
            }
        }
        .onChange(of: vault.selectedNote?.id) { _, newValue in
            if newValue != nil && viewMode != .whiteboard {
                viewMode = .editor
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
                    Text("NODAYSIDIAN")
                        .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                        .tracking(14)
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
                        viewMode = .editor
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

    // MARK: - Canvas Empty State

    private var canvasEmptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                VStack(spacing: 10) {
                    Text("WHITEBOARD")
                        .font(.system(size: 36, weight: .ultraLight, design: .rounded))
                        .tracking(10)
                        .foregroundStyle(LatticeTheme.textPrimary)
                    Text("Sketch, diagram, think visually.")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .tracking(0.2)
                        .foregroundStyle(LatticeTheme.textSecondary)
                }
                Rectangle()
                    .fill(LatticeTheme.border)
                    .frame(width: 40, height: 1)
                actionButton(
                    icon: "plus",
                    title: "Create a Canvas",
                    color: LatticeTheme.lavender
                ) {
                    if let canvas = whiteboard.createCanvas() {
                        whiteboard.selectCanvas(canvas)
                    }
                }
            }
            Spacer()
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

    // MARK: - Toolbar (with active-state pill)

    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItem {
            HStack(spacing: 2) {
                modeButton(mode: .graph, icon: "point.3.connected.trianglepath.dotted", label: "Graph")
                modeButton(mode: .editor, icon: "doc.text", label: "Editor")
                modeButton(mode: .whiteboard, icon: "square.on.square", label: "Whiteboard")
            }
            .padding(2)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(LatticeTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(LatticeTheme.border, lineWidth: 1)
                    }
            }
        }

        ToolbarItem {
            Button {
                vault.createNote()
                graph.reload()
                viewMode = .editor
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LatticeTheme.mint)
            }
            .help("New Note")
            .accessibilityLabel("New Note")
        }
    }

    private func modeButton(mode: ViewMode, icon: String, label: String) -> some View {
        let isActive = viewMode == mode
        let accentColor = mode == .whiteboard ? LatticeTheme.lavender : LatticeTheme.mint

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                viewMode = mode
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? accentColor : LatticeTheme.textMuted)
                .frame(width: 28, height: 24)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(accentColor.opacity(0.15))
                    }
                }
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}
