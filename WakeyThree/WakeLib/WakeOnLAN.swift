//
//  WakeOnLAN.swift
//  WakeyLib
//
//  Created by echo on 7/5/24.
//

import Foundation

public enum NetworkError: Error {
    case invalidMacAddress // fallure to read mac address

    // sendto errno codes
    case noRouteToHost // on iOS, this indicates a lack of network permission or entitlement
    case networkUnreachable // no connections found
    case cannotAssignRequestedAddress // no LAN connections found. Likely cell or public IP only
    case noSuchFileOrDirectory // on macOS 15+, this indicates a lack of network permission
    case socketFailue // catch all for any socket related error
}

public struct WakeOnLAN {

    /// Wakes a server and, on success, bumps its `lastUsed` timestamp so it
    /// floats to the top of the most-recently-used list. A failed wake leaves
    /// the ordering untouched. Runs on the main actor so it can safely mutate
    /// the SwiftData model; the blocking socket work hops off-main inside `wake`.
    @MainActor
    @discardableResult
    public static func wakeServer(_ server: Server) async -> Result<Void, NetworkError> {
        let macAddress = server.macAddress
        let host = server.host
        let port = server.port
        do {
            try await wake(macAddress: macAddress, host: host, port: port)
            server.lastUsed = Date.now
            return .success(())
        } catch let error as NetworkError {
            return .failure(error)
        } catch {
            return .failure(.socketFailue)
        }
    }

    // quick actions / App Intents helper
    @MainActor
    @discardableResult
    public static func wakeServerByName(_ name: String) async -> Result<Void, NetworkError> {
        do {
            guard let server = try WakeyDataStore.shared.fetchServer(name: name) else {
                Logger.shared.logWarning(message: "Failed to find server with name: \(name)")
                return .failure(.socketFailue)
            }
            return await wakeServer(server)
        } catch {
            return .failure(.socketFailue)
        }
    }

    nonisolated public static func validate(name: String) -> Bool {
        return (name.count > 0)
    }

    nonisolated public static func validate(macAddress: String) -> Bool {
        guard macAddress.count == 17 || (macAddress.count == 12 && !containsSeparators(macAddress)) else {
            return false
        }

        // scanner.scanHexInt64 ignores overflow...
        let charset = "0123456789abcdefABCDEF:-"
        for char in macAddress {
            if !charset.contains(char) {
                return false
            }
        }

        let cleanMacAddress = sanitizeMacAddress(macAddress)
        do {
            let works = try WakeOnLAN.readMacAddressFrom(hexString: cleanMacAddress)
            if works.count == 6 {
                return true
            }
        } catch { }

        Logger.shared.logWarning(message: "Invalid MAC address, ignoring")
        return false
    }

    nonisolated static func containsSeparators(_ string: String) -> Bool {
        return string.contains("-") || string.contains(":")
    }

    /// Adds separators to strings that lack them, improves usability
    nonisolated static func sanitizeMacAddress(_ string: String) -> String {
        if string.count == 17 {
            return string
        }

        var sanitized = ""
        for (index, character) in string.enumerated() {
            sanitized.append(character)
            if (index+1) % 2 == 0 && index != string.count-1 {
                sanitized.append(":")
            }
        }

        return sanitized
    }

    /// Parses a MAC address hex string into 6 bytes. Assumes separators (":"/"-") between octets.
    nonisolated static func readMacAddressFrom(hexString: String) throws -> [UInt8] {
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: ":-")

