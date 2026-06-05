//
//  PhoneView.swift
//  WakeyThree
//

#if !os(macOS)
import SwiftUI
import SwiftData

// iOS / iPadOS / visionOS main view
struct PhoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.lastUsed, order: .reverse) private var servers: [Server]

    @StateObject private var logWrapper = LoggerSwiftUI()

    @State private var editorRoute: ServerEditorRoute?
    @State private var showingLog = false

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
                                WakeOnLAN.wakeServer(server)
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
        }
    }
}

/// A simple read-only log viewer presented as a sheet.
private struct LogSheet: View {
    @ObservedObject var logWrapper: LoggerSwiftUI
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
