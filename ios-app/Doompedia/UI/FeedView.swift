import SwiftUI

private enum FeedSortOption: String, CaseIterable {
    case recommended = "For you"
    case titleAsc = "A–Z"
    case titleDesc = "Z–A"
}

struct FeedView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.openURL) private var openURL

    @State private var whyMessage = ""
    @State private var showWhyAlert = false
    @State private var selectedSort: FeedSortOption = .recommended
    @State private var selectedFilter = "All"
    @State private var didInitialRefresh = false
    @State private var isAtTop = true

    private var items: [RankedCard] {
        if viewModel.query.isEmpty {
            return viewModel.feed
        }
        return viewModel.searchResults.map { card in
            RankedCard(card: card, score: 0, why: "Search match by title or alias")
        }
    }

    private var availableFilters: [String] {
        Array(Set(items.map { editorialTopic(for: $0.card) })).sorted()
    }

    private var visibleItems: [RankedCard] {
        var filtered = items
        if selectedFilter != "All" {
            filtered = filtered.filter { editorialTopic(for: $0.card) == selectedFilter }
        }

        switch selectedSort {
        case .recommended:
            return filtered
        case .titleAsc:
            return filtered.sorted { $0.card.title.localizedCaseInsensitiveCompare($1.card.title) == .orderedAscending }
        case .titleDesc:
            return filtered.sorted { $0.card.title.localizedCaseInsensitiveCompare($1.card.title) == .orderedDescending }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        DoompediaMasthead(
                            eyebrow: "The pocket encyclopedia edition",
                            status: viewModel.effectiveFeedMode == .offline ? "Offline" : "Live"
                        )
                        .id("feed-top")
                        .onAppear { isAtTop = true }
                        .onDisappear { isAtTop = false }

                        Section {
                            feedContent
                        } header: {
                            feedControls
                        }
                    }
                }
                .background(DoompediaPalette.page)
                .refreshable {
                    await viewModel.refreshFeed(manual: true)
                }
                .onChange(of: viewModel.exploreReselectToken) { _, _ in
                    if isAtTop {
                        Task { await viewModel.refreshFeed(manual: true) }
                    } else if viewModel.settings.reduceMotion {
                        proxy.scrollTo("feed-top", anchor: .top)
                    } else {
                        withAnimation(.easeOut(duration: 0.28)) {
                            proxy.scrollTo("feed-top", anchor: .top)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                guard !didInitialRefresh else { return }
                didInitialRefresh = true
                if viewModel.feed.isEmpty, viewModel.query.isEmpty {
                    Task { await viewModel.refreshFeed() }
                }
            }
            .alert("Why this is shown", isPresented: $showWhyAlert) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text(whyMessage)
            }
        }
    }

    private var feedControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(DoompediaPalette.subtle)

                TextField("Search articles", text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.updateQuery($0) }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Search articles by title")

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.updateQuery("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(DoompediaPalette.subtle)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 7)
            .frame(minHeight: 46)
            .background(DoompediaPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(DoompediaPalette.line, lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    topicButton(title: "For you", filter: "All")
                    ForEach(availableFilters, id: \.self) { filter in
                        topicButton(title: filter, filter: filter)
                    }
                }
            }

            HStack {
                Text(viewModel.query.isEmpty ? "THE ENDLESS EDITION" : "SEARCH RESULTS")
                    .font(.caption.weight(.bold))
                    .tracking(1.25)
                    .foregroundStyle(DoompediaPalette.coral)

                Spacer()

                Text("\(visibleItems.count) articles")
                    .font(.caption)
                    .foregroundStyle(DoompediaPalette.muted)

                Menu {
                    ForEach(FeedSortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) { selectedSort = option }
                    }
                } label: {
                    Label(selectedSort.rawValue, systemImage: "arrow.up.arrow.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DoompediaPalette.ink)
                        .frame(minHeight: 32)
                }
            }

            Rectangle()
                .fill(DoompediaPalette.line)
                .frame(height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(DoompediaPalette.page)
    }

    @ViewBuilder
    private var feedContent: some View {
        if viewModel.isLoading, visibleItems.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(DoompediaPalette.green)
                Text("Preparing your edition…")
                    .font(.subheadline)
                    .foregroundStyle(DoompediaPalette.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 70)
        } else if visibleItems.isEmpty {
            EditorialEmptyState(
                systemImage: "text.magnifyingglass",
                title: "No articles found",
                message: "Try another title or return to the full edition."
            )
            .padding(16)
        } else {
            ForEach(Array(visibleItems.enumerated()), id: \.offset) { index, ranked in
                EditorialArticleView(
                    ranked: ranked,
                    editionNumber: index + 1,
                    viewModel: viewModel,
                    onOpen: { open(ranked.card) },
                    onWhy: {
                        whyMessage = """
                        This article is placed using your personalization level, diversity guardrails, and controlled exploration.

                        \(ranked.why)
                        """
                        showWhyAlert = true
                    }
                )
                .onAppear {
                    if index >= visibleItems.count - 6 {
                        Task { await viewModel.loadMoreFeed() }
                    }
                }
            }

            if viewModel.isLoadingMoreFeed {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Printing the next page…")
                        .font(.subheadline)
                        .foregroundStyle(DoompediaPalette.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    private func topicButton(title: String, filter: String) -> some View {
        let isSelected = selectedFilter == filter
        return Button {
            selectedFilter = filter
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? DoompediaPalette.surface : DoompediaPalette.muted)
                .padding(.horizontal, 13)
                .frame(minHeight: 36)
                .background(isSelected ? DoompediaPalette.green : DoompediaPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isSelected ? DoompediaPalette.green : DoompediaPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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

private struct EditorialArticleView: View {
    let ranked: RankedCard
    let editionNumber: Int
    @ObservedObject var viewModel: MainViewModel
    let onOpen: () -> Void
    let onWhy: () -> Void

    private var card: ArticleCard { ranked.card }
    private var topic: String { editorialTopic(for: card) }
    private var provenance: String {
        card.updatedAt.hasPrefix("1970-") ? "AVAILABLE OFFLINE" : "LIVE CACHE"
    }

    var body: some View {
        VStack(spacing: 0) {
            ArticleMedia(card: card, viewModel: viewModel)
                .overlay(alignment: .bottomTrailing) {
                    Text(topic.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.7)
                        .foregroundStyle(Color(red: 0.09, green: 0.19, blue: 0.15))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ARTICLE \(String(format: "%02d", editionNumber))")
                    Spacer()
                    Text(provenance)
                }
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(DoompediaPalette.green)

                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(DoompediaPalette.coral)
                        .frame(width: 3)

                    Text(card.title)
                        .font(.system(size: 31, weight: .bold, design: .serif))
                        .foregroundStyle(DoompediaPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(card.summary)
                    .font(.system(.body, design: .default))
                    .foregroundStyle(DoompediaPalette.muted)
                    .lineSpacing(4)
                    .lineLimit(5)

                Button(action: onOpen) {
                    HStack(spacing: 7) {
                        Text("READ ON WIKIPEDIA")
                        Image(systemName: "arrow.right")
                    }
                    .font(.caption.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(DoompediaPalette.green)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    EditorialIconButton(
                        systemImage: card.bookmarked ? "bookmark.fill" : "bookmark",
                        label: card.bookmarked ? "Saved to folders" : "Save to folders",
                        isActive: card.bookmarked
                    ) {
                        Task { await viewModel.showFolderPicker(for: card) }
                    }

                    EditorialIconButton(
                        systemImage: "hand.thumbsup",
                        label: "Show more articles like this"
                    ) {
                        Task { await viewModel.moreLike(card) }
                    }

                    EditorialIconButton(
                        systemImage: "hand.thumbsdown",
                        label: "Show fewer articles like this"
                    ) {
                        Task { await viewModel.lessLike(card) }
                    }

                    EditorialIconButton(
                        systemImage: "info.circle",
                        label: "Why this article is shown",
                        action: onWhy
                    )

                    Spacer()

                    Text(topic.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(DoompediaPalette.subtle)
                        .lineLimit(1)
                }
            }
            .padding(16)
        }
        .background(DoompediaPalette.surface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DoompediaPalette.line)
                .frame(height: 10)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(DoompediaPalette.line)
                        .frame(height: 1)
                }
        }
        .accessibilityElement(children: .contain)
    }
}

struct FolderPickerSheet: View {
    @ObservedObject var viewModel: MainViewModel
    let card: ArticleCard

    var body: some View {
        NavigationStack {
            List(viewModel.folders.filter { $0.folderId != WikiRepository.defaultReadFolderID }) { folder in
                Button {
                    viewModel.toggleFolderInPicker(folder.folderId)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder")
                            .foregroundStyle(DoompediaPalette.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folder.name)
                                .foregroundStyle(DoompediaPalette.ink)
                            Text("\(folder.articleCount) articles")
                                .font(.caption)
                                .foregroundStyle(DoompediaPalette.muted)
                        }
                        Spacer()
                        if viewModel.folderPickerSelection.contains(folder.folderId) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DoompediaPalette.green)
                        }
                    }
                    .frame(minHeight: 48)
                }
                .buttonStyle(.plain)
                .listRowBackground(DoompediaPalette.surface)
            }
            .scrollContentBackground(.hidden)
            .background(DoompediaPalette.page)
            .navigationTitle("Save \(card.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { viewModel.dismissFolderPicker() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        Task { await viewModel.applyFolderPicker() }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct ArticleMedia: View {
    let card: ArticleCard
    @ObservedObject var viewModel: MainViewModel
    @State private var imageURL: String?
    @State private var didResolve = false

    var body: some View {
        ZStack {
            DoompediaPalette.greenSoft

            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        brandedPlaceholder(showProgress: true)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        brandedPlaceholder(showProgress: false)
                    @unknown default:
                        brandedPlaceholder(showProgress: false)
                    }
                }
            } else {
                brandedPlaceholder(showProgress: viewModel.settings.downloadPreviewImages && !didResolve)
            }
        }
        .aspectRatio(4 / 5, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .task(id: "\(card.pageId)-\(viewModel.settings.downloadPreviewImages)") {
            didResolve = false
            imageURL = await viewModel.resolveThumbnailURL(for: card)
            didResolve = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview image for \(card.title)")
    }

    private func brandedPlaceholder(showProgress: Bool) -> some View {
        VStack(spacing: 18) {
            Image("elephant-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .opacity(0.72)
            if showProgress {
                ProgressView()
                    .tint(DoompediaPalette.green)
            } else {
                Text(editorialTopic(for: card).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(DoompediaPalette.greenStrong)
            }
        }
    }
}

private func editorialTopic(for card: ArticleCard) -> String {
    CardKeywords.prettyTopic(card.topicKey)
}

#Preview("Explore · Doomscroll Edition") {
    FeedView(viewModel: MainViewModel.make())
}
