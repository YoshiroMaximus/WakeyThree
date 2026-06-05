//
//  PhoneEditView.swift
//  WakeyThree
//

#if !os(macOS)
import SwiftUI
import SwiftData

// iOS / iPadOS / visionOS edit view
struct PhoneEditView: View {
    @State private var model: ServerEditorModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(server: Server?) {
        _model = State(initialValue: ServerEditorModel(server: server))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $model.name)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)

                    TextField("Hardware or MAC Address", text: $model.macAddress)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }

                Section {
                    if model.showNameError {
                        Text("Name cannot be empty")
                            .foregroundStyle(.red)
                    }
                    if model.showMacError {
                        Text("Invalid MAC Address")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(model.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        withAnimation {
                            model.save(into: modelContext)
                            dismiss()
                        }
                    }
                    .disabled(!model.canSave)
                }
            }
        }
    }
}
#endif
