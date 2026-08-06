import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var selectedTab: AppTab

    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
#if DEBUG
        let requestedTab = ProcessInfo.processInfo.environment["DOOMPEDIA_PREVIEW_TAB"]
        _selectedTab = State(initialValue: AppTab(rawValue: requestedTab ?? "") ?? .explore)
#else
        _selectedTab = State(initialValue: .explore)
#endif
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .explore:
            FeedView(viewModel: viewModel)
            case .saved:
            SavedView(viewModel: viewModel)
            case .packs:
            PacksView(viewModel: viewModel)
            case .settings:
            SettingsView(viewModel: viewModel)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            customTabBar
        }
        .sheet(item: Binding(
            get: { viewModel.folderPickerCard },
            set: { if $0 == nil { viewModel.dismissFolderPicker() } }
        )) { card in
            FolderPickerSheet(viewModel: viewModel, card: card)
        }
        .alert("Doompedia", isPresented: Binding(
            get: { viewModel.message != nil },
            set: { if !$0 { viewModel.message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.message ?? "")
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(.explore, title: "Explore", systemImage: "safari.fill")
            tabButton(.saved, title: "Saved", systemImage: "bookmark")
            tabButton(.packs, title: "Packs", systemImage: "tray.and.arrow.down")
            tabButton(.settings, title: "Settings", systemImage: "slider.horizontal.3")
        }
        .frame(maxWidth: .infinity)
        .background(DoompediaPalette.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(DoompediaPalette.line).frame(height: 1)
        }
    }

    private func tabButton(_ tab: AppTab, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            if isSelected, tab == .explore {
                viewModel.handleExploreReselected()
            }
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                Text(title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                Rectangle()
                    .fill(isSelected ? DoompediaPalette.coral : Color.clear)
                    .frame(width: 30, height: 3)
            }
            .foregroundStyle(isSelected ? DoompediaPalette.green : DoompediaPalette.ink)
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private enum AppTab: String, Hashable {
    case explore
    case saved
    case packs
    case settings
}
