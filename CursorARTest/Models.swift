//
//  Models.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import Foundation

// MARK: - Speaker Model
struct Speaker: Codable, Identifiable {
    var id: String { uuid }
    let uuid: String
    let speaker_id: Int?
    let full_name: String?
    let nickname: String?
    let gender: String?
    let created_at: String?
    let last_active_at: String?
    let meet_count: Int?
    let meet_days: Int?
    let voiceprint_ids: [String]
    let first_audio: String?
}

// MARK: - Session Model
struct Session: Codable, Identifiable, Hashable {
    var id: String { uuid }
    let uuid: String
    let session_id: String?
    let session_type: String?
    let title: String?
    let start_time: String?
    let end_time: String?
    let summary: String?
    let participants: [String]?
    
}

// MARK: - SpeechLog Model
struct SpeechLog: Codable, Identifiable {
    var id: String { uuid }
    let uuid: String
    let content: String?
    let timestamp: String?
    let confidence: Double?
    let duration: Double?
    let language: String?
    let speaker: String?
    let session: String?
}

// MARK: - People Store Model
class PeopleStore: ObservableObject {
    @Published var people: [CGPoint] = []
} 
