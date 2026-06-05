//
//  WakeOnLANTests.swift
//  WakeyThreeTests
//
//  Covers the pure WoL logic most likely to break in a refactor: MAC validation,
//  separator normalization, magic-packet layout, and directed-broadcast math.
//

import Testing
import Foundation
@testable import WakeyThree

struct WakeOnLANTests {

    @Test func validatesGoodMacAddresses() {
        #expect(WakeOnLAN.validate(macAddress: "D8:BB:C1:8F:20:DB"))
        #expect(WakeOnLAN.validate(macAddress: "d8-bb-c1-8f-20-db"))
        #expect(WakeOnLAN.validate(macAddress: "d8bbc18f20db")) // no separators, 12 chars
    }

    @Test func rejectsBadMacAddresses() {
        #expect(!WakeOnLAN.validate(macAddress: ""))
        #expect(!WakeOnLAN.validate(macAddress: "nope"))
        #expect(!WakeOnLAN.validate(macAddress: "D8:BB:C1:8F:20"))    // too short
        #expect(!WakeOnLAN.validate(macAddress: "GG:BB:C1:8F:20:DB")) // invalid hex
    }

    @Test func sanitizeAddsSeparators() {
        #expect(WakeOnLAN.sanitizeMacAddress("d8bbc18f20db") == "d8:bb:c1:8f:20:db")
        #expect(WakeOnLAN.sanitizeMacAddress("D8:BB:C1:8F:20:DB") == "D8:BB:C1:8F:20:DB")
    }

    @Test func magicPacketLayout() throws {
        let packet = try WakeOnLAN.createMagicPackageFor(macAddress: "01:02:03:04:05:06")
        #expect(packet.count == 102)
        #expect(packet.prefix(6).allSatisfy { $0 == 0xFF })

        let mac: [UInt8] = [1, 2, 3, 4, 5, 6]
        for i in 0..<16 {
            let start = 6 + i * 6
            #expect(Array(packet[start..<start + 6]) == mac)
        }
    }

    @Test func directedBroadcastSetsLastOctet() {
        var addr = in_addr()
        _ = "192.168.1.50".withCString { inet_pton(AF_INET, $0, &addr) }

        var broadcast = WakeOnLAN.directedBroadcast(of: addr)
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        _ = inet_ntop(AF_INET, &broadcast, &buffer, socklen_t(buffer.count))

        #expect(String(cString: buffer) == "192.168.1.255")
    }

    @Test func validatesNames() {
        #expect(WakeOnLAN.validate(name: "Blinky"))
        #expect(!WakeOnLAN.validate(name: ""))
    }
}
