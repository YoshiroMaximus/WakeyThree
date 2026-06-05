//
//  WakeFeedback.swift
//  WakeyThree
//
//  Turns a wake Result into user-facing feedback. The networking layer already
//  distinguishes the actionable failure cases (notably missing Local Network
//  permission); this surfaces them instead of only logging.
//

import Foundation

extension NetworkError {
    /// A short, actionable message suitable for a notification or toast.
    var userMessage: String {
        switch self {
        case .noRouteToHost, .noSuchFileOrDirectory:
            return "Couldn’t reach the local network. Grant WakeyThree “Local Network” permission in System Settings, then try again."
        case .networkUnreachable:
            return "No network connection. Join your local Wi-Fi or Ethernet and try again."
        case .cannotAssignRequestedAddress:
            return "No local network found. Wake-on-LAN needs Wi-Fi or Ethernet — not cellular."
        case .invalidMacAddress:
            return "That MAC address looks invalid."
        case .socketFailue:
            return "Something went wrong sending the magic packet."
        }
    }
}

/// Title + body for a wake outcome, shared by every platform's delivery mechanism.
struct WakeMessage {
    let title: String
    let body: String
    let isSuccess: Bool

    init(result: Result<Void, NetworkError>, serverName: String) {
        switch result {
        case .success:
            title = "Magic packet sent"
            body = "Woke \(serverName)."
            isSuccess = true
        case .failure(let error):
            title = "Couldn’t wake \(serverName)"
            body = error.userMessage
            isSuccess = false
        }
    }
}
