import UIKit
import AVFoundation

class SavedRecordingsViewController: UITableViewController {
    
    // AVAudioPlayer to handle playback (if needed)
    var playbackPlayer: AVAudioPlayer?
    
    // Use the recordings from the RecordingManager singleton.
    var recordings: [Recording] {
        return RecordingManager.shared.recordings
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Saved Recordings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecordingCell")
        
        // Observe updates so that if recordings change (i.e. after deletion or renaming) we refresh.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateRecordings),
                                               name: NSNotification.Name("RecordingManagerUpdated"),
                                               object: nil)
    }
    
    @objc func updateRecordings() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1  // Single section
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)
        let recording = recordings[indexPath.row]
        cell.textLabel?.text = recording.title
        return cell
    }
    
    // Enable swipe-to-delete.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            RecordingManager.shared.removeRecording(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // Add a trailing swipe action for "Rename".
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
                            -> UISwipeActionsConfiguration? {
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            self?.deleteRecording(at: indexPath)
            completionHandler(true)
        }
        
                                
        // Rename action
        let renameAction = UIContextualAction(style: .normal, title: "Rename") { [weak self] (action, view, completionHandler) in
            self?.promptForRename(at: indexPath)
            completionHandler(true)
        }
        renameAction.backgroundColor = .blue
        
        // Return both actions – they will appear side by side on swipe.
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
        return configuration
    }
    
    // When a cell is tapped, play the recording.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
        playRecording(recording)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Plays the recording using AVAudioPlayer.
    func playRecording(_ recording: Recording) {
        if let player = playbackPlayer, player.isPlaying {
            player.stop()
        }
        do {
            playbackPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            playbackPlayer?.prepareToPlay()
            playbackPlayer?.play()
            print("Playing: \(recording.title)")
        } catch {
            print("Error playing recording: \(error)")
        }
    }
    
    /// Prompts the user to rename a recording.
    /// Prompts the user to rename a recording.
    func promptForRename(at indexPath: IndexPath) {
        let recording = recordings[indexPath.row]
        let alert = UIAlertController(title: "Rename Recording", message: "Enter a new name for this recording", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = recording.title
            textField.placeholder = "New name"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                RecordingManager.shared.renameRecording(at: indexPath.row, newTitle: newName)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func deleteRecording(at indexPath: IndexPath) {
        RecordingManager.shared.removeRecording(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
