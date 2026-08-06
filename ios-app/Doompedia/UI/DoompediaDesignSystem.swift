import SwiftUI
import UIKit

enum DoompediaPalette {
    static let page = adaptive(light: 0xF4F6F2, dark: 0x101512)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x171D19)
    static let surfaceRaised = adaptive(light: 0xFFFFFF, dark: 0x1D2420)
    static let ink = adaptive(light: 0x17211B, dark: 0xF0F4F1)
    static let muted = adaptive(light: 0x647068, dark: 0xADB8B1)
    static let subtle = adaptive(light: 0x89938D, dark: 0x859089)
    static let line = adaptive(light: 0xDCE4DE, dark: 0x2D3731)
    static let green = adaptive(light: 0x0B624F, dark: 0x65C6A7)
    static let greenStrong = adaptive(light: 0x07483B, dark: 0x8AD9BD)
    static let greenSoft = adaptive(light: 0xDCEFE7, dark: 0x183B30)
    static let coral = adaptive(light: 0xC85B44, dark: 0xEF8A72)
    static let gold = adaptive(light: 0xB17D25, dark: 0xD6AA5B)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

struct DoompediaMasthead: View {
    let eyebrow: String
    let status: String?

    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                Image("elephant-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Doompedia")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(DoompediaPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(DoompediaPalette.muted)
                }

                Spacer(minLength: 8)

                if let status {
                    Label(status, systemImage: "circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DoompediaPalette.green)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                }
            }

            Rectangle()
                .fill(DoompediaPalette.coral)
                .frame(height: 3)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(DoompediaPalette.surface)
    }
}

struct DoompediaScreenHeader: View {
    let eyebrow: String
    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(DoompediaPalette.coral)
            Text(title)
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .foregroundStyle(DoompediaPalette.ink)
            Text(summary)
                .font(.body)
                .foregroundStyle(DoompediaPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(DoompediaPalette.line)
                .frame(height: 1)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
    }
}

struct EditorialSectionHeader: View {
    let title: String
    var caption: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Rectangle()
                .fill(DoompediaPalette.coral)
                .frame(width: 3, height: 20)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.subheadline.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(DoompediaPalette.ink)
            Spacer()
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(DoompediaPalette.muted)
            }
        }
        .frame(minHeight: 28)
    }
}

struct EditorialIconButton: View {
    let systemImage: String
    let label: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(isActive ? DoompediaPalette.greenStrong : DoompediaPalette.ink)
                .background(isActive ? DoompediaPalette.greenSoft : DoompediaPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isActive ? DoompediaPalette.green : DoompediaPalette.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct EditorialEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(DoompediaPalette.green)
            Text(title)
                .font(.system(.title2, design: .serif, weight: .bold))
                .foregroundStyle(DoompediaPalette.ink)
            Text(message)
                .font(.body)
                .foregroundStyle(DoompediaPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(DoompediaPalette.surface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(DoompediaPalette.coral)
                .frame(width: 3)
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
