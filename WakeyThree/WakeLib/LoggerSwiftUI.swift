//
//  LoggerSwiftUI.swift
//  WakeyLib
//
//  Created by echo on 6/4/24.
//

import Foundation
import Observation

/// Bridges the SDK `Logger` into an observable type SwiftUI debug views can read.
@MainActor
@Observable
public final class LoggerSwiftUI: LogDestination {

    public private(set) var text: String = ""

    // line limit, makes it easier to read than a character limit
    // this version trades data duplication for simplicity
    @ObservationIgnored public var maxLines = 10
    @ObservationIgnored private var textLines: [String] = []

    public init() {
        Logger.shared.setDestination(destination: self)
        Logger.shared.playbackBuffer()
    }

    // incoming log messages can be from any thread, just fire and forget them
    public nonisolated func handle(message: String) {
        Task {
            await self.eventuallyHandle(message: message)
        }
    }

    private func eventuallyHandle(message: String) {
        self.textLines.append(message)
        if self.textLines.count > self.maxLines {
            self.textLines.removeFirst()
        }

        self.text = self.textLines.reversed().joined(separator: "\n")
    }

    public func removalAll() {

        // UI elements are cleared immediately on main
        self.text.removeAll()
        self.textLines.removeAll()

        // The backing Logger is scheduled to be cleared on a background queue
        Logger.shared.clearBuffer()
    }
}
