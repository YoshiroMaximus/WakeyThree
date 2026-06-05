//
//  Server.swift
//  WakeyLib
//
//  Created by echo on 7/3/24.
//

import Foundation
import SwiftData

public typealias Server = ServerVersionSchemaV3.Server

enum ServerMigrationPlan: SchemaMigrationPlan {

    static var schemas: [any VersionedSchema.Type] {
        [ServerVersionSchemaV1.self, ServerVersionSchemaV2.self, ServerVersionSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ServerVersionSchemaV1.self,
        toVersion: ServerVersionSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let servers = try context.fetch(FetchDescriptor<ServerVersionSchemaV2.Server>())
            for server in servers {
                server.appEntityID = UUID()
            }
            try? context.save()
        }
    )

    // V3 only adds an optional host and a defaulted port, so a lightweight
    // migration is sufficient — existing rows keep their values.
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: ServerVersionSchemaV2.self,
        toVersion: ServerVersionSchemaV3.self
    )
}

public enum ServerVersionSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        return Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Server.self]
    }

    @Model
    public final class Server {
        @Attribute(.unique) public var macAddress: String
        public var name: String
        public var lastUsed: Date?

        public init(macAddress: String, name: String) {
            self.macAddress = macAddress
            self.name = name
        }
    }
}

// App Intents require a UUID and lightweight migration does NOT populate them correctly
public enum ServerVersionSchemaV2: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        return Schema.Version(2, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Server.self]
    }

    @Model
    public final class Server {
        @Attribute(.unique) public var macAddress: String
        public var name: String

        // App Intents require a UUID
        public var appEntityID: UUID = UUID()
        public var lastUsed: Date?

        public init(macAddress: String, name: String) {
            self.macAddress = macAddress
            self.name = name
        }
    }
}

// V3 adds an optional host/IP (for directed-broadcast across subnets) and a
// configurable port (default 9).
public enum ServerVersionSchemaV3: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        return Schema.Version(3, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [Server.self]
    }

    @Model
    public final class Server {
        @Attribute(.unique) public var macAddress: String
        public var name: String

        // App Intents require a UUID
        public var appEntityID: UUID = UUID()
        public var lastUsed: Date?

        /// Optional hostname or IPv4 address. When set, the magic packet is also
        /// sent to that host's subnet directed-broadcast so it can cross subnets.
        public var host: String?
        /// Destination UDP port. 9 (discard) is the de-facto WoL default; 7 is also common.
        public var port: Int = 9

        public init(macAddress: String, name: String, host: String? = nil, port: Int = 9) {
            self.macAddress = macAddress
            self.name = name
            self.host = host
            self.port = port
        }
    }
}
