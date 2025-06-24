import AVFoundation
import Defaults
import Foundation
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var permissionGranted = false
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var audioLevel: Float = 0.0
    @Published var recordingError: Error? = nil
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var levelTimer: Timer?
    private var lastSignificantAudioTime: Date?
    private var minDB: Float = 0.0
    private var maxDB: Float = -100.0
    private var consecutiveSignificantSamples = 0
    private let requiredConsecutiveSamples = 3  // Required amount of above-threshold samples for valid audio transcription.
    
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
    
    func startRecording() -> Bool {
        // Reset any previous error
        recordingError = nil
        
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
            
            // Reset/clean up values for new recording.
            lastSignificantAudioTime = nil
            consecutiveSignificantSamples = 0
            return true
        } catch {
            print("Could not start recording: \(error)")
            recordingError = error  // Set the error property
            stopMonitoringAudioLevels()
            return false
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
                let dbRange = abs(self.maxDB - self.minDB)
                let normalizedValue = dbRange > 0.1 ? max(0, (averagePower - self.minDB) / dbRange) : 0
                
                // Apply more smoothing to avoid jumpy animation
                self.audioLevel = min(1.0, self.audioLevel * 0.85 + normalizedValue * 0.15)
                
                // Check if we have significant audio
                // Using `audioSilenceThreshold` to detect actual speech vs. ambient noise.
                if averagePower > Defaults[.voiceSilenceThreshold] {
                    self.consecutiveSignificantSamples += 1
                    
                    let hasSustainedSignificantAudio = self.consecutiveSignificantSamples >= self.requiredConsecutiveSamples
                    
                    if hasSustainedSignificantAudio {
                        self.lastSignificantAudioTime = Date()
                    }
                } else {
                    // Reset counter if we drop below threshold.
                    self.consecutiveSignificantSamples = 0
                }
            }
        }
    }
    
    private func stopMonitoringAudioLevels() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0.0
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func clearError() {
        recordingError = nil
    }
    
    func recordingIsNotSilent() -> Bool {
        return lastSignificantAudioTime != nil
    }
}
