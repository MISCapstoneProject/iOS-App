//
//  Config.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import Foundation

struct Config {
    static let baseURL = "https://programmer-kept-thumbzilla-ignore.trycloudflare.com"
    
    struct API {
        static let speakers = "\(baseURL)/speakers"
        static let transcribe = "\(baseURL)/transcribe"
        static let stream: String = {
                let wsPath = "/ws/stream"
                return baseURL
                    .replacingOccurrences(of: "https://", with: "wss://")
                    .replacingOccurrences(of: "http://",  with: "ws://")
                    + wsPath
            }()
        static let sessions = "\(baseURL)/sessions"
        
        static func speaker(_ uuid: String) -> String {
            return "\(speakers)/\(uuid)"
        }
        
        static func speakerSessions(_ uuid: String) -> String {
            return "\(speakers)/\(uuid)/sessions"
        }
        
        static func speakerSpeechLogs(_ uuid: String) -> String {
            return "\(speakers)/\(uuid)/speechlogs"
        }
        
        static func session(_ uuid: String) -> String {
            return "\(sessions)/\(uuid)"
        }
        
        static func sessionSpeechLogs(_ uuid: String) -> String {
            return "\(sessions)/\(uuid)/speechlogs"
        }
    }
}

