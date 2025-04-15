import UIKit
import AVFoundation

class MixerViewController: UIViewController {
    
    // Dictionary to store the mute state for each track (1...8)
    var trackMuteStates: [Int: Bool] = [:]
    
    // Dictionary to keep references to each track’s UI controls:
    // We'll now store a mute button and a status indicator view.
    var trackControls: [Int: (muteButton: UIButton, statusIndicator: UIView)] = [:]
    
    // Bottom row height constraints for each track (for toggling extra controls)
    var trackBottomHeightConstraints: [Int: NSLayoutConstraint] = [:]
    
    // Buttons at the bottom
    var saveMixButton: UIButton!
    var newMixButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "8 Track Mixer"
        view.backgroundColor = UIColor.black
        setupMixerUI()
        setupBottomButtons()
        updateTrackStatuses()
    }
    
    // MARK: - Setup Methods
    
    func setupMixerUI() {
        // Create a vertical stack to hold the track rows.
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Constrain mainStack to the safe area. Let its height be determined by content.
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
        
        // Create 8 track rows.
        for i in 1...8 {
            let trackRow = createTrackRow(for: i)
            mainStack.addArrangedSubview(trackRow)
            trackMuteStates[i] = false
        }
    }
    // MARK: - TRACK ROW
    func createTrackRow(for trackNumber: Int) -> UIView {
        // Main vertical stack for this track row.
        let rowStack = UIStackView()
        rowStack.axis = .vertical
        rowStack.spacing = 8
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        // Top Row (always visible): holds label, mute, clear, and status indicator.
        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.spacing = 16
        topRow.alignment = .center
        topRow.distribution = .equalSpacing
        topRow.translatesAutoresizingMaskIntoConstraints = false
        topRow.backgroundColor = UIColor.black
        topRow.layer.cornerRadius = 20
        topRow.layer.masksToBounds = true
        topRow.layer.shadowColor = UIColor.black.cgColor
        topRow.layer.shadowOpacity = 0.1
        topRow.layer.shadowOffset = CGSize(width: 0, height: 2)
        topRow.layer.shadowRadius = 4
        topRow.tag = trackNumber  // Use tag to identify track

        let trackLabel = UILabel()
        trackLabel.text = "Track \(trackNumber)"
        trackLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let muteButton = UIButton(type: .system)
        muteButton.setTitle("Mute", for: .normal)
        muteButton.tag = trackNumber
        muteButton.addTarget(self, action: #selector(toggleMute(_:)), for: .touchUpInside)
        muteButton.backgroundColor = UIColor.systemBlue
        muteButton.setTitleColor(.white, for: .normal)
        muteButton.layer.cornerRadius = 5
        muteButton.clipsToBounds = true

        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.tag = trackNumber
        clearButton.addTarget(self, action: #selector(clearTrack(_:)), for: .touchUpInside)
        clearButton.backgroundColor = UIColor.systemRed
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.layer.cornerRadius = 5
        clearButton.clipsToBounds = true

        let statusIndicator = UIView()
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        let isOccupied = MixerManager.shared.tracks[trackNumber - 1] != nil
        statusIndicator.backgroundColor = isOccupied ? UIColor.systemGreen : UIColor.lightGray
        statusIndicator.layer.cornerRadius = 6  // For a 12x12 circle
        statusIndicator.clipsToBounds = true

        topRow.addArrangedSubview(trackLabel)
        topRow.addArrangedSubview(muteButton)
        topRow.addArrangedSubview(clearButton)
        topRow.addArrangedSubview(statusIndicator)

        muteButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        clearButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        NSLayoutConstraint.activate([
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12)
        ])

        // Add a tap gesture to topRow to toggle fader controls.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleTrackOptions(_:)))
        topRow.isUserInteractionEnabled = true
        topRow.addGestureRecognizer(tapGesture)

        // Bottom Row (volume and pan sliders)
        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.spacing = 10
        bottomRow.alignment = .center
        bottomRow.distribution = .fillEqually
        bottomRow.translatesAutoresizingMaskIntoConstraints = false

        let volumeSlider = UISlider()
        volumeSlider.minimumValue = 0.0
        volumeSlider.maximumValue = 1.0
        volumeSlider.value = 1.0
        volumeSlider.tag = trackNumber
        volumeSlider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)

        let panSlider = UISlider()
        panSlider.minimumValue = -1.0
        panSlider.maximumValue = 1.0
        panSlider.value = 0.0
        panSlider.tag = trackNumber
        panSlider.addTarget(self, action: #selector(panSliderChanged(_:)), for: .valueChanged)

        bottomRow.addArrangedSubview(volumeSlider)
        bottomRow.addArrangedSubview(panSlider)

        // Collapse bottomRow using a height constraint.
        let bottomHeightConstraint = bottomRow.heightAnchor.constraint(equalToConstant: 0)
        bottomHeightConstraint.isActive = true
        // Also explicitly hide the bottom row to ensure it's not visible initially.
        bottomRow.isHidden = true
        trackBottomHeightConstraints[trackNumber] = bottomHeightConstraint

        // Add topRow and bottomRow to rowStack.
        rowStack.addArrangedSubview(topRow)
        rowStack.addArrangedSubview(bottomRow)

        // Fix the top row height.
        topRow.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Save control references.
        trackControls[trackNumber] = (muteButton: muteButton, statusIndicator: statusIndicator)

        // Optionally set a fixed overall rowStack height if desired (or let it be determined by content).
        // rowStack.heightAnchor.constraint(equalToConstant: 80).isActive = true

        return rowStack
    }
    
    // MARK: - Instance Methods for UI Actions
    
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
        updateTrackStatuses()
    }
    
    @objc func clearTrack(_ sender: UIButton) {
        let trackNumber = sender.tag
        MixerManager.shared.clearTrack(at: trackNumber - 1)
        if let controls = trackControls[trackNumber] {
            controls.statusIndicator.backgroundColor = UIColor.lightGray
            controls.muteButton.setTitle("Mute", for: .normal)
        }
        trackMuteStates[trackNumber] = false
        updateTrackStatuses()
    }
    
    @objc func volumeSliderChanged(_ sender: UISlider) {
        let trackNumber = sender.tag
        if let player = MixerManager.shared.tracks[trackNumber - 1] {
            player.volume = sender.value
            print("Track \(trackNumber) volume: \(sender.value)")
        }
    }
    
    @objc func panSliderChanged(_ sender: UISlider) {
        let trackNumber = sender.tag
        if let player = MixerManager.shared.tracks[trackNumber - 1] {
            player.pan = sender.value
            print("Track \(trackNumber) pan: \(sender.value)")
        }
    }
    
    @objc func toggleTrackOptions(_ gesture: UITapGestureRecognizer) {
        guard let topRow = gesture.view as? UIStackView,
              let rowStack = topRow.superview as? UIStackView,
              rowStack.arrangedSubviews.count >= 2,
              let bottomRow = rowStack.arrangedSubviews[1] as? UIStackView,
              let bottomHeightConstraint = trackBottomHeightConstraints[topRow.tag] else { return }
        
        if bottomRow.isHidden {
            // Expand: unhide and animate height to 44.
            bottomRow.isHidden = false
            bottomHeightConstraint.constant = 44
            UIView.animate(withDuration: 0.3) {
                rowStack.layoutIfNeeded()
            }
        } else {
            // Collapse: animate height to 0 then hide.
            bottomHeightConstraint.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                rowStack.layoutIfNeeded()
            }) { _ in
                bottomRow.isHidden = true
            }
        }
    }
    // MARK: - Bottom Buttons Setup
    
    func setupBottomButtons() {
        // Create a horizontal stack view for both New Mix and Save Mix buttons.
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 20
        buttonStack.alignment = .center
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        // Configure Save Mix button.
        var saveConfig = UIButton.Configuration.filled()
        saveConfig.title = "Save Mix"
        saveConfig.image = UIImage(systemName: "square.and.arrow.down")
        saveConfig.imagePadding = 8
        saveConfig.baseBackgroundColor = UIColor.systemGreen
        saveConfig.baseForegroundColor = UIColor.white
        saveConfig.cornerStyle = .medium
        saveMixButton = UIButton(type: .system)
        saveMixButton.configuration = saveConfig
        saveMixButton.layer.cornerRadius = 16
        saveMixButton.clipsToBounds = true
        saveMixButton.addTarget(self, action: #selector(saveMixPressed), for: .touchUpInside)
        
        // Configure New Mix button.
        var newConfig = UIButton.Configuration.filled()
        newConfig.title = "New Mix"
        newConfig.image = UIImage(systemName: "plus.circle.fill")
        newConfig.imagePadding = 8
        newConfig.baseBackgroundColor = UIColor.systemOrange
        newConfig.baseForegroundColor = UIColor.white
        newConfig.cornerStyle = .medium
        newMixButton = UIButton(type: .system)
        newMixButton.configuration = newConfig
        newMixButton.layer.cornerRadius = 16
        newMixButton.clipsToBounds = true
        newMixButton.addTarget(self, action: #selector(newMixPressed), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(newMixButton)
        buttonStack.addArrangedSubview(saveMixButton)
        
        NSLayoutConstraint.activate([
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.widthAnchor.constraint(equalToConstant: 320),  // Adjust width as needed
            buttonStack.heightAnchor.constraint(equalToConstant: 80)   // Adjust height as needed
        ])
    }
    
    // MARK: - UI Update
    
    @objc func updateTrackStatuses() {
        for (trackNumber, controls) in trackControls {
            let isOccupied = MixerManager.shared.tracks[trackNumber - 1] != nil
            controls.statusIndicator.backgroundColor = isOccupied ? UIColor.systemGreen : UIColor.lightGray
            print("Track \(trackNumber) is \(isOccupied ? "Active" : "Empty")")
        }
    }
    
    // MARK: - Bottom Button Actions
    
    @objc func newMixPressed() {
        let trackCount = MixerManager.shared.tracks.count
        for i in 0..<trackCount {
            MixerManager.shared.clearTrack(at: i)
            let trackNumber = i + 1
            if let controls = trackControls[trackNumber] {
                controls.statusIndicator.backgroundColor = UIColor.lightGray
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
