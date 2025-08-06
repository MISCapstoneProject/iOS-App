//
//  SpeakerListViewModel.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import Foundation

class SpeakerListViewModel: ObservableObject {
    @Published var speakers: [Speaker] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var selectedSpeaker: Speaker? = nil
  
    func fetchSpeakers() {
        isLoading = true
        error = nil
        guard let url = URL(string: Config.API.speakers) else { return }
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
                let speakers = try JSONDecoder().decode([Speaker].self, from: data)
                DispatchQueue.main.async {
                    self.speakers = speakers
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func updateSpeaker(_ speaker: Speaker, updates: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(Config.API.speakers)/\(speaker.uuid)") else {
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
                        self.fetchSpeakers() // 重新載入資料
                    } else {
                        completion(false, "HTTP錯誤: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "無效的HTTP回應")
                }
            }
        }.resume()
    }
} 