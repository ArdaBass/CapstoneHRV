import SwiftUI

struct HRVAnalysisView: View {
    let selectedECG: ECGSample // ✅ Selected ECG sample for HRV Analysis

    @State private var hrvData: [ECGDataPoint] = []
    @State private var detectedPeaks: [Double] = []
    @State private var hrvParameters: [String: Double] = [:]
    @State private var graphID = UUID()

    // 🔹 Reference values for HRV parameters
    let referenceRanges: [String: (lower: Double, upper: Double)] = [
        "RMSSD": (20.0, 70.0),
        "SDNN": (30.0, 100.0),
        "pNN50": (5.0, 30.0),
        "LF/HF Ratio": (0.5, 3.0)
    ]

    var body: some View {
        NavigationView {
            VStack {
                Text("HRV Analysis")
                    .font(.largeTitle)
                    .padding()

                if !hrvData.isEmpty {
                    VStack {
                        Text("ECG Waveform")
                            .font(.headline)
                            .padding(.top, 10)

                        ECGGraphView(ecgData: hrvData, detectedPeaks: detectedPeaks)
                            .id(graphID)
                            .frame(height: 300)
                            .padding(.horizontal)
                    }
                    .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 2))
                    .padding(.bottom, 10)
                }

                PeakTimestampsView(detectedPeaks: detectedPeaks)

                VStack(alignment: .leading, spacing: 10) {
                    Text("HRV Parameters")
                        .font(.headline)

                    ForEach(hrvParameters.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        let range = referenceRanges[key] ?? (0, 100)
                        let color = getColor(for: value, within: range)

                        HStack {
                            Text("\(key):")
                                .bold()
                            Spacer()
                            Text("\(value, specifier: "%.2f")")
                                .foregroundColor(color)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()

                Spacer()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadECGData()
                }
            }
        }
    }

    /// Loads ECG data for the selected sample
    func loadECGData() {
        DispatchQueue.global(qos: .userInitiated).async {
            let mockECG = downsampleECGData(createMockECGData(), factor: 10)
            let peaks = detectPeaks(in: mockECG)

            DispatchQueue.main.async {
                self.hrvData = mockECG.map { ECGDataPoint(time: $0.time, voltage: $0.voltage) }
                self.detectedPeaks = peaks

                self.hrvParameters = [
                    "RMSSD": 23.5,
                    "SDNN": 50.2,
                    "pNN50": 18.3,
                    "LF/HF Ratio": 1.75
                ]
            }
        }
    }
    
    /// Downsamples ECG Data for smoother rendering
    func downsampleECGData(_ data: [(time: Double, voltage: Double)], factor: Int = 10) -> [(time: Double, voltage: Double)] {
        guard factor > 1 else { return data }
        return data.enumerated().compactMap { index, point in
            return index % factor == 0 ? point : nil
        }
    }

    /// Determines text color based on HRV parameter values
    func getColor(for value: Double, within range: (lower: Double, upper: Double)) -> Color {
        let margin = (range.upper - range.lower) * 0.1 // 10% margin for yellow
        if value < range.lower - margin || value > range.upper + margin {
            return .red // 🚨 Out of range
        } else if value < range.lower || value > range.upper {
            return .yellow // ⚠️ Near limits
        } else {
            return .green // ✅ Normal range
        }
    }
}
