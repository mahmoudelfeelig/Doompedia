import SwiftUI

struct PacksView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var manifestURLDraft = ""
    @State private var addManifestURLDraft = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    DoompediaMasthead(eyebrow: "The pocket encyclopedia edition", status: nil)
                    DoompediaScreenHeader(
                        eyebrow: "Offline library",
                        title: "Packs",
                        summary: "Choose how much of Wikipedia travels with you. Start small, then expand when you need more range."
                    )

                    VStack(alignment: .leading, spacing: 18) {
                        EditorialSectionHeader(title: "Choose an edition", caption: "From 17K to 6.3M articles")

                        ForEach(viewModel.packCatalog) { pack in
                            PackEditionRow(
                                pack: pack,
                                isSelected: viewModel.settings.manifestURL == pack.manifestURL,
                                isUpdating: viewModel.isUpdatingPack,
                                onSelect: { viewModel.choosePack(pack) },
                                onRemove: { viewModel.removePack(pack) }
                            )
                        }

                        updateControls

                        advancedControls

                        Text("Pack indexes are downloaded from doompedia.elfeel.me. Full articles still open on Wikipedia when you are online.")
                            .font(.footnote)
                            .foregroundStyle(DoompediaPalette.muted)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(DoompediaPalette.page)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if manifestURLDraft.isEmpty {
                    manifestURLDraft = viewModel.settings.manifestURL
                }
            }
            .onChange(of: viewModel.settings.manifestURL) { _, newValue in
                if manifestURLDraft != newValue {
                    manifestURLDraft = newValue
                }
            }
        }
    }

    private var updateControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorialSectionHeader(title: "Download", caption: installedVersionLabel)

            Toggle("Article preview images", isOn: Binding(
                get: { viewModel.settings.downloadPreviewImages },
                set: { viewModel.setDownloadPreviewImages($0) }
            ))
            .tint(DoompediaPalette.green)

            Text("Preview images make the feed more visual and load only when needed.")
                .font(.footnote)
                .foregroundStyle(DoompediaPalette.muted)

            Button {
                Task { await viewModel.checkForUpdatesNow() }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle")
                    Text(viewModel.isUpdatingPack ? "Checking edition…" : "Download or update selected edition")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DoompediaPalette.surface)
                .padding(.horizontal, 14)
                .frame(minHeight: 50)
                .background(DoompediaPalette.green)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUpdatingPack || viewModel.settings.manifestURL.isEmpty)

            if let progress = viewModel.updateProgress {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(progress.phase) \(progress.detail)".trimmingCharacters(in: .whitespaces))
                        Spacer()
                        Text(String(format: "%.1f%%", progress.percent))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)

                    ProgressView(value: progress.percent / 100.0)
                        .tint(DoompediaPalette.green)

                    Text(progressBytesText(progress))
                        .font(.caption)
                        .foregroundStyle(DoompediaPalette.muted)
                }
                .padding(.vertical, 4)
            }

            if !viewModel.settings.lastUpdateStatus.isEmpty {
                Label(viewModel.settings.lastUpdateStatus, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(DoompediaPalette.muted)
            }

            if !viewModel.settings.lastUpdateISO.isEmpty {
                Text("Last checked \(friendlyUpdateDate(viewModel.settings.lastUpdateISO))")
                    .font(.caption)
                    .foregroundStyle(DoompediaPalette.subtle)
            }

            Rectangle().fill(DoompediaPalette.line).frame(height: 1)
        }
    }

    private var advancedControls: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("Add a compatible pack manifest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)

                TextField("https://…/manifest.json", text: $addManifestURLDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(DoompediaPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(DoompediaPalette.line, lineWidth: 1)
                    )

                Button("Add manifest") {
                    let value = addManifestURLDraft
                    addManifestURLDraft = ""
                    Task { await viewModel.addPackByManifestURL(value) }
                }
                .font(.subheadline.weight(.semibold))
                .disabled(addManifestURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isUpdatingPack)

                Text("Current manifest URL")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)

                TextField("Manifest URL", text: Binding(
                    get: { manifestURLDraft },
                    set: { value in
                        manifestURLDraft = value
                        viewModel.setManifestURL(value)
                    }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .font(.footnote)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(DoompediaPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(DoompediaPalette.line, lineWidth: 1)
                )
            }
            .padding(.top, 12)
        } label: {
            Label("Advanced pack sources", systemImage: "link")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DoompediaPalette.ink)
                .frame(minHeight: 44)
        }
    }

    private var installedVersionLabel: String {
        viewModel.settings.installedPackVersion == 0
            ? "No update installed"
            : "Version \(viewModel.settings.installedPackVersion) installed"
    }

    private func progressBytesText(_ progress: PackUpdateProgress) -> String {
        let bytesText = progress.totalBytes > 0
            ? "\(formatBytes(progress.downloadedBytes)) / \(formatBytes(progress.totalBytes))"
            : formatBytes(progress.downloadedBytes)
        let speedText = progress.bytesPerSecond > 0 ? " · \(formatBytes(progress.bytesPerSecond))/s" : ""
        return bytesText + speedText
    }
}

private struct PackEditionRow: View {
    let pack: PackOption
    let isSelected: Bool
    let isUpdating: Bool
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.title)
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(DoompediaPalette.ink)
                    Text(pack.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DoompediaPalette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? DoompediaPalette.green : DoompediaPalette.subtle)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 16) {
                packFact(value: pack.articleCount.formatted(), label: "ARTICLES")
                packFact(value: pack.downloadSize, label: "DOWNLOAD")
                packFact(value: "\(pack.shardCount)", label: "PARTS")
            }

            if !pack.includedTopics.isEmpty {
                Text(pack.includedTopics.prefix(8).joined(separator: "  ·  "))
                    .font(.caption)
                    .foregroundStyle(DoompediaPalette.muted)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Button(isSelected ? "Selected" : (pack.available ? "Use this edition" : "Coming soon"), action: onSelect)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? DoompediaPalette.muted : DoompediaPalette.green)
                    .frame(minHeight: 44)
                    .disabled(!pack.available || pack.manifestURL.isEmpty || isSelected)

                if pack.removable {
                    Button("Remove", role: .destructive, action: onRemove)
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                        .disabled(isUpdating)
                }
            }
        }
        .padding(.vertical, 16)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelected ? DoompediaPalette.coral : DoompediaPalette.line)
                .frame(width: isSelected ? 3 : 1)
        }
        .padding(.leading, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DoompediaPalette.line).frame(height: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func packFact(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DoompediaPalette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2.weight(.bold))
                .tracking(0.7)
                .foregroundStyle(DoompediaPalette.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func friendlyUpdateDate(_ iso: String) -> String {
    guard let date = ISO8601DateFormatter().date(from: iso) else { return iso }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func formatBytes(_ bytes: Int64) -> String {
    if bytes <= 0 { return "0 B" }
    let kb = Double(bytes) / 1024.0
    if kb < 1024.0 { return String(format: "%.0f KB", kb) }
    let mb = kb / 1024.0
    if mb < 1024.0 { return String(format: "%.1f MB", mb) }
    return String(format: "%.2f GB", mb / 1024.0)
}

#Preview("Packs · Offline Editions") {
    PacksView(viewModel: MainViewModel.make())
}
