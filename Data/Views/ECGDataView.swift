import SwiftUI

struct ECGDataView: View {
    @ObservedObject var ecgManager: ECGManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    headerView()

                    unassignedECGView()
                }
                .padding()
            }
        }
        .onAppear {
            ecgManager.fetchECGSamples()
        }
    }

    private func headerView() -> some View {
        HStack {
            Text("ECG Data Exporter")
                .font(.title2)
                .bold()

            Spacer()

            Button(action: {
                ecgManager.fetchECGSamples()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .padding(8)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    private func unassignedECGView() -> some View {
        let unassignedECGs = ecgManager.ecgSamples.filter { $0.folderName == nil }

        return Group {
            if !unassignedECGs.isEmpty {
                Section(header: Text("Fetched ECGs").font(.headline)) {
                    ForEach(unassignedECGs, id: \.id) { sample in
                        ECGRow(sample: sample, ecgManager: ecgManager, isSelecting: false, selectedECGs: .constant([]))
                    }
                }
            }
        }
    }

}
