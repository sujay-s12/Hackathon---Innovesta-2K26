import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var onStop: ((URL?) -> Void)?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = getAudioFileURL()

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true

        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording(completion: @escaping (URL?) -> Void) {
        onStop = completion
        audioRecorder?.stop()
        isRecording = false
    }

    private func getAudioFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("meeting_\(Date().timeIntervalSince1970).m4a")
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        onStop?(flag ? recorder.url : nil)
        onStop = nil
    }
}
