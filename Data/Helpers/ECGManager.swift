import Foundation
import SwiftUI
import HealthKit
import UIKit

/// Represents a single ECG data point with a unique identifier.
struct ECGDataPoint: Identifiable, Hashable {
    let id = UUID()  // 🔥 Ensures each point is unique
    let time: Double
    let voltage: Double
}

/// Represents a single ECG sample with optional folder assignment.
struct ECGSample: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let duration: TimeInterval
    var folderName: String? // ✅ Added folder name for grouping

    private enum CodingKeys: String, CodingKey {
        case id, startDate, duration, folderName
    }
}

/// **ECG Manager:** Handles fetching, organizing, and exporting ECG data.
@MainActor
class ECGManager: ObservableObject {
    let healthStore = HKHealthStore()

    @Published var ecgSamples: [ECGSample] = []
    @Published var folders: [String: [ECGSample]] = [:] // ✅ Stores ECGs grouped by folder
    @Published var ecgData: [ECGDataPoint] = []
    @Published var detectedPeaks: [Double] = []
    @Published var isLoading = false
    @Published var isSimulator = false

    @AppStorage("ECGFolders") private var storedFolders: Data? // ✅ Saves folder structure persistently

    /// Initializes the ECGManager and requests HealthKit authorization
    init() {
        requestAuthorization()
        loadFolders() // ✅ Load folders on startup
        
        #if targetEnvironment(simulator)
        isSimulator = true
        print("✅ Running in Simulator - Using Mock ECG Data")
        #endif
    }

    /// Requests HealthKit authorization to access ECG data.
    func requestAuthorization() {
        let ecgType = HKObjectType.electrocardiogramType()
        healthStore.requestAuthorization(toShare: nil, read: [ecgType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ HealthKit access granted for ECG")
                } else {
                    print("❌ Error requesting HealthKit access: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    /// Fetch ECG samples from HealthKit or mock data for the simulator.
    func fetchECGSamples() {
        if isSimulator {
            DispatchQueue.main.async {
                self.ecgSamples = createMockECGSamples() // ✅ Ensures mock data appears in UI
                print("✅ Mock ECG Samples Loaded: \(self.ecgSamples.count)")
            }
            return
        }

        let ecgType = HKObjectType.electrocardiogramType()
        let query = HKSampleQuery(sampleType: ecgType, predicate: nil, limit: 10,
                                  sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)])
        { _, results, error in
            if let error = error {
                print("❌ Error fetching ECG samples: \(error.localizedDescription)")
                return
            }

            guard let ecgResults = results as? [HKElectrocardiogram], !ecgResults.isEmpty else {
                print("❌ No ECG samples found. Ensure you have recorded an ECG in Apple Health.")
                return
            }

            DispatchQueue.main.async {
                let newSamples = ecgResults.map {
                    ECGSample(
                        id: $0.uuid,
                        startDate: $0.startDate,
                        duration: $0.endDate.timeIntervalSince($0.startDate),
                        folderName: nil // ✅ Initially, ECGs have no folder
                    )
                }
                self.ecgSamples = newSamples
                self.loadFolders() // ✅ Ensure folders persist
                print("✅ Successfully fetched \(self.ecgSamples.count) ECG samples.")
            }
        }
        healthStore.execute(query)
    }

    /// ✅ Assign an ECG to a folder
    func assignECGToFolder(_ sample: ECGSample, folder: String) {
        var updatedSample = sample
        updatedSample.folderName = folder

        if folders[folder] == nil {
            folders[folder] = []
        }
        folders[folder]?.append(updatedSample)

        saveFolders()
    }

    /// ✅ Remove an ECG from a folder
    func removeECGFromFolder(_ sample: ECGSample) {
        if let folder = sample.folderName {
            folders[folder]?.removeAll { $0.id == sample.id }
            if folders[folder]?.isEmpty == true {
                folders.removeValue(forKey: folder) // ✅ Remove empty folder
            }
        }
        saveFolders()
    }

    /// ✅ Save folders persistently
    func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            storedFolders = encoded
        }
    }

    /// ✅ Load folders from persistent storage
    private func loadFolders() {
        if let data = storedFolders, let savedFolders = try? JSONDecoder().decode([String: [ECGSample]].self, from: data) {
            folders = savedFolders
        }
    }

    /// Fetch ECG Data points and detect peaks for a specific sample.
    func fetchECGData(for sample: ECGSample) {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.ecgData.removeAll()
                self.detectedPeaks.removeAll()
            }

            let rawData = createMockECGData()
            let peaks = detectPeaks(in: rawData)

            DispatchQueue.main.async {
                self.ecgData = rawData.map { ECGDataPoint(time: $0.time, voltage: $0.voltage) }
                self.detectedPeaks = peaks
                self.isLoading = false
                print("✅ Processed \(self.ecgData.count) ECG data points for sample \(sample.id).")
            }
        }
    }

    /// Exports ECG data for a specific sample as a CSV file and allows sharing.
    func exportECGDataAsCSV(for sample: ECGSample) {
        DispatchQueue.main.async {
            var fileName = "ECGData_\(formatDateForFile(sample.startDate))"

            let alert = UIAlertController(title: "Save ECG Data", message: "Enter a name for the CSV file", preferredStyle: .alert)

            // ✅ Add text field for file name input
            alert.addTextField { textField in
                textField.text = fileName
                textField.placeholder = "Enter file name"
            }

            // ✅ Save Action
            let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                if let inputName = alert.textFields?.first?.text, !inputName.trimmingCharacters(in: .whitespaces).isEmpty {
                    fileName = inputName.replacingOccurrences(of: " ", with: "_") // ✅ Ensure valid filename
                }
                self.performCSVExport(for: sample, fileName: fileName)
            }

            // ❌ Cancel Action
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

            alert.addAction(saveAction)
            alert.addAction(cancelAction)

            if let topVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                .first {
                topVC.present(alert, animated: true, completion: nil)
            }
        }
    }
    private func performCSVExport(for sample: ECGSample, fileName: String) {
        fetchECGData(for: sample) // ✅ Ensure ECG data is available

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            guard !self.ecgData.isEmpty else {
                print("❌ No ECG data available for export.")
                return
            }

            var csvString = "Time (s), Voltage (µV)\n"
            for entry in self.ecgData {
                csvString += "\(String(format: "%.6f", entry.time)), \(entry.voltage)\n"
            }

            let path = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).csv")

            do {
                try csvString.write(to: path, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: [path], applicationActivities: nil)
                    if let topVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.windows.first?.rootViewController })
                        .first {
                        topVC.present(activityVC, animated: true, completion: nil)
                    }
                    print("✅ Successfully exported ECG data as \(fileName).csv")
                }
            } catch {
                print("❌ Failed to save CSV: \(error.localizedDescription)")
            }
        }
    }
   


}

private func formatDateForFile(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss" // ✅ File-safe format
    return formatter.string(from: date)
}


