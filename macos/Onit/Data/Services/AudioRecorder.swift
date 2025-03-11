import AVFoundation
import Foundation

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionGranted = false
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    
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
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return audioFileURL
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
