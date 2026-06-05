//
//  WakeyDataStore.swift
//  WakeyLib
//
//  Created by echo on 12/1/24.
//

import Foundation
import SwiftData

/// Shared access to SwiftData from app and extensions
/// SwiftUI views can directly use the ModelContainer to get access to Query.
/// Other code can use the helper methods to handle CRUD operations.
public struct WakeyDataStore: Sendable {

    public static let shared = WakeyDataStore()

    // For direct access to the ModelContainer, allows SwiftUI Views to use Query
    public let container: ModelContainer

    public init() {
        self.container = WakeyDataStore.initModelContainer()
    }

    static func initModelContainer() -> ModelContainer {
        let schema = Schema([
            Server.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, migrationPlan: ServerMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            // Log the FULL error — `error.localizedDescription` hides the real
            // CoreData/SwiftData reason behind a generic message.
            Logger.shared.logError(message: "ModelContainer init failed: \(error)")

            // Most likely an unreadable or unmigratable store on disk. Move it
            // aside so the app can still launch with a fresh store rather than
            // hard-crashing on every launch.
            archiveCorruptStore(at: modelConfiguration.url)
            do {
                return try ModelContainer(for: schema, migrationPlan: ServerMigrationPlan.self, configurations: [modelConfiguration])
            } catch {
                // Last resort: an in-memory store keeps the app usable this session.
                Logger.shared.logError(message: "ModelContainer recovery failed, falling back to in-memory: \(error)")
                let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                // swiftlint:disable:next force_try
                return try! ModelContainer(for: schema, configurations: [memoryConfiguration])
            }
        }
    }

    /// Moves a failed store (and its -wal/-shm sidecar files) aside so a clean
    /// store can be created in its place. Best-effort; failures are logged.
    private static func archiveCorruptStore(at storeURL: URL) {
        let fm = FileManager.default
        let suffix = ".corrupt-backup"
        for sidecar in ["", "-wal", "-shm"] {
            let src = URL(fileURLWithPath: storeURL.path + sidecar)
            guard fm.fileExists(atPath: src.path) else { continue }
            let dst = URL(fileURLWithPath: src.path + suffix)
            try? fm.removeItem(at: dst)
            do {
                try fm.moveItem(at: src, to: dst)
                Logger.shared.logWarning(message: "Archived unreadable store: \(src.lastPathComponent) -> \(dst.lastPathComponent)")
            } catch {
                Logger.shared.logError(message: "Could not archive store file \(src.lastPathComponent): \(error)")
            }
        }
    }

    public func create(_ server: Server) throws {
        // ModelContext is not Sendable, it is tied to the thread that created it.
        let context = ModelContext(container)
        context.insert(server)
        try context.save()
    }

    public func delete(_ server: Server) throws {
        let context = ModelContext(container)
        let id = server.persistentModelID
        try context.delete(model: Server.self, where: #Predicate<Server> { server in
            server.persistentModelID == id
        })
        try context.save()
    }

    // for app intents, suggested list
    public func fetchAllServers() throws -> [Server] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Server>(
            sortBy: [
                SortDescriptor(\.lastUsed, order: .reverse)
            ]
         )
        return try context.fetch(descriptor)
    }

    // for app intents
    public func fetchServer(id: UUID) throws -> Server? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Server>(
            predicate: #Predicate<Server> { server in
                server.appEntityID == id
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // for quick actions
    public func fetchRecentServers() throws -> [Server] {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Server>(
            sortBy: [
                SortDescriptor(\.lastUsed, order: .reverse)
            ]
         )
        descriptor.fetchLimit = 3
        return try context.fetch(descriptor)
    }

    // for quick actions, it only provides the quick item title
    public func fetchServer(name: String) throws -> Server? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Server>(
            predicate: #Predicate<Server> { server in
                server.name == name
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

}
