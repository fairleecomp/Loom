//
//  recordingModel.swift
//  Loom
//
//  Created by Lee Reddy on 13/04/2025.
//

import Foundation

struct Recording {
    let title: String
    let fileURL: URL
}

class RecordingManager {
    static let shared = RecordingManager()
    private init() {}
    
    var recordings: [Recording] = []
}
