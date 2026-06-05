//
//  WakeIntents.swift
//  WakeyThree
//
//  App Intents so a server can be woken from Siri, Spotlight, and the Shortcuts
//  app. Builds on the existing appEntityID / fetch helpers in WakeyDataStore.
//

import AppIntents
import Foundation

/// A saved server, exposed to the App Intents system.
struct ServerEntity: AppEntity {
    let id: UUID
    let name: String
    let macAddress: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Server" }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(macAddress)")
    }

    static var defaultQuery = ServerEntityQuery()

    init(id: UUID, name: String, macAddress: String) {
        self.id = id
        self.name = name
        self.macAddress = macAddress
    }

    init(_ server: Server) {
        self.init(id: server.appEntityID, name: server.name, macAddress: server.macAddress)
    }
}

/// Resolves and suggests `ServerEntity` values from SwiftData.
struct ServerEntityQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ServerEntity] {
        identifiers.compactMap { id in
            (try? WakeyDataStore.shared.fetchServer(id: id)).flatMap { $0 }.map(ServerEntity.init)
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [ServerEntity] {
        let servers = (try? WakeyDataStore.shared.fetchAllServers()) ?? []
        return servers.map(ServerEntity.init)
    }
}

/// Sends a Wake-on-LAN magic packet to a saved server.
struct WakeServerIntent: AppIntent {
    static var title: LocalizedStringResource = "Wake Server"
    static var description = IntentDescription("Sends a Wake-on-LAN magic packet to a saved server.")
    static var openAppWhenRun = false

    @Parameter(title: "Server")
    var server: ServerEntity

    init() {}

    init(server: ServerEntity) {
        self.server = server
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let model = try WakeyDataStore.shared.fetchServer(id: server.id) else {
            return .result(dialog: "That server no longer exists.")
        }

        switch await WakeOnLAN.wakeServer(model) {
        case .success:
            return .result(dialog: "Woke \(server.name).")
        case .failure(let error):
            return .result(dialog: IntentDialog(stringLiteral: error.userMessage))
        }
    }
}

/// Exposes the intents to Siri and Spotlight with spoken phrases.
struct WakeyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: WakeServerIntent(),
            phrases: [
                "Wake a server with \(.applicationName)",
                "Wake \(\.$server) with \(.applicationName)"
            ],
            shortTitle: "Wake Server",
            systemImageName: "powersleep"
        )
    }
}
