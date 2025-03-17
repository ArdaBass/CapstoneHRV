import SwiftUI
import Zip

struct FoldersView: View {
    @ObservedObject var ecgManager: ECGManager
    @State private var newFolderName = ""
    @State private var isCreatingFolder = false
    @State private var selectedECGs: Set<UUID> = []
    @State private var addingToFolder: String? = nil
    @State private var renamingFolder: String? = nil
    @State private var updatedFolderName = ""
    @State private var collapsedFolders: Set<String> = [] // ✅ Tracks collapsed folders

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    headerView()

                    if isCreatingFolder {
                        folderCreationView()
                    }

                    folderListView()
                }
                .padding()
            }
        }
    }

    private func headerView() -> some View {
        HStack {
            Text("Folders")
                .font(.title2)
                .bold()

            Spacer()

            Button(action: {
                isCreatingFolder.toggle()
            }) {
                Image(systemName: "folder.badge.plus")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .padding(8)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private func folderCreationView() -> some View {
        VStack {
            TextField("Folder Name", text: $newFolderName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                createNewFolder()
            }) {
                Text("Confirm Folder")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }

    private func createNewFolder() {
        guard !newFolderName.isEmpty else { return }

        DispatchQueue.main.async {
            if ecgManager.folders[newFolderName] == nil {
                ecgManager.folders[newFolderName] = []
            }
            newFolderName = ""
            isCreatingFolder = false
            ecgManager.saveFolders()
        }
    }

    private func folderListView() -> some View {
        ForEach(ecgManager.folders.keys.sorted(), id: \.self) { folder in
            VStack(spacing: 6) {
                HStack {
                    if renamingFolder == folder {
                        TextField("Rename Folder", text: $updatedFolderName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(4)

                        Button(action: {
                            renameFolder(from: folder, to: updatedFolderName)
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(folder)
                            .font(.headline)
                            .bold()
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button(action: {
                        addingToFolder = addingToFolder == folder ? nil : folder
                        selectedECGs.removeAll()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.trailing, 5)

                    Button(action: {
                        renamingFolder = renamingFolder == folder ? nil : folder
                        updatedFolderName = folder
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 5)

                    // ✅ Download Folder Button (ZIP format)
                    Button(action: {
                        ecgManager.exportFolderAsZIP(folder: folder)
                    }) {
                        Image(systemName: "arrow.down.to.line")
                            .foregroundColor(.green)
                    }
                    .padding(.trailing, 5)

                    // ✅ Collapse/Expand Folder Button
                    Button(action: {
                        toggleFolderCollapse(folder)
                    }) {
                        Image(systemName: collapsedFolders.contains(folder) ? "chevron.right" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 5)

                    if ecgManager.folders[folder]?.isEmpty == true {
                        Button(action: {
                            ecgManager.folders.removeValue(forKey: folder)
                            ecgManager.saveFolders()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)

                if !collapsedFolders.contains(folder) { // ✅ Show content only if folder is expanded
                    if addingToFolder == folder {
                        addECGToFolderView(folder)
                    }
                    folderECGListView(folder)
                }
            }
        }
    }

    private func renameFolder(from oldName: String, to newName: String) {
        guard !newName.isEmpty, oldName != newName else { return }

        DispatchQueue.main.async {
            if let ecgs = ecgManager.folders.removeValue(forKey: oldName) {
                ecgManager.folders[newName] = ecgs
            }
            renamingFolder = nil
            ecgManager.saveFolders()
        }
    }

    private func toggleFolderCollapse(_ folder: String) {
        if collapsedFolders.contains(folder) {
            collapsedFolders.remove(folder)
        } else {
            collapsedFolders.insert(folder)
        }
    }

    private func folderECGListView(_ folder: String) -> some View {
        let folderECGs = ecgManager.folders[folder] ?? []
        return ForEach(folderECGs, id: \.id) { sample in
            ECGRow(sample: sample, ecgManager: ecgManager, isSelecting: false, selectedECGs: .constant([]), folderName: folder)
        }
    }
    
    private func addSelectedECGsToFolder(_ folder: String) {
        for sampleID in selectedECGs {
            if let sample = ecgManager.ecgSamples.first(where: { $0.id == sampleID }) {
                ecgManager.assignECGToFolder(sample, folder: folder)
            }
        }
        selectedECGs.removeAll()
        addingToFolder = nil
    }


    private func addECGToFolderView(_ folder: String) -> some View {
        let availableECGs = ecgManager.ecgSamples.filter { $0.folderName == nil }

        return VStack {
            ForEach(availableECGs, id: \.id) { sample in
                ECGRow(sample: sample, ecgManager: ecgManager, isSelecting: true, selectedECGs: $selectedECGs)
            }

            Button(action: {
                addSelectedECGsToFolder(folder)
            }) {
                Text("Confirm Selection")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding(.top, 5)
    }
}

// ✅ **ECGManager: Added Folder Export Function**
extension ECGManager {
    func exportFolderAsZIP(folder: String) {
        guard let folderECGs = folders[folder], !folderECGs.isEmpty else {
            print("❌ No ECGs found in folder \(folder).")
            return
        }

        let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(folder)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)

            for sample in folderECGs {
                let csvString = "Time (s), Voltage (µV)\n" + sample.id.uuidString
                let fileURL = folderURL.appendingPathComponent("\(sample.id.uuidString.prefix(8)).csv")
                try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            let zipFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(folder).zip")
            try Zip.zipFiles(paths: [folderURL], zipFilePath: zipFileURL, password: nil, progress: nil)

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [zipFileURL], applicationActivities: nil)

                if let topVC = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                    .first {
                    topVC.present(activityVC, animated: true, completion: nil)
                }
                print("✅ Successfully exported folder \(folder) as ZIP.")
            }
        } catch {
            print("❌ Failed to create ZIP for folder \(folder): \(error.localizedDescription)")
        }
    }
}

struct ECGRow: View {
    let sample: ECGSample
    @ObservedObject var ecgManager: ECGManager
    var isSelecting: Bool = false
    @Binding var selectedECGs: Set<UUID>
    var folderName: String? = nil

    var body: some View {
        HStack {
            if isSelecting {
                Button(action: {
                    if selectedECGs.contains(sample.id) {
                        selectedECGs.remove(sample.id)
                    } else {
                        selectedECGs.insert(sample.id)
                    }
                }) {
                    Image(systemName: selectedECGs.contains(sample.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedECGs.contains(sample.id) ? .green : .gray)
                        .font(.title3)
                }
                .padding(.trailing, 5)
            }

            VStack(alignment: .leading) {
                Text(formatDate(sample.startDate))
                    .font(.headline)
                    .bold()
                    .foregroundColor(.primary)
            }
            Spacer()

            NavigationLink(destination: HRVAnalysisView(selectedECG: sample)) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            .padding(6)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(10)

            Button(action: {
                ecgManager.exportECGDataAsCSV(for: sample)
            }) {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            .padding(6)
            .background(Color.green.opacity(0.15))
            .cornerRadius(10)

            if let folderName = folderName {
                Button(action: {
                    ecgManager.removeECGFromFolder(sample)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .padding(6)
                .background(Color.red.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 1))
        .padding(.horizontal)
    }
}


func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}
