import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var accentHexDraft = ""
    @State private var importDraft = ""

    private let presets = ["#0B624F", "#C85B44", "#B17D25", "#2C5F87", "#34453B"]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    DoompediaMasthead(eyebrow: "The pocket encyclopedia edition", status: nil)
                    DoompediaScreenHeader(
                        eyebrow: "Reading desk",
                        title: "Settings",
                        summary: "Tune the edition to your attention, accessibility needs, and connection."
                    )

                    VStack(alignment: .leading, spacing: 28) {
                        readingSection
                        personalizationSection
                        appearanceSection
                        accessibilitySection
                        downloadsSection
                        backupSection
                        attributionSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(DoompediaPalette.page)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if accentHexDraft.isEmpty {
                    accentHexDraft = viewModel.settings.accentHex
                }
            }
            .onChange(of: viewModel.settings.accentHex) { _, newValue in
                if accentHexDraft != newValue {
                    accentHexDraft = newValue
                }
            }
        }
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EditorialSectionHeader(title: "Reading mode")

            Picker("Feed mode", selection: Binding(
                get: { viewModel.settings.feedMode },
                set: { viewModel.setFeedMode($0) }
            )) {
                Text("Offline").tag(FeedMode.offline)
                Text("Online").tag(FeedMode.online)
            }
            .pickerStyle(.segmented)

            Label(
                readingModeDescription,
                systemImage: viewModel.effectiveFeedMode == .offline ? "internaldrive" : "network"
            )
            .font(.footnote)
            .foregroundStyle(DoompediaPalette.muted)

            if viewModel.effectiveFeedMode != viewModel.settings.feedMode {
                Label("No connection detected. The downloaded edition is active.", systemImage: "wifi.slash")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.coral)
            }
        }
    }

    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EditorialSectionHeader(title: "Personalization", caption: "You control the signal")

            Picker("Personalization level", selection: Binding(
                get: { viewModel.settings.personalizationLevel },
                set: { viewModel.setPersonalization($0) }
            )) {
                Text("Off").tag(PersonalizationLevel.off)
                Text("Low").tag(PersonalizationLevel.low)
                Text("Medium").tag(PersonalizationLevel.medium)
                Text("High").tag(PersonalizationLevel.high)
            }
            .pickerStyle(.segmented)

            Text(personalizationDescription(viewModel.settings.personalizationLevel))
                .font(.footnote)
                .foregroundStyle(DoompediaPalette.muted)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorialSectionHeader(title: "Appearance")

            Picker("Theme", selection: Binding(
                get: { viewModel.settings.themeMode },
                set: { viewModel.setTheme($0) }
            )) {
                Text("System").tag(ThemeMode.system)
                Text("Light").tag(ThemeMode.light)
                Text("Dark").tag(ThemeMode.dark)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 8) {
                Text("ACCENT")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(DoompediaPalette.subtle)

                HStack(spacing: 14) {
                    ForEach(presets, id: \.self) { hex in
                        Button {
                            accentHexDraft = hex
                            viewModel.setAccentHex(hex)
                        } label: {
                            Circle()
                                .fill(Color.fromHex(hex) ?? DoompediaPalette.green)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(
                                        accentHexDraft.caseInsensitiveCompare(hex) == .orderedSame
                                            ? DoompediaPalette.ink
                                            : DoompediaPalette.line,
                                        lineWidth: accentHexDraft.caseInsensitiveCompare(hex) == .orderedSame ? 3 : 1
                                    )
                                )
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use accent color \(hex)")
                    }

                    ColorPicker("Custom accent", selection: Binding(
                        get: { Color.fromHex(accentHexDraft) ?? DoompediaPalette.green },
                        set: { value in
                            if let hex = value.hexString {
                                accentHexDraft = hex
                                viewModel.setAccentHex(hex)
                            }
                        }
                    ))
                    .labelsHidden()
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Choose custom accent color")
                }
            }

            TextField("Accent hex (#RRGGBB)", text: Binding(
                get: { accentHexDraft },
                set: { value in
                    accentHexDraft = value
                    viewModel.setAccentHex(value)
                }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.system(.footnote, design: .monospaced))
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(DoompediaPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(DoompediaPalette.line, lineWidth: 1)
            )
        }
    }

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            EditorialSectionHeader(title: "Accessibility")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Text size")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DoompediaPalette.ink)
                    Text("Scales every article and control")
                        .font(.caption)
                        .foregroundStyle(DoompediaPalette.muted)
                }
                Spacer()
                Text("\(Int(viewModel.settings.fontScale * 100))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(DoompediaPalette.green)
            }

            Slider(
                value: Binding(
                    get: { viewModel.settings.fontScale },
                    set: { viewModel.setFontScale($0) }
                ),
                in: 0.85 ... 1.35
            )
            .tint(DoompediaPalette.green)
            .accessibilityLabel("Text size")

            settingsToggle(
                title: "High contrast",
                detail: "Adds weight and clarity to interface text.",
                isOn: Binding(
                    get: { viewModel.settings.highContrast },
                    set: { viewModel.setHighContrast($0) }
                )
            )

            settingsToggle(
                title: "Reduce motion",
                detail: "Removes animated scrolling and transitions.",
                isOn: Binding(
                    get: { viewModel.settings.reduceMotion },
                    set: { viewModel.setReduceMotion($0) }
                )
            )
        }
    }

    private var downloadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EditorialSectionHeader(title: "Downloads")
            settingsToggle(
                title: "Wi-Fi only",
                detail: "Avoid downloading large offline editions over cellular data.",
                isOn: Binding(
                    get: { viewModel.settings.wifiOnlyDownloads },
                    set: { viewModel.setWifiOnly($0) }
                )
            )
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            EditorialSectionHeader(title: "Backup")

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Copy settings as JSON") {
                        viewModel.exportSettingsToClipboard()
                    }
                    .font(.subheadline.weight(.semibold))

                    TextEditor(text: $importDraft)
                        .frame(minHeight: 110)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(6)
                        .background(DoompediaPalette.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(DoompediaPalette.line, lineWidth: 1)
                        )

                    Button("Import settings") {
                        Task { await viewModel.importSettingsJSON(importDraft) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .disabled(importDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.top, 10)
            } label: {
                Label("Transfer settings", systemImage: "curlybraces.square")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)
                    .frame(minHeight: 44)
            }
        }
    }

    private var attributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            EditorialSectionHeader(title: "Sources & attribution")
            Text("Doompedia uses Wikipedia content under the Creative Commons Attribution-ShareAlike 4.0 license.")
                .font(.footnote)
                .foregroundStyle(DoompediaPalette.muted)
            Link("Read the CC BY-SA 4.0 license", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
                .font(.subheadline.weight(.semibold))
            Link("Visit Wikipedia", destination: URL(string: "https://www.wikipedia.org/")!)
                .font(.subheadline.weight(.semibold))
        }
    }

    private var readingModeDescription: String {
        viewModel.settings.feedMode == .offline
            ? "The feed uses downloaded packs and the local cache only."
            : "The feed fetches live Wikipedia summaries and keeps a local cache."
    }

    private func settingsToggle(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DoompediaPalette.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DoompediaPalette.muted)
            }
        }
        .tint(DoompediaPalette.green)
        .padding(.vertical, 3)
    }
}

