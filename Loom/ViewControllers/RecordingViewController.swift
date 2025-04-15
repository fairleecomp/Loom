import UIKit
import AVFoundation

class RecordingViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    
    var audioRecorder: AVAudioRecorder?
    var recordedFileURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recordButton.setTitle("", for: .normal)
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if audioRecorder == nil {
            startRecording()
            recordButton.setTitle("Stop", for: .normal)
        } else {
            stopRecording()
            recordButton.setTitle("Record", for: .normal)
        }
    }
    
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
            
            let filename = UUID().uuidString + ".m4a"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            recordedFileURL = fileURL
            
            print("Recording started: \(fileURL.absoluteString)")
        } catch {
            print("Error starting recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        print("Recording stopped.")
        
        // Once the recording stops, assign it to the mixer.
        if let url = recordedFileURL {
            MixerManager.shared.assignRecording(url: url)
        }
    }
}
