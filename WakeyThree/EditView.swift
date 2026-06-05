//
//  EditView.swift
//  WakeyThree
//

#if os(macOS)
import SwiftUI
import SwiftData

struct EditView: View {
    @State private var model: ServerEditorModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(server: Server?) {
        _model = State(initialValue: ServerEditorModel(server: server))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.title)
                .font(.headline)

            Form {
                TextField("Name", text: $model.name)
                    .autocorrectionDisabled(true)

                TextField("Hardware or MAC Address", text: $model.macAddress)
                    .autocorrectionDisabled(true)
            }

            // Inline validation hints, only shown once the user has typed something
            VStack(alignment: .leading, spacing: 4) {
                if model.showNameError {
                    Label("Name cannot be empty", systemImage: "exclamationmark.triangle.fill")
                }
                if model.showMacError {
                    Label("Invalid MAC address", systemImage: "exclamationmark.triangle.fill")
                }
            }
            .font(.callout)
            .foregroundStyle(.red)

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    model.save(into: modelContext)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canSave)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

#Preview("Add") {
    EditView(server: nil)
        .modelContainer(for: Server.self, inMemory: true)
}

#Preview("Edit") {
    EditView(server: Server(macAddress: "D8:BB:C1:8F:20:DB", name: "Blinky"))
        .modelContainer(for: Server.self, inMemory: true)
}
#endif
