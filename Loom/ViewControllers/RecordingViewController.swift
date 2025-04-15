import UIKit
import AVFoundation

class RecordingViewController: UIViewController {

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var bpmSlider: UISlider!
    @IBOutlet weak var bpmLabel: UILabel!
    
    var audioRecorder: AVAudioRecorder?
    var recordedFileURL: URL?
    
    // Metronome properties
    var metronomeTimer: Timer?
    var currentBeat: Int = 0
    
    // AVAudioPlayers for metronome sounds
    var accentSoundPlayer: AVAudioPlayer?
    var tickSoundPlayer: AVAudioPlayer?
    
    var metronomeBPM: Float {
        return bpmSlider.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Configure BPM slider
        bpmSlider.minimumValue = 40
        bpmSlider.maximumValue = 240
        bpmSlider.value = 120
        updateBPMLabel()
        
        // Load metronome sound files (ensure accent.wav and tick.wav are added to your project bundle)
        if let accentURL = Bundle.main.url(forResource: "Perc_PracticePad_hi", withExtension: "wav") {
            accentSoundPlayer = try? AVAudioPlayer(contentsOf: accentURL)
            accentSoundPlayer?.prepareToPlay()
        }
        if let tickURL = Bundle.main.url(forResource: "Perc_PracticePad_lo", withExtension: "wav") {
            tickSoundPlayer = try? AVAudioPlayer(contentsOf: tickURL)
            tickSoundPlayer?.prepareToPlay()
        }
    }
    
    @IBAction func bpmSliderChanged(_ sender: UISlider) {
        updateBPMLabel()
    }
    
    func updateBPMLabel() {
        bpmLabel.text = "BPM: \(Int(bpmSlider.value))"
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if audioRecorder == nil {
            startMetronomeCountdown()
        } else {
            stopRecording()
            stopMetronomeCountdown()
            stopOverlayImageAnimation()
        }
    }
    
    // MARK: - Metronome Methods
    
    func startMetronomeCountdown() {
        currentBeat = 0
        let interval = Double(60 / metronomeBPM)
        metronomeTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(metronomeTick), userInfo: nil, repeats: true)
        animateOverlayImage()
    }
    
    @objc func metronomeTick() {
        currentBeat += 1
        if currentBeat == 1 {
            print("Beat 1 (accented)")
            accentSoundPlayer?.play()
        } else {
            print("Beat \(currentBeat)")
            tickSoundPlayer?.play()
        }
        if currentBeat >= 4 {
            stopMetronomeCountdown()
            startRecording()
        }
    }
    
    func stopMetronomeCountdown() {
        metronomeTimer?.invalidate()
        metronomeTimer = nil
        currentBeat = 0
    }
    
    // MARK: - Recording Methods
    
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
        if let url = recordedFileURL {
            MixerManager.shared.assignRecording(url: url)
            NotificationCenter.default.post(name: NSNotification.Name("MixerManagerUpdated"), object: nil)
        }
    }
    
    // MARK: - Overlay Animation Methods
    
    func animateOverlayImage() {
        guard let overlayImageView = recordButton.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.8
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.repeatCount = Float.infinity
        pulseAnimation.autoreverses = true
        overlayImageView.layer.add(pulseAnimation, forKey: "breathe")
    }
    
    func stopOverlayImageAnimation() {
        guard let overlayImageView = recordButton.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        overlayImageView.layer.removeAnimation(forKey: "breathe")
    }
}
