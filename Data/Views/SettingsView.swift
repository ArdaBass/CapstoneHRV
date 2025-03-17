import SwiftUI

struct SettingsView: View {
    @AppStorage("themeColor") private var themeColor: String = "Blue"
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    let colors: [String] = ["Blue", "Green", "Red", "Purple"]
    
    // ✅ Fetch the app version from Info.plist
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("ECG Graph Color", selection: $themeColor) {
                        ForEach(colors, id: \.self) { color in
                            Text(color)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { _ in
                            updateAppearance()
                        }
                }

                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion) // ✅ Dynamically fetch the version
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("Arda")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    func updateAppearance() {
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
}