private func personalizationDescription(_ level: PersonalizationLevel) -> String {
    switch level {
    case .off:
        return "No behavior-based tuning. The edition stays broadly neutral."
    case .low:
        return "A light signal with strong variety and exploration guardrails."
    case .medium:
        return "A balanced mix of your interests and unfamiliar subjects."
    case .high:
        return "Stronger adaptation while still keeping anti-bubble constraints."
    }
}

private extension Color {
    static func fromHex(_ hex: String) -> Color? {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 || cleaned.count == 8,
              let value = UInt64(cleaned, radix: 16) else {
            return nil
        }

        let r, g, b, a: Double
        if cleaned.count == 8 {
            r = Double((value & 0xFF00_0000) >> 24) / 255.0
            g = Double((value & 0x00FF_0000) >> 16) / 255.0
            b = Double((value & 0x0000_FF00) >> 8) / 255.0
            a = Double(value & 0x0000_00FF) / 255.0
        } else {
            r = Double((value & 0xFF00_00) >> 16) / 255.0
            g = Double((value & 0x00FF_00) >> 8) / 255.0
            b = Double(value & 0x0000_FF) / 255.0
            a = 1.0
        }
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    var hexString: String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255.0),
            Int(green * 255.0),
            Int(blue * 255.0)
        )
    }
}

#Preview("Settings · Reading Desk") {
    SettingsView(viewModel: MainViewModel.make())
}
