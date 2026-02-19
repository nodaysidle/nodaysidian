import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var note: NoteEntity
    var vault: VaultViewModel

    @State private var editingTitle: String = ""
    @State private var editingContent: String = ""
    @State private var showMetadata: Bool = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool

    var body: some View {
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
        .onChange(of: note.id) {
            editingTitle   = note.title
            editingContent = note.content
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
                    note.title = editingTitle
                    vault.saveNote()
                    isContentFocused = true
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
            ScrollView {
                TextEditor(text: $editingContent)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(LatticeTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isContentFocused)
                    .frame(minHeight: 400)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .onChange(of: editingContent) {
                        note.content   = editingContent
                        note.modifiedAt = Date()
                    }
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
                                value: "\(note.content.split(separator: " ").count)")
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
                note.title   = editingTitle
                note.content = editingContent
                vault.saveNote()
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
