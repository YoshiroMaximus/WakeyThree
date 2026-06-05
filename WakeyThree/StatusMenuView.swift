//
//  StatusMenuView.swift
//  WakeyThree
//

#if os(macOS)
import SwiftUI
import SwiftData

struct StatusMenuView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.lastUsed, order: .reverse) private var servers: [Server]

    var body: some View {

        ForEach(servers) { server in
            Button {
                Task {
                    let result = await WakeOnLAN.wakeServer(server)
                    WakeNotifier.report(result, serverName: server.name)
                }
            } label: {
                HStack {
                    Text("\(server.name)")
                }
            }
        }

        Divider()
        Button("Settings...") {

            // Focus existing window, the new version does not work reliably on macOS Sequoia
            NSApp.activate()
            NSApplication.shared.activate(ignoringOtherApps: true)

            // Prevent opening extra settings windows
            if !NSApplication.shared.windows.contains(where: { $0.title == SettingsView.titleString}) {
                openWindow(id: SettingsView.viewID)
            }
        }

        Link("Help", destination: WakeyLinks.help)
        Button("About WakeyThree") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: AboutView.viewID)
        }
        Divider()
        Button("Quit WakeyThree") {
            NSApplication.shared.terminate(nil)
        }
    }
}

#Preview {
    StatusMenuView()
        .modelContainer(for: Server.self, inMemory: true)
}
#endif
