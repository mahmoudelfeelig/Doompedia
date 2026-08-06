import SwiftUI

struct SavedView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.openURL) private var openURL
    @State private var newFolderName = ""
    @State private var importDraft = ""

    private var selectedFolder: SaveFolderSummary? {
        viewModel.folders.first { $0.folderId == viewModel.selectedFolderID }
    }

    private var isReadFolder: Bool {
        selectedFolder?.folderId == WikiRepository.defaultReadFolderID
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    DoompediaMasthead(eyebrow: "The pocket encyclopedia edition", status: nil)
                    DoompediaScreenHeader(
                        eyebrow: "Your library",
                        title: "Saved",
                        summary: "Keep the articles worth returning to, arranged into small personal editions."
                    )

                    folderControls
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                    if isReadFolder {
                        readSorting
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                    }

                    EditorialSectionHeader(
                        title: selectedFolder?.name ?? "Saved",
                        caption: "\(viewModel.savedCards.count) articles"
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    if viewModel.savedCards.isEmpty {
                        EditorialEmptyState(
                            systemImage: isReadFolder ? "clock.arrow.circlepath" : "bookmark",
                            title: isReadFolder ? "No reading history yet" : "Nothing saved here yet",
                            message: isReadFolder
                                ? "Open an article from Explore and it will appear in your reading history."
                                : "Use the bookmark control while scrolling to add articles to this edition."
                        )
                        .padding(16)
                    } else {
                        ForEach(viewModel.savedCards) { card in
                            SavedArticleRow(
                                card: card,
                                showBookmarkAction: viewModel.selectedFolderID == WikiRepository.defaultBookmarksFolderID,
                                showFolderAction: !isReadFolder,
                                onOpen: { open(card) },
                                onBookmark: { Task { await viewModel.toggleBookmark(card) } },
                                onFolders: { Task { await viewModel.showFolderPicker(for: card) } }
                            )
                        }
                    }
                }
            }
            .background(DoompediaPalette.page)
            .refreshable { await viewModel.refreshSaved() }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var folderControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorialSectionHeader(title: "Editions", caption: "Organize your finds")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.folders) { folder in
                        folderButton(folder)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Name a new edition", text: $newFolderName)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(DoompediaPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(DoompediaPalette.line, lineWidth: 1)
                    )

                Button("Add") {
                    let current = newFolderName
                    newFolderName = ""
                    Task { await viewModel.createFolder(current) }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DoompediaPalette.surface)
                .frame(minWidth: 62, minHeight: 44)
                .background(DoompediaPalette.green)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Button("Copy this edition") { viewModel.exportSelectedFolderToClipboard() }
                            .buttonStyle(.bordered)
                        Button("Copy all") { viewModel.exportAllFoldersToClipboard() }
                            .buttonStyle(.bordered)
                    }

                    TextEditor(text: $importDraft)
                        .frame(minHeight: 90)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(6)
                        .background(DoompediaPalette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(DoompediaPalette.line, lineWidth: 1)
                        )

                    Button("Import editions") {
                        let payload = importDraft
                        importDraft = ""
                        Task { await viewModel.importFoldersJSON(payload) }
                    }
                    .disabled(importDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.top, 10)
            } label: {
                Label("Transfer editions", systemImage: "arrow.up.arrow.down.square")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)
            }

            if let selectedFolder, !selectedFolder.isDefault {
                Button(role: .destructive) {
                    Task { await viewModel.deleteFolder(selectedFolder.folderId) }
                } label: {
                    Label("Remove \(selectedFolder.name)", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
            }
        }
    }

    private var readSorting: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("READING ORDER")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(DoompediaPalette.coral)
            Picker("Reading order", selection: Binding(
                get: { viewModel.settings.readSort },
                set: { viewModel.setReadSort($0) }
            )) {
                Text("Newest first").tag(ReadSort.newestFirst)
                Text("Oldest first").tag(ReadSort.oldestFirst)
            }
            .pickerStyle(.segmented)
        }
    }

    private func folderButton(_ folder: SaveFolderSummary) -> some View {
        let isSelected = viewModel.selectedFolderID == folder.folderId
        return Button {
            Task { await viewModel.selectSavedFolder(folder.folderId) }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(folder.articleCount) articles")
                    .font(.caption2)
            }
            .foregroundStyle(isSelected ? DoompediaPalette.surface : DoompediaPalette.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
            .background(isSelected ? DoompediaPalette.green : DoompediaPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? DoompediaPalette.green : DoompediaPalette.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(folder.name), \(folder.articleCount) articles")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func open(_ card: ArticleCard) {
        Task {
            let shouldOpen = await viewModel.openCard(card)
            if shouldOpen, let url = URL(string: card.wikiURL) {
                openURL(url)
            }
        }
    }
}

private struct SavedArticleRow: View {
    let card: ArticleCard
    let showBookmarkAction: Bool
    let showFolderAction: Bool
    let onOpen: () -> Void
    let onBookmark: () -> Void
    let onFolders: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline) {
                Text(CardKeywords.prettyTopic(card.topicKey).uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(DoompediaPalette.green)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.subtle)
            }

            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(DoompediaPalette.coral)
                    .frame(width: 3)
                Text(card.title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(DoompediaPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(card.summary)
                .font(.subheadline)
                .foregroundStyle(DoompediaPalette.muted)
                .lineSpacing(3)
                .lineLimit(4)

            HStack(spacing: 10) {
                Button("Read", action: onOpen)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DoompediaPalette.green)
                    .frame(minHeight: 44)

                if showFolderAction {
                    EditorialIconButton(systemImage: "folder", label: "Choose editions", action: onFolders)
                }

                if showBookmarkAction {
                    EditorialIconButton(systemImage: "bookmark.slash", label: "Remove bookmark", action: onBookmark)
                }
            }
        }
        .padding(16)
        .background(DoompediaPalette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DoompediaPalette.line).frame(height: 1)
        }
        .contentShape(Rectangle())
    }
}

#Preview("Saved · Personal Editions") {
    SavedView(viewModel: MainViewModel.make())
}
