//
//  SettingsView.swift
//  WakeyThree
//

#if os(macOS)
import SwiftUI
import SwiftData

struct SettingsView: View {
    static let viewID: String = "settings-view"
    static let titleString = "WakeyThree"

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Server.lastUsed, order: .reverse) private var servers: [Server]

    @StateObject private var logWrapper = LoggerSwiftUI()

    @State private var editorRoute: ServerEditorRoute?

    var body: some View {
        VStack(spacing: 0) {
            serverList
            Divider()
            footer
        }
        .frame(width: 380, height: 420)
        .navigationTitle(SettingsView.titleString)
        .sheet(item: $editorRoute) { route in
            switch route {
            case .add:
                EditView(server: nil)
            case .edit(let server):
                EditView(server: server)
            }
        }
    }

    @ViewBuilder
    private var serverList: some View {
        if servers.isEmpty {
            ContentUnavailableView {
                Label("No Servers", systemImage: "powersleep")
            } description: {
                Text("Add a server to wake it over your network.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(servers) { server in
                    ServerRow(server: server) {
                        editorRoute = .edit(server)
                    } onRemove: {
                        modelContext.delete(server)
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var footer: some View {
        HStack {
            Button {
                editorRoute = .add
            } label: {
                Label("Add Server", systemImage: "plus")
            }

            Spacer()

            LogPopover(logWrapper: logWrapper)

            Link(destination: WakeyLinks.help) {
                Image(systemName: "questionmark.circle")
            }
            .help("Help")
        }
        .buttonStyle(.borderless)
        .padding(12)
    }
}

/// A single server row: name + MAC, with subtle edit/remove actions.
private struct ServerRow: View {
    let server: Server
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ServerLabel(server: server)

            Spacer()

            Button("Edit", systemImage: "pencil", action: onEdit)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

            Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: onEdit)
        .contextMenu {
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
        }
    }
}

/// A small log viewer tucked behind a popover so it stays out of the way.
private struct LogPopover: View {
    @ObservedObject var logWrapper: LoggerSwiftUI
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "text.alignleft")
        }
        .help("Log")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Log")
                        .font(.headline)
                    Spacer()
                    Button("Clear", role: .destructive) {
                        logWrapper.removalAll()
                    }
                    .buttonStyle(.borderless)
                }

                LogTextView(text: logWrapper.text)
            }
            .padding(12)
            .frame(width: 320, height: 220)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Server.self, inMemory: true)
}
#endif
