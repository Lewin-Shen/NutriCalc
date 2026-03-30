import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showTimestamp") var showTimestamp = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Show Timestamp on Log Entries", isOn: $showTimestamp)
                } footer: {
                    Text("When enabled, each log entry will show the time it was recorded. You can also edit the date and time of an entry when logging.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
