//
//  AboutView.swift
//  WakeyThree
//
//  Custom "About" window shown from the app menu, replacing the default panel.
//

#if os(macOS)
import SwiftUI

struct AboutView: View {
    static let viewID = "about-view"

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            VStack(spacing: 3) {
                Text("WakeyThree")
                    .font(.title2.bold())
                Text(versionString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Text("A minimalist Wake-on-LAN utility. Wake computers on your local network with a single click.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Link("Help & Setup Guide", destination: WakeyLinks.help)
                .font(.callout)

            Divider()

            VStack(spacing: 2) {
                Text("Based on WakeyToo by echo · GPL-3.0")
                Text("© 2026 Nico Sendan")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(width: 320)
    }
}

/// Menu command that opens the custom About window. A dedicated view so it can
/// reach `openWindow` from the environment (not available directly in `App`).
struct AboutCommand: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("About WakeyThree") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: AboutView.viewID)
        }
    }
}

#Preview {
    AboutView()
}
#endif
