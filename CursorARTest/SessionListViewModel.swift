//
//  SessionListViewModel.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import Foundation

class SessionListViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    
    // MARK: - 會議管理 API
    
    func fetchSessions() {
        isLoading = true
        error = nil
        guard let url = URL(string: Config.API.sessions) else { return }
        URLSession.shared.dataTask(with: url) { data, response, err in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            if let err = err {
                DispatchQueue.main.async {
                    self.error = err.localizedDescription
                }
                return
            }
            guard let data = data else { return }
            do {
                let sessions = try JSONDecoder().decode([Session].self, from: data)
                DispatchQueue.main.async {
                    self.sessions = sessions
                    print("Fetched sessions:", sessions)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    print("Session decode error:", error)
                }
            }
        }.resume()
    }
    
    func createSession(title: String, sessionType: String, participants: [String], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: Config.API.sessions) else {
            completion(false, "無效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sessionData: [String: Any] = [
            "title": title,
            "session_type": sessionType,
            "participants": participants
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: sessionData)
        } catch {
            completion(false, "JSON序列化失敗")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        completion(true, nil)
                        self.fetchSessions() // 重新載入會議列表
                    } else {
                        completion(false, "HTTP錯誤: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "無效的HTTP回應")
                }
            }
        }.resume()
    }
    
    func updateSession(_ session: Session, updates: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: Config.API.session(session.uuid)) else {
            completion(false, "無效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updates)
        } catch {
            completion(false, "JSON序列化失敗")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, nil)
                        self.fetchSessions() // 重新載入會議列表
                    } else {
                        completion(false, "HTTP錯誤: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "無效的HTTP回應")
                }
            }
        }.resume()
    }
    
    func deleteSession(_ session: Session, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: Config.API.session(session.uuid)) else {
            completion(false, "無效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, nil)
                        self.fetchSessions() // 重新載入會議列表
                    } else {
                        completion(false, "HTTP錯誤: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "無效的HTTP回應")
                }
            }
        }.resume()
    }
    
    // MARK: - 語者相關 API
    
    func fetchSpeakerSessions(speakerUUID: String, completion: @escaping ([Session]?, String?) -> Void) {
        guard let url = URL(string: Config.API.speakerSessions(speakerUUID)) else {
            completion(nil, "無效的URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, err in
            if let err = err {
                DispatchQueue.main.async {
                    completion(nil, err.localizedDescription)
                }
                return
            }
            guard let data = data else { 
                DispatchQueue.main.async {
                    completion(nil, "無資料")
                }
                return 
            }
            do {
                let sessions = try JSONDecoder().decode([Session].self, from: data)
                DispatchQueue.main.async {
                    completion(sessions, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error.localizedDescription)
                }
            }
        }.resume()
    }
    
    func fetchSpeakerSpeechLogs(speakerUUID: String, completion: @escaping ([SpeechLog]?, String?) -> Void) {
        guard let url = URL(string: Config.API.speakerSpeechLogs(speakerUUID)) else {
            completion(nil, "無效的URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, err in
            if let err = err {
                DispatchQueue.main.async {
                    completion(nil, err.localizedDescription)
                }
                return
            }
            guard let data = data else { 
                DispatchQueue.main.async {
                    completion(nil, "無資料")
                }
                return 
            }
            do {
                let speechLogs = try JSONDecoder().decode([SpeechLog].self, from: data)
                DispatchQueue.main.async {
                    completion(speechLogs, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error.localizedDescription)
                }
            }
        }.resume()
    }
    
    func fetchSessionSpeechLogs(sessionUUID: String, completion: @escaping ([SpeechLog]?, String?) -> Void) {
        guard let url = URL(string: Config.API.sessionSpeechLogs(sessionUUID)) else {
            completion(nil, "無效的URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, err in
            if let err = err {
                DispatchQueue.main.async {
                    completion(nil, err.localizedDescription)
                }
                return
            }
            guard let data = data else { 
                DispatchQueue.main.async {
                    completion(nil, "無資料")
                }
                return 
            }
            do {
                let speechLogs = try JSONDecoder().decode([SpeechLog].self, from: data)
                DispatchQueue.main.async {
                    completion(speechLogs, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error.localizedDescription)
                }
            }
        }.resume()
    }
}