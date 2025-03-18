import AVFoundation
import Foundation
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var permissionGranted = false
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var audioLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var levelTimer: Timer?
    private var silenceTimer: Timer?
    private var lastSignificantAudioTime: Date?
    private let silenceThreshold: Float = 0.02
    private var minDB: Float = 0.0
    private var maxDB: Float = -100.0
    
    override init() {
        super.init()
        Task { @MainActor in
            await checkPermission()
        }
    }
    
    func checkPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        self.permissionStatus = status
        
        switch status {
        case .authorized:
            self.permissionGranted = true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            self.permissionGranted = granted
            self.permissionStatus = granted ? .authorized : .denied
        default:
            self.permissionGranted = false
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        self.audioFileURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            
            // Start monitoring audio levels
            startMonitoringAudioLevels()
            
            // Reset the last significant audio time
            lastSignificantAudioTime = Date()
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        stopMonitoringAudioLevels()
        audioRecorder?.stop()
        isRecording = false
        return audioFileURL
    }
    
    private func startMonitoringAudioLevels() {
        // Stop any existing timers
        levelTimer?.invalidate()
        silenceTimer?.invalidate()
        
        // Create a timer to update audio levels
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                
                // Get the average power in decibels
                let averagePower = recorder.averagePower(forChannel: 0)
                self.minDB = min(self.minDB, averagePower)
                self.maxDB = max(self.maxDB, averagePower)

                // Convert decibels to a linear scale (0.0 to 1.0)
//                let minDb: Float = -45.0
                let normalizedValue = max(0.0, (averagePower - self.minDB) / abs(self.maxDB - self.minDB))
                
                // Apply more smoothing to avoid jumpy animation
                self.audioLevel = min(1.0, self.audioLevel * 0.85 + normalizedValue * 0.15)
                
                // Check if we have significant audio
                if self.audioLevel > self.silenceThreshold {
                    self.lastSignificantAudioTime = Date()
                }
            }
        }
    }
    
    private func stopMonitoringAudioLevels() {
        levelTimer?.invalidate()
        levelTimer = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
        audioLevel = 0.0
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
