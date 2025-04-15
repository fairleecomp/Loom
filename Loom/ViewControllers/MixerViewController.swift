import UIKit
import AVFoundation

class MixerViewController: UIViewController {

    // Dictionary to store the mute state for each track (1...8)
    var trackMuteStates: [Int: Bool] = [:]
    
    // Dictionary to keep references to each track’s UI controls (mute button and status label)
    var trackControls: [Int: (muteButton: UIButton, statusLabel: UILabel)] = [:]
    
    // Save Mix button
    var saveMixButton: UIButton!
    
    // New Mix button to clear all active tracks.
    var newMixButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "8 Track Mixer"
        setupMixerUI()
        setupSaveMixButton()
        setupNewMixButton()
        
        // Initial update of all track statuses.
        updateTrackStatuses()
    }
    
    func setupMixerUI() {
        // Create a vertical stack view to hold track rows.
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Constrain the main stack view to the view’s safe area (leaving space at bottom for the mix buttons).
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                    // leaving room for buttons
        ])
        
        // Create 8 track rows.
        for i in 1...8 {
            let trackRow = createTrackRow(for: i)
            mainStack.addArrangedSubview(trackRow)
            // Initialize the mute state for each track as false.
            trackMuteStates[i] = false
        }
    }
    
    /// Creates a horizontal stack view representing a single mixer track.
    /// - Parameter trackNumber: The track number (1…8)
    /// - Returns: A configured UIView representing the track controls.
    func createTrackRow(for trackNumber: Int) -> UIView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.spacing = 16
        rowStack.alignment = .center
        rowStack.distribution = .equalSpacing
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        let trackLabel = UILabel()
        trackLabel.text = "Track \(trackNumber)"
        trackLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let muteButton = UIButton(type: .system)
        muteButton.setTitle("Mute", for: .normal)
        muteButton.tag = trackNumber
        muteButton.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
        
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.tag = trackNumber
        clearButton.addTarget(self, action: #selector(clearTrack(_:)), for: .touchUpInside)
        
        let statusLabel = UILabel()
        // When the row is created, we set an initial status
        let isOccupied = MixerManager.shared.tracks[trackNumber - 1] != nil
        statusLabel.text = isOccupied ? "Active" : "Empty"
        statusLabel.textColor = .gray
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        rowStack.addArrangedSubview(trackLabel)
        rowStack.addArrangedSubview(muteButton)
        rowStack.addArrangedSubview(clearButton)
        rowStack.addArrangedSubview(statusLabel)
        
        muteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        
        // Save the UI control references.
        trackControls[trackNumber] = (muteButton: muteButton, statusLabel: statusLabel)
        
        return rowStack
    }
    
    func setupSaveMixButton() {
        saveMixButton = UIButton(type: .system)
        saveMixButton.setTitle("Save Mix", for: .normal)
        saveMixButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveMixButton)
        
        NSLayoutConstraint.activate([
            saveMixButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveMixButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        saveMixButton.addTarget(self, action: #selector(saveMixPressed), for: .touchUpInside)
    }
    
    func setupNewMixButton() {
        newMixButton = UIButton(type: .system)
        newMixButton.setTitle("New Mix", for: .normal)
        newMixButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newMixButton)
        
        NSLayoutConstraint.activate([
            newMixButton.centerYAnchor.constraint(equalTo: saveMixButton.centerYAnchor),
            newMixButton.trailingAnchor.constraint(equalTo: saveMixButton.leadingAnchor, constant: -20)
        ])
        
        newMixButton.addTarget(self, action: #selector(newMixPressed), for: .touchUpInside)
    }
    
    // MARK: - UI Update
    
    /// Updates the status labels for all mixer tracks based on whether a track is active.
    @objc func updateTrackStatuses() {
        for (trackNumber, controls) in trackControls {
            let isOccupied = MixerManager.shared.tracks[trackNumber - 1] != nil
            controls.statusLabel.text = isOccupied ? "Active" : "Empty"
        }
    }
    
    // MARK: - Action Handlers
    
    @objc func toggleMute(_ sender: UIButton) {
        let trackNumber = sender.tag
        guard let player = MixerManager.shared.tracks[trackNumber - 1] else {
            print("No recording on Track \(trackNumber) to mute/unmute.")
            return
        }
        let isMuted = trackMuteStates[trackNumber] ?? false
        if isMuted {
            player.play()
            sender.setTitle("Mute", for: .normal)
        } else {
            player.pause()
            sender.setTitle("Unmute", for: .normal)
        }
        trackMuteStates[trackNumber] = !isMuted
        
        // Update the corresponding status if necessary.
        updateTrackStatuses()
    }
    
    @objc func clearTrack(_ sender: UIButton) {
        let trackNumber = sender.tag
        MixerManager.shared.clearTrack(at: trackNumber - 1)
        if let controls = trackControls[trackNumber] {
            controls.statusLabel.text = "Empty"
            controls.muteButton.setTitle("Mute", for: .normal)
        }
        trackMuteStates[trackNumber] = false
        updateTrackStatuses()
    }
    
    @objc func newMixPressed() {
        let trackCount = MixerManager.shared.tracks.count
        for i in 0..<trackCount {
            MixerManager.shared.clearTrack(at: i)
            let trackNumber = i + 1
            if let controls = trackControls[trackNumber] {
                controls.statusLabel.text = "Empty"
                controls.muteButton.setTitle("Mute", for: .normal)
            }
            trackMuteStates[trackNumber] = false
        }
        for player in MixerManager.shared.tracks {
            player?.stop()
        }
        print("All mixer tracks cleared. Ready for a new mix.")
        updateTrackStatuses()
    }
    
    @objc func saveMixPressed() {
        let activeTracks = MixerManager.shared.tracks.compactMap { $0 }
        if activeTracks.isEmpty {
            let alert = UIAlertController(title: "No Audio Tracks", message: "There are no recordings to save. Please record some audio first.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Name Your Mix", message: "Enter a name for your mix", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Mix name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let mixName: String
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                mixName = name
            } else {
                mixName = "Mix Recording \(RecordingManager.shared.recordings.count + 1)"
            }
            for player in MixerManager.shared.tracks {
                player?.stop()
            }
            Task {
                if let url = await self.bounceTracks() {
                    print("Mix saved at: \(url)")
                    let newRecording = Recording(title: mixName, fileURL: url)
                    RecordingManager.shared.addRecording(newRecording)
                    // Update the UI if the Saved Recordings view is visible:
                    DispatchQueue.main.async {
                        self.updateTrackStatuses()
                    }
                } else {
                    print("Failed to save mix.")
                }
            }
        }))
        present(alert, animated: true, completion: nil)
        
    }
    
    /// Combines all active mixer tracks into a single audio file.
    /// - Returns: The URL of the mixed audio file, or nil on failure.
    func bounceTracks() async -> URL? {
        var assets: [AVURLAsset] = []
        for player in MixerManager.shared.tracks {
            if let url = player?.url {
                let asset = AVURLAsset(url: url)
                assets.append(asset)
            }
        }
        
        let composition = AVMutableComposition()
        var maxDuration = CMTime.zero
        
        for asset in assets {
            do {
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                guard let assetTrack = audioTracks.first else { continue }
                if let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    let duration: CMTime = try await asset.load(.duration)
                    let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
                    try compTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
                    if duration > maxDuration {
                        maxDuration = duration
                    }
                }
            } catch {
                print("Error processing asset: \(error)")
                return nil
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            print("Unable to create export session")
            return nil
        }
        
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .m4a
        exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: maxDuration)
        
        do {
            try await exportSession.export(to: exportURL, as: .m4a)
            return exportURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
}
