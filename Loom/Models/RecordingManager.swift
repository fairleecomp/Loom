import Foundation

// MARK: - Recording Model

/// Represents a single audio recording.
struct Recording {
    var title: String
    let fileURL: URL
}

// MARK: - Recording Manager

/// A singleton manager to store and manage recordings.
class RecordingManager {
    static let shared = RecordingManager()
    
    /// The array of recordings.
    private(set) var recordings: [Recording] = []
    
    // Private initializer prevents external instantiation.
    private init() { }
    
    /// Adds a new recording to the manager.
    /// - Parameter recording: The recording to add.
    func addRecording(_ recording: Recording) {
        recordings.append(recording)
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
    
    /// Removes the recording at the specified index.
    /// - Parameter index: The index of the recording to remove.
    func removeRecording(at index: Int) {
        guard recordings.indices.contains(index) else { return }
        recordings.remove(at: index)
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
    
    /// Removes all recordings from the manager.
    func clearRecordings() {
        recordings.removeAll()
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
    
    /// Renames the recording at the specified index.
    /// - Parameters:
    ///   - index: The index of the recording to rename.
    ///   - newTitle: The new title for the recording.
    func renameRecording(at index: Int, newTitle: String) {
        guard recordings.indices.contains(index) else { return }
        let oldRecording = recordings[index]
        recordings[index] = Recording(title: newTitle, fileURL: oldRecording.fileURL)
        NotificationCenter.default.post(name: NSNotification.Name("RecordingManagerUpdated"), object: nil)
    }
}
