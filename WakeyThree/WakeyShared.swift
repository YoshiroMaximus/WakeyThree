//
//  WakeyShared.swift
//  WakeyThree
//
//  Cross-platform pieces shared by the macOS and iOS UIs.
//

import SwiftUI
import SwiftData
import Observation

enum WakeyLinks {
    static let help = URL(string: "https://ieesizaq.com/wakeytoo/")!
}

/// Identifies what the add/edit sheet is presenting. Shared by every platform.
enum ServerEditorRoute: Identifiable {
    case add
    case edit(Server)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let server): return server.appEntityID.uuidString
        }
    }
}

/// Owns the add/edit form's state, validation, and persistence so the macOS and
/// iOS editors only have to describe their layout.
@Observable
final class ServerEditorModel {
    let server: Server?
    var name: String
    var macAddress: String

    init(server: Server?) {
        self.server = server
        self.name = server?.name ?? ""
        self.macAddress = server?.macAddress ?? ""
    }

    var title: String { server == nil ? "Add Server" : "Edit Server" }

    var canSave: Bool {
        WakeOnLAN.validate(name: name) && WakeOnLAN.validate(macAddress: macAddress)
    }

    var showNameError: Bool { !name.isEmpty && !WakeOnLAN.validate(name: name) }
    var showMacError: Bool { !macAddress.isEmpty && !WakeOnLAN.validate(macAddress: macAddress) }

    /// Updates the existing server in place, or inserts a new one.
    func save(into context: ModelContext) {
        guard WakeOnLAN.validate(name: name), WakeOnLAN.validate(macAddress: macAddress) else {
            Logger.shared.logWarning(message: "Invalid server, ignoring")
            return
        }

        if let server {
            server.name = name
            server.macAddress = macAddress
        } else {
            context.insert(Server(macAddress: macAddress, name: name))
        }

        try? context.save()
    }
}

/// The name + MAC address pair, styled consistently everywhere a server is listed.
struct ServerLabel: View {
    let server: Server

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(server.name)
                .font(.headline)
            Text(server.macAddress)
                .font(.callout)
                .monospaced()
                .foregroundStyle(.secondary)
        }
    }
}

/// Read-only, selectable log text used by the macOS popover and the iOS sheet.
struct LogTextView: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "No log messages." : text)
                .font(.callout)
                .monospaced()
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