        var bytes: [UInt8] = []
        bytes.reserveCapacity(6)
        for _ in 0..<6 {
            var octet: UInt64 = 0
            guard scanner.scanHexInt64(&octet) else {
                throw NetworkError.invalidMacAddress
            }
            bytes.append(UInt8(truncatingIfNeeded: octet))
        }
        return bytes
    }

    // macOS Sequoia's Local Network permission handler does not initialize very
    // quickly, so transient failures are retried. The `Task.sleep` between
    // attempts suspends without blocking a thread.
    // https://developer.apple.com/forums/thread/765513
    nonisolated static func wake(macAddress: String, host: String? = nil, port: Int = 9, maxAttempts: Int = 3) async throws {
        var lastError: NetworkError = .socketFailue

        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                Logger.shared.logWarning(message: "Will retry in 2 seconds")
                try? await Task.sleep(for: .seconds(2))
            }

            do {
                try sendWakeOnLAN(macAddress: macAddress, host: host, port: port)
                return
            } catch let error as NetworkError {
                lastError = error
            }
        }

        Logger.shared.logError(message: "Failed to send magic packet to \(macAddress) after \(maxAttempts) attempts.")
        throw lastError
    }

    nonisolated static func sendWakeOnLAN(macAddress: String, host: String? = nil, port: Int = 9) throws {
        let udpSocket = try self.setupSocket()

        // rebind sockaddr_in to sockaddr, then call bind
        var udpClient = self.setupUDPClient()
        let clientBindStatus = withUnsafePointer(to: &udpClient) { sockAddressIn in
            sockAddressIn.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddress in
                bind(udpSocket, sockAddress, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }
        guard clientBindStatus != -1 else {
            throw NetworkError.socketFailue
        }

        let magicPacket = try self.createMagicPackageFor(macAddress: macAddress)
        let packetSize = magicPacket.count

        // rebind sockaddr_in to sockaddr, then call sendto
        var udpServer = self.setupUDPServer(host: host, port: port)
        let sendStatus = withUnsafePointer(to: &udpServer) { sockAddressIn in
            sockAddressIn.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddress in
                sendto(udpSocket, magicPacket, packetSize, 0, sockAddress, socklen_t(MemoryLayout<sockaddr_in>.stride))
            }
        }

        let timestamp = Date.now.formatted(date: .omitted, time: .standard)
        guard sendStatus != -1 else {
            // errno is global and may be clobbered by a later syscall, so capture it now.
            // https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20161031/028627.html
            let code = errno
            Logger.shared.logVerbose(message: "Wake \(macAddress) at \(timestamp). status: failed errno:\(code)")
            switch code {
            case EHOSTUNREACH:
                // No route to host. On iOS this usually means Local Network permission is missing.
                Logger.shared.logVerbose(message: "No route to host. Have you granted Local Network permission?")
                throw NetworkError.noRouteToHost
            case ENETUNREACH:
                Logger.shared.logVerbose(message: "Network unreachable. Are you offline?")
                throw NetworkError.networkUnreachable
            case EADDRNOTAVAIL:
                Logger.shared.logVerbose(message: "Can't assign requested address. Are you on cellular only?")
                throw NetworkError.cannotAssignRequestedAddress
            case ENOENT:
                // macOS 15+ reports this until Local Network permission is granted.
                Logger.shared.logVerbose(message: "No such file or directory. Have you granted Local Network permission?")
                throw NetworkError.noSuchFileOrDirectory
            default:
                Logger.shared.logVerbose(message: "Unexpected errno: \(code).")
                throw NetworkError.socketFailue
            }
        }

        Logger.shared.logVerbose(message: "Wake \(macAddress) at \(timestamp). status: OK")
    }

    nonisolated static func setupSocket() throws -> Int32 {
        let udpSocket = socket(AF_INET, SOCK_DGRAM, 0)
        guard udpSocket != -1 else {
            throw NetworkError.socketFailue
        }

        // SO_BROADCAST works on both IPv4 and IPv6
        var broadcast: Int32 = 1
        let broadcastSetupStatus = setsockopt(udpSocket, SOL_SOCKET, SO_BROADCAST, &broadcast, socklen_t(MemoryLayout<Int32>.size))
        guard broadcastSetupStatus != -1 else {
            throw NetworkError.socketFailue
        }

        return udpSocket
    }

    nonisolated static func setupUDPClient() -> sockaddr_in {
        var socketAddressIn = sockaddr_in()
        socketAddressIn.sin_family = UInt8(truncatingIfNeeded: AF_INET)
        socketAddressIn.sin_addr.s_addr = INADDR_ANY
        socketAddressIn.sin_port = 0
        return socketAddressIn
    }

    /// Destination for the magic packet. With no host this is the limited
    /// broadcast (255.255.255.255), which stays on the local subnet. With a host
    /// it targets that host's /24 directed broadcast, which a suitably-configured
    /// router can forward across subnets.
    nonisolated static func setupUDPServer(host: String?, port: Int) -> sockaddr_in {
        var socketAddressIn = sockaddr_in()
        socketAddressIn.sin_family = UInt8(truncatingIfNeeded: AF_INET)
        socketAddressIn.sin_port = UInt16(truncatingIfNeeded: port).bigEndian

        if let host, !host.isEmpty, let addr = resolveIPv4(host) {
            socketAddressIn.sin_addr = directedBroadcast(of: addr)
        } else {
            socketAddressIn.sin_addr.s_addr = INADDR_BROADCAST
        }
        return socketAddressIn
    }

    /// Resolves a hostname or dotted IPv4 string to an `in_addr`, or nil on failure.
    nonisolated static func resolveIPv4(_ host: String) -> in_addr? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_DGRAM

        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, nil, &hints, &result) == 0, let result else {
            return nil
        }
        defer { freeaddrinfo(result) }

        var node: UnsafeMutablePointer<addrinfo>? = result
        while let current = node {
            if current.pointee.ai_family == AF_INET, let sa = current.pointee.ai_addr {
                return sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee.sin_addr }
            }
            node = current.pointee.ai_next
        }
        return nil
    }

    /// The /24 directed-broadcast address for an IPv4 address (last octet → 255).
    nonisolated static func directedBroadcast(of addr: in_addr) -> in_addr {
        var raw = addr.s_addr // network byte order: memory is [a][b][c][d]
        withUnsafeMutableBytes(of: &raw) { $0[3] = 0xFF }
        return in_addr(s_addr: raw)
    }

    /// Builds the 102-byte magic packet: 6 bytes of 0xFF followed by the MAC repeated 16 times.
    nonisolated static func createMagicPackageFor(macAddress: String) throws -> [UInt8] {
        let mac = try readMacAddressFrom(hexString: sanitizeMacAddress(macAddress))
        guard mac.count == 6 else { throw NetworkError.invalidMacAddress }

        var packet = [UInt8](repeating: 0xFF, count: 6)
        for _ in 0..<16 {
            packet.append(contentsOf: mac)
        }
        return packet
    }
}
