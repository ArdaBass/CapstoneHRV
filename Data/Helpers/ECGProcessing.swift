import Foundation

func detectPeaks(in data: [(time: Double, voltage: Double)]) -> [Double] {
    let threshold: Double = 80.0
    var peaks: [Double] = []
    
    for i in 1..<data.count - 1 {
        if data[i].voltage > threshold &&
            data[i].voltage > data[i - 1].voltage &&
            data[i].voltage > data[i + 1].voltage {
            peaks.append(data[i].time)
        }
    }
    return peaks
}

func createMockECGSamples() -> [ECGSample] {
    return [
        ECGSample(id: UUID(), startDate: Date().addingTimeInterval(-3600), duration: 30.0),
        ECGSample(id: UUID(), startDate: Date().addingTimeInterval(-7200), duration: 30.0)
    ]
}


func createMockECGData() -> [(time: Double, voltage: Double)] {
    let samplingRate = 512.0 // ✅ 512 samples per second (realistic ECG rate)
    let duration = 30.0 // ✅ Generate data for 30 seconds
    let totalSamples = Int(samplingRate * duration) // Total number of points

    var ecgData: [(time: Double, voltage: Double)] = []

    for i in 0..<totalSamples {
        let time = Double(i) / samplingRate // ✅ Time in seconds

        // ✅ Simulated ECG signal with realistic heartbeats (1Hz frequency = 60bpm)
        let heartRate = 60.0 // Beats per minute
        let frequency = heartRate / 60.0 // Hz
        let voltage = 100 * sin(2 * .pi * frequency * time) // ✅ Sine wave simulating ECG waveform

        ecgData.append((time, voltage))
    }

    return ecgData
}



