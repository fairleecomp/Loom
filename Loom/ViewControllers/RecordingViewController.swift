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
        
        
            
            // When stopping the recording:
            if let url = recordedFileURL {
                // Assume the recording is assigned to a particular track.
                // If you know the track number (say track 1 for simplicity):
                
                MixerManager.shared.assignRecording(url: url)
                
                // Update the state to playing for that track.
                // (Alternatively, you might update the state from within MixerManager's assignRecording method.)
                NotificationCenter.default.post(name: NSNotification.Name("MixerManagerUpdated"), object: nil)
            }
        }
    }

