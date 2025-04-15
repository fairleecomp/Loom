import UIKit
import AVFoundation

class IdeasListViewController: UITableViewController {
    var recordings: [Recording] {
        return RecordingManager.shared.recordings
    }

    var player: AVAudioPlayer?
    var expandedIndexPaths: Set<IndexPath> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPress)
    }

    @objc func update() {
        tableView.reloadData()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        let location = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else { return }

        if expandedIndexPaths.contains(indexPath) {
            expandedIndexPaths.remove(indexPath)
        } else {
            expandedIndexPaths.insert(indexPath)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)
        let item = recordings[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.numberOfLines = expandedIndexPaths.contains(indexPath) ? 0 : 1
        cell.detailTextLabel?.text = item.notes
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = recordings[indexPath.row]
        
        if let player = player, player.isPlaying {
            player.stop()
        } else {
            player = try? AVAudioPlayer(contentsOf: item.fileURL)
            player?.play()
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            RecordingManager.shared.deleteRecording(at: indexPath.row)
            completionHandler(true)
            self.tableView.reloadData()
        }

        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, completionHandler in
            let recording = self.recordings[indexPath.row]
            
            let editVC = UIViewController()
            editVC.modalPresentationStyle = .formSheet
            editVC.view.backgroundColor = .systemBackground

            let titleField = UITextField(frame: CGRect(x: (editVC.view.frame.width - 300) / 2, y: 40, width: 300, height: 40))
            titleField.borderStyle = .roundedRect
            titleField.text = recording.title
            titleField.placeholder = "Title"
            titleField.textAlignment = .center

            let notesView = UITextView(frame: CGRect(x: (editVC.view.frame.width - 300) / 2, y: 100, width: 300, height: 200))
            notesView.layer.borderWidth = 1
            notesView.layer.borderColor = UIColor.systemGray4.cgColor
            notesView.layer.cornerRadius = 8
            notesView.font = UIFont.systemFont(ofSize: 16)
            notesView.text = recording.notes
            notesView.textAlignment = .center

            let saveButton = UIButton(type: .system)
            saveButton.setTitle("Save", for: .normal)
            saveButton.frame = CGRect(x: 20, y: 320, width: 300, height: 44)
            saveButton.addTarget(self, action: #selector(self.saveEdits(_:)), for: .touchUpInside)
            saveButton.tag = indexPath.row
            saveButton.accessibilityHint = "\(indexPath.row)" // store index

            editVC.view.addSubview(titleField)
            editVC.view.addSubview(notesView)
            editVC.view.addSubview(saveButton)

            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.frame = CGRect(x: 20, y: 380, width: 300, height: 44)
            cancelButton.addTarget(self, action: #selector(self.cancelEdit), for: .touchUpInside)

            editVC.view.addSubview(cancelButton)

            editVC.view.tag = indexPath.row
            editVC.view.accessibilityElements = [titleField, notesView]

            editVC.modalTransitionStyle = .coverVertical
            self.present(editVC, animated: true)
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    @objc func saveEdits(_ sender: UIButton) {
        guard let editVC = self.presentedViewController,
              let elements = editVC.view.accessibilityElements,
              let titleField = elements[0] as? UITextField,
              let notesView = elements[1] as? UITextView else { return }

        let index = sender.tag
        guard index >= 0 && index < RecordingManager.shared.recordings.count else {
            print("❌ Index \(index) out of range")
            self.dismiss(animated: true)
            return
        }
        let newTitle = titleField.text ?? ""
        let newNotes = notesView.text ?? ""

        RecordingManager.shared.renameRecording(at: index, newTitle: newTitle)
        RecordingManager.shared.updateNotes(at: index, newNotes: newNotes)

        editVC.dismiss(animated: true)
    }

    @objc func cancelEdit() {
        self.dismiss(animated: true)
    }
}
