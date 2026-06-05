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
    var host: String
    var port: Int

    init(server: Server?) {
        self.server = server
        self.name = server?.name ?? ""
        self.macAddress = server?.macAddress ?? ""
        self.host = server?.host ?? ""
        self.port = server?.port ?? 9
    }

    var title: String { server == nil ? "Add Server" : "Edit Server" }

    var portIsValid: Bool { (1...65535).contains(port) }

    var canSave: Bool {
        WakeOnLAN.validate(name: name) && WakeOnLAN.validate(macAddress: macAddress) && portIsValid
    }

    var showNameError: Bool { !name.isEmpty && !WakeOnLAN.validate(name: name) }
    var showMacError: Bool { !macAddress.isEmpty && !WakeOnLAN.validate(macAddress: macAddress) }
    var showPortError: Bool { !portIsValid }

    /// Updates the existing server in place, or inserts a new one.
    func save(into context: ModelContext) {
        guard WakeOnLAN.validate(name: name), WakeOnLAN.validate(macAddress: macAddress), portIsValid else {
            Logger.shared.logWarning(message: "Invalid server, ignoring")
            return
        }

        let trimmedHost = host.trimmingCharacters(in: .whitespaces)
        let resolvedHost = trimmedHost.isEmpty ? nil : trimmedHost

        if let server {
            server.name = name
            server.macAddress = macAddress
            server.host = resolvedHost
            server.port = port
        } else {
            context.insert(Server(macAddress: macAddress, name: name, host: resolvedHost, port: port))
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
