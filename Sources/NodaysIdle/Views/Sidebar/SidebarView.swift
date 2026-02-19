import SwiftUI

struct SidebarView: View {
    @Bindable var vault: VaultViewModel
    @Bindable var graph: GraphViewModel
    @Bindable var whiteboard: WhiteboardViewModel
    var onSelectCanvas: ((CanvasEntity) -> Void)?

    @State private var hoverNoteId: UUID?
    @State private var hoverCanvasId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            noteList
            canvasSection
            sidebarFooter
        }
        .background(LatticeTheme.deepSpace)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                // Logotype — wide tracked, semibold, small caps feel
                Text("NODAYSIDLE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3.5)
                    .foregroundStyle(LatticeTheme.textPrimary)

                // Note count — monospaced for the number, muted label
                HStack(spacing: 3) {
                    Text("\(vault.notes.count)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(LatticeTheme.textSecondary)
                    Text("notes")
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(LatticeTheme.textMuted)
                }
            }

            Spacer()

            // New note button — plain icon, mint accent
            Button {
                vault.createNote()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LatticeTheme.mint)
                    .frame(width: 28, height: 28)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LatticeTheme.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(LatticeTheme.border, lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .help("New Note")
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LatticeTheme.textMuted)

            TextField("Search", text: $vault.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, weight: .regular, design: .default))
                .foregroundStyle(LatticeTheme.textPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LatticeTheme.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(LatticeTheme.border, lineWidth: 1)
                }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Note List

    private var noteList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(vault.filteredNotes, id: \.id) { note in
                    NoteListItem(
                        note: note,
                        isSelected: vault.selectedNote?.id == note.id,
                        isHovered: hoverNoteId == note.id
                    )
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) {
                            vault.selectedNote = note
                            graph.selectNode(note.id)
                        }
                    }
                    .onHover { hover in
                        hoverNoteId = hover ? note.id : nil
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            vault.deleteNote(note)
                            graph.reload()
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Canvas Section

    private var canvasSection: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(LatticeTheme.border)
                .frame(height: 1)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            // Section header
            HStack {
                Text("CANVASES")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(LatticeTheme.textMuted)

                Spacer()

                // Canvas count
                Text("\(whiteboard.canvases.count)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(LatticeTheme.textMuted)

                // New canvas button
                Button {
                    whiteboard.createCanvas()
                    if let canvas = whiteboard.canvases.first {
                        onSelectCanvas?(canvas)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LatticeTheme.lavender)
                        .frame(width: 22, height: 22)
                        .background {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(LatticeTheme.surface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(LatticeTheme.border, lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .help("New Canvas")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Canvas list
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(whiteboard.canvases, id: \.id) { canvas in
                        CanvasListItem(
                            canvas: canvas,
                            isSelected: whiteboard.selectedCanvas?.id == canvas.id,
                            isHovered: hoverCanvasId == canvas.id
                        )
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.18)) {
                                whiteboard.selectCanvas(canvas)
                                onSelectCanvas?(canvas)
                            }
                        }
                        .onHover { hover in
                            hoverCanvasId = hover ? canvas.id : nil
                        }
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                whiteboard.deleteCanvas(canvas)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LatticeTheme.border)
                .frame(height: 1)

            VStack(spacing: 8) {
                if let msg = vault.importMessage {
                    Text(msg)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundStyle(LatticeTheme.textSecondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                }

                Button {
                    vault.showImportPanel = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 10, weight: .medium))
                        Text("Import Vault")
                            .font(.system(size: 11, weight: .medium, design: .default))
                    }
                    .foregroundStyle(LatticeTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LatticeTheme.surface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(LatticeTheme.border, lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 8)
            }
        }
    }
}
