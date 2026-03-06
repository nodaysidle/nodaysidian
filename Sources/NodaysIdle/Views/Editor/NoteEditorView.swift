import SwiftUI
import CoreData

struct NoteEditorView: View {
    @ObservedObject var note: NoteEntity
    var vault: VaultViewModel

    @State private var editingTitle: String = ""
    @State private var editingContent: String = ""
    @State private var showMetadata: Bool = false
    @State private var autosaveTask: Task<Void, Never>?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool

    var body: some View {
        if note.isDeleted || note.managedObjectContext == nil {
            Color.clear
        } else {
        VStack(spacing: 0) {
            editorHeader
            Rectangle()
                .fill(LatticeTheme.border)
                .frame(height: 1)
            editorBody
            Rectangle()
                .fill(LatticeTheme.border)
                .frame(height: 1)
            editorFooter
        }
        .background(LatticeTheme.deepSpace)
        .onAppear {
            editingTitle   = note.title
            editingContent = note.content
        }
        .onDisappear {
            flushSave()
        }
        .onChange(of: note.id) { oldId, newId in
            // Cancel pending autosave — it would target the wrong note
            autosaveTask?.cancel()
            autosaveTask = nil
            // Save old editing buffers to the OLD note, not the new one
            if oldId != newId, let ctx = note.managedObjectContext {
                let req = NoteEntity.fetchRequest()
                req.predicate = NSPredicate(format: "id == %@", oldId as CVarArg)
                if let oldNote = try? ctx.fetch(req).first {
                    oldNote.title = editingTitle
                    oldNote.content = editingContent
                    oldNote.modifiedAt = Date()
                    do { try ctx.save() } catch {
                        print("[Nodaysidian] Failed to save old note on switch: \(error.localizedDescription)")
                    }
                }
            }
            // Now load the new note's data
            editingTitle   = note.title
            editingContent = note.content
        }
        } // else (not deleted)
    }

    // MARK: - Autosave (ID-pinned — immune to note reference swaps)

    /// Debounced save — waits 1.5s after last edit, then persists to disk.
    /// Captures the note ID at call time so it always targets the correct note.
    private func scheduleAutosave() {
        autosaveTask?.cancel()
        let pinnedId = note.id
        let pinnedCtx = note.managedObjectContext
        autosaveTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            saveToNote(id: pinnedId, context: pinnedCtx)
        }
    }

    /// Immediate save — used by Save button and view disappear.
    /// Captures the note ID at call time so it always targets the correct note.
    private func flushSave() {
        autosaveTask?.cancel()
        autosaveTask = nil
        guard !note.isDeleted, note.managedObjectContext != nil else { return }
        saveToNote(id: note.id, context: note.managedObjectContext)
    }

    /// Core save: fetches a specific note by its pinned UUID, writes buffers, persists.
    /// Never references `note` directly — completely safe across note switches.
    private func saveToNote(id: UUID, context: NSManagedObjectContext?) {
        guard let ctx = context else { return }
        let req = NoteEntity.fetchRequest()
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let target = try? ctx.fetch(req).first else { return }
        target.title = editingTitle
        target.content = editingContent
        target.modifiedAt = Date()
        do { try ctx.save() } catch {
            print("[Nodaysidian] Failed to autosave note: \(error.localizedDescription)")
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack(spacing: 12) {
            // Ripeness dot — flat solid, precisely sized
            Circle()
                .fill(LatticeTheme.ripenessColor(note.ripenessScore))
                .frame(width: 8, height: 8)

            TextField("Untitled", text: $editingTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 19, weight: .semibold, design: .default))
                .foregroundStyle(LatticeTheme.textPrimary)
                .focused($isTitleFocused)
                .onSubmit {
                    flushSave()
                    isContentFocused = true
                }
                .onChange(of: editingTitle) {
                    scheduleAutosave()
                }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    showMetadata.toggle()
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(showMetadata ? LatticeTheme.mint : LatticeTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Toggle Metadata")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
    }

    // MARK: - Body

    private var editorBody: some View {
        HStack(spacing: 0) {
            TextEditor(text: $editingContent)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(LatticeTheme.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isContentFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .onChange(of: editingContent) {
                    scheduleAutosave()
                }

            if showMetadata {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(LatticeTheme.border)
                        .frame(width: 1)
                    metadataPanel
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: - Metadata Panel

    private var metadataPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Panel heading
                Text("METADATA")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(2)
                    .foregroundStyle(LatticeTheme.textMuted)

                VStack(alignment: .leading, spacing: 14) {
                    metadataRow(label: "Created",
                                value: note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                    metadataRow(label: "Modified",
                                value: note.modifiedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—")
                    metadataRow(label: "Words",
                                value: "\(note.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)")
                    metadataRow(label: "Characters",
                                value: "\(note.content.count)")

                    if let path = note.sourcePath {
                        metadataRow(label: "Source", value: path)
                    }
                }

                // Ripeness section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ripeness")
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .tracking(2)
                            .foregroundStyle(LatticeTheme.textMuted)
                        Spacer()
                        Text(String(format: "%.0f%%", note.ripenessScore * 100))
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(LatticeTheme.ripenessColor(note.ripenessScore))
                    }
                    RipenessBar(score: note.ripenessScore)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(16)
        }
        .frame(width: 200)
        .background(LatticeTheme.nebula)
    }

    private func metadataRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9.5, weight: .semibold, design: .default))
                .tracking(1.5)
                .foregroundStyle(LatticeTheme.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(LatticeTheme.textSecondary)
                .lineLimit(2)
        }
    }

    // MARK: - Footer

    private var editorFooter: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(LatticeTheme.ripenessColor(note.ripenessScore))
                    .frame(width: 5, height: 5)
                Text(ripenessLabel)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundStyle(LatticeTheme.textMuted)
            }

            Spacer()

            Text("Markdown")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(LatticeTheme.textMuted)
                .padding(.trailing, 8)

            Button("Save") {
                flushSave()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium, design: .default))
            .foregroundStyle(LatticeTheme.mint)
            .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private var ripenessLabel: String {
        let s = note.ripenessScore
        if s < 0.30 { return "Seedling" }
        if s < 0.60 { return "Growing" }
        if s < 0.85 { return "Maturing" }
        return "Ripe"
    }
}

// MARK: - Ripeness Bar (flat solid, no gradient)

struct RipenessBar: View {
    let score: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LatticeTheme.surfaceRaised)
                    .frame(maxWidth: .infinity)

                // Fill — solid flat color matching the ripeness tier
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(LatticeTheme.ripenessColor(score))
                    .frame(width: geo.size.width * max(0, min(1, score)))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 4, maxHeight: 4)
    }
}
