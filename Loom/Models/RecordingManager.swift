import Foundation

struct Recording {
    var title: String
    let fileURL: URL
    var notes: String
    var tags: String
}

class RecordingManager {
    static let shared = RecordingManager()
    private(set) var recordings: [Recording] = []

    private init() {}

    func addRecording(_ recording: Recording) {
        recordings.append(recording)
        NotificationCenter.default.post(name: NSNotification.Name("RecordingsUpdated"), object: nil)
    }

    func deleteRecording(at index: Int) {
        guard recordings.indices.contains(index) else {
            print("❌ Tried to delete recording at invalid index: \(index)")
            return
        }
        recordings.remove(at: index)
        NotificationCenter.default.post(name: NSNotification.Name("RecordingsUpdated"), object: nil)
    }
    
    func renameRecording(at index: Int, newTitle: String) {
        guard recordings.indices.contains(index) else { return }
        recordings[index].title = newTitle
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
    
    func updateNotes(at index: Int, newNotes: String) {
        guard recordings.indices.contains(index) else { return }
        recordings[index].notes = newNotes
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
}
