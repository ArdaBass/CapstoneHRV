import SwiftUI

struct ContentView: View {
    @StateObject private var ecgManager = ECGManager() // ✅ Shared instance

    var body: some View {
        TabView {
            // 🔹 ECG Data Page
            ECGDataView(ecgManager: ecgManager)
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("ECG Data")
                }

            // 🔹 Folders Page (Manages ECG Grouping)
            FoldersView(ecgManager: ecgManager)
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Folders")
                }

            // 🔹 Settings Page
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
        }
    }
}
