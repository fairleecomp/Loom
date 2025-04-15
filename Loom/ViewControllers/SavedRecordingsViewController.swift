import UIKit

class SavedRecordingsViewController: UITableViewController {
    
    // For simplicity, this example uses a static array.
    // In a real app, you might fetch from a RecordingManager singleton.
    var recordings: [String] = ["Recording 1", "Recording 2", "Recording 3"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Saved Recordings"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecordingCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)
        cell.textLabel?.text = recordings[indexPath.row]
        return cell
    }
    
    // Optional: handle selection to play or view details of a recording.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected: \(recordings[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
