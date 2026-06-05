//
//  PhoneView.swift
//  WakeyThree
//

#if !os(macOS)
import SwiftUI
import SwiftData
#if os(iOS)
import UIKit
#endif

// iOS / iPadOS / visionOS main view
struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.lastUsed, order: .reverse) private var servers: [Server]

    @State private var logWrapper = LoggerSwiftUI()

    @State private var editorRoute: ServerEditorRoute?
    @State private var showingLog = false
    @State private var toast: WakeMessage?

    var body: some View {
        NavigationStack {
            Group {
                if servers.isEmpty {
                    ContentUnavailableView {
                        Label("No Servers", systemImage: "powersleep")
                    } description: {
                        Text("Add a server to wake it over your network.")
                    } actions: {
                        Button("Add Server") { editorRoute = .add }
                    }
                } else {
                    List {
                        ForEach(servers) { server in
                            Button {
                                Task { await wake(server) }
                            } label: {
                                HStack {
                                    ServerLabel(server: server)
                                    Spacer()
                                    Image(systemName: "power")
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .leading) {
                                Button("Edit", systemImage: "pencil") {
                                    editorRoute = .edit(server)
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    withAnimation { modelContext.delete(server) }
                                }
                            }
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") {
                                    editorRoute = .edit(server)
                                }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    withAnimation { modelContext.delete(server) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("WakeyThree")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Server", systemImage: "plus") {
                        editorRoute = .add
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu("More", systemImage: "ellipsis.circle") {
                        Button("View Log", systemImage: "text.alignleft") {
                            showingLog = true
                        }
                        Link(destination: WakeyLinks.help) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    }
                }
            }
            .sheet(item: $editorRoute) { route in
                switch route {
                case .add:
                    PhoneEditView(server: nil)
                case .edit(let server):
                    PhoneEditView(server: server)
                }
            }
            .sheet(isPresented: $showingLog) {
                LogSheet(logWrapper: logWrapper)
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    WakeToast(message: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func wake(_ server: Server) async {
        let result = await WakeOnLAN.wakeServer(server)
        let message = WakeMessage(result: result, serverName: server.name)

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(message.isSuccess ? .success : .error)
        #endif

        withAnimation { toast = message }
        try? await Task.sleep(for: .seconds(message.isSuccess ? 2 : 4))
        withAnimation { if toast?.title == message.title { toast = nil } }
    }
}

/// Transient banner confirming a wake (or explaining why it failed).
private struct WakeToast: View {
    let message: WakeMessage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(message.isSuccess ? .green : .orange)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(.subheadline.weight(.semibold))
                Text(message.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

/// A simple read-only log viewer presented as a sheet.
private struct LogSheet: View {
    var logWrapper: LoggerSwiftUI
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LogTextView(text: logWrapper.text)
                .padding()
                .navigationTitle("Log")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) {
                            logWrapper.removalAll()
                        }
                    }
                }
        }
    }
}

#Preview {
    PhoneView()
        .modelContainer(for: Server.self, inMemory: true)
}
#endif
