import UIKit
import AVFoundation

class MainViewController: UIViewController, AVAudioPlayerDelegate, UITextViewDelegate {
    // UI
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var tagField: UITextField!
    @IBOutlet weak var waveformView: WaveformView!

    // Audio
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    var currentFileURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }
        Task {
            await requestMicrophonePermission()
        }
        
        notesTextView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        notesTextView.textColor = UIColor.darkText
        notesTextView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func recordTapped(_ sender: UIButton) {
        if recorder?.isRecording == true {
            stopRecording()
            recordButton.setImage(UIImage(systemName: "timelapse"), for: .normal)
        } else {
            startRecording()
            recordButton.setImage(UIImage(systemName: "circle.slash"), for: .normal)
        }
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        guard let url = currentFileURL else { return }

        let alert = UIAlertController(title: "Save Recording", message: "Enter a title for your idea:", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Recording Name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let title = alert.textFields?.first?.text ?? "Untitled Idea"
            let notes = self.notesTextView.text ?? ""

            // Move file to permanent location
            let fileName = UUID().uuidString + ".m4a"
            let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

            do {
                try FileManager.default.copyItem(at: url, to: destinationURL)
                let recording = Recording(title: title, fileURL: destinationURL, notes: notes, tags: "")
                RecordingManager.shared.addRecording(recording)

                self.notesTextView.text = ""
                print("Recording saved!")

            } catch {
                print("Failed to save recording: \(error)")
            }
        }))
        present(alert, animated: true)
        return
    }

    private func startRecording() {
        let filename = UUID().uuidString + ".m4a"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        
        
        do {
            recorder = try AVAudioRecorder(url: path, settings: settings)
            currentFileURL = path
            recorder?.isMeteringEnabled = true
            recorder?.prepareToRecord()
            recorder?.record()

            if let waveformView = waveformView {
                waveformView.recorder = recorder
                waveformView.startMonitoring()
            } else {
                print("❌ waveformView is nil")
            }
        } catch {
            print("❌ Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        waveformView.stopMonitoring()
        recorder?.stop()
        recorder = nil
    }

    private func requestMicrophonePermission() async {
        await AVAudioApplication.requestRecordPermission()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
    
    @IBAction func ideasTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let ideasVC = storyboard.instantiateViewController(withIdentifier: "IdeasListViewController") as? IdeasListViewController {
            navigationController?.pushViewController(ideasVC, animated: true)
        }
    }
    @IBAction func playTapped(_ sender: UIButton) {
        guard let url = currentFileURL else {
            print("❌ No recording available to play")
            return
        }

        // Extra check
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist at: \(url.path)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()

            if player?.play() == true {
                playButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
                print("✅ Playback started")
            } else {
                print("❌ Playback failed to start")
            }

        } catch {
            print("❌ Failed to play audio: \(error)")
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
