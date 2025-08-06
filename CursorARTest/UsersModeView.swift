//
//  UsersModeView.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import SwiftUI

struct UsersModeView: View {
    @StateObject private var speakerListVM = SpeakerListViewModel()
    @State private var selectedSpeaker: Speaker? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if speakerListVM.isLoading {
                    ProgressView("載入中...")
                } else if let error = speakerListVM.error {
                    Text("錯誤：\(error)")
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(speakerListVM.speakers) { speaker in
                                SpeakerCardView(speaker: speaker) {
                                    selectedSpeaker = speaker
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("語者列表")
            .navigationBarItems(trailing: Button("重新載入") {
                speakerListVM.fetchSpeakers()
            })
            .onAppear {
                speakerListVM.fetchSpeakers()
            }
            .sheet(item: $selectedSpeaker) { speaker in
                SpeakerDetailView(speaker: speaker, speakerListVM: speakerListVM)
            }
        }
    }
}

struct SpeakerCardView: View {
    let speaker: Speaker
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(speaker.full_name ?? speaker.nickname ?? String(speaker.uuid.prefix(8)))
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack(spacing: 16) {
                    if let gender = speaker.gender {
                        Text("性別: \(gender)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let meetCount = speaker.meet_count {
                        Text("見面次數: \(meetCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let meetDays = speaker.meet_days {
                        Text("見面天數: \(meetDays)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if let lastActive = speaker.last_active_at {
                    Text("最後活躍: \(lastActive)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                if !speaker.voiceprint_ids.isEmpty {
                    Text("語音樣本數: \(speaker.voiceprint_ids.count)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                Text("ID: \(speaker.uuid)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SpeakerDetailView: View {
    let speaker: Speaker
    @ObservedObject var speakerListVM: SpeakerListViewModel
    @State private var showingEditSheet = false
    
    // 從 speakerListVM 中獲取最新的語者資料
    private var currentSpeaker: Speaker? {
        speakerListVM.speakers.first { $0.uuid == speaker.uuid }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentSpeaker?.full_name ?? currentSpeaker?.nickname ?? "未命名")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let gender = currentSpeaker?.gender {
                        Text("性別: \(gender)")
                            .font(.subheadline)
                    }
                    
                    if let meetCount = currentSpeaker?.meet_count {
                        Text("見面次數: \(meetCount)")
                            .font(.subheadline)
                    }
                    
                    if let meetDays = currentSpeaker?.meet_days {
                        Text("見面天數: \(meetDays)")
                            .font(.subheadline)
                    }
                    
                    if let createdAt = currentSpeaker?.created_at {
                        Text("建立時間: \(createdAt)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastActive = currentSpeaker?.last_active_at {
                        Text("最後活躍: \(lastActive)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let voiceprintIds = currentSpeaker?.voiceprint_ids, !voiceprintIds.isEmpty {
                        Text("語音樣本數: \(voiceprintIds.count)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("ID: \(currentSpeaker?.uuid ?? speaker.uuid)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Button("編輯資料") {
                    showingEditSheet = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("語者詳情")
        .sheet(isPresented: $showingEditSheet) {
            if let currentSpeaker = currentSpeaker {
                SpeakerEditView(speaker: currentSpeaker, speakerListVM: speakerListVM)
            }
        }
    }
}

struct SpeakerEditView: View {
    let speaker: Speaker
    @ObservedObject var speakerListVM: SpeakerListViewModel
    @State private var fullName: String = ""
    @State private var nickname: String = ""
    @State private var gender: String = ""
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本資料")) {
                    TextField("全名", text: $fullName)
                    TextField("暱稱", text: $nickname)
                    TextField("性別", text: $gender)
                }
                
                Section {
                    Button(action: updateSpeaker) {
                        if isUpdating {
                            ProgressView("更新中...")
                        } else {
                            Text("更新資料")
                        }
                    }
                    .disabled(isUpdating)
                }
            }
            .navigationTitle("編輯語者")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("儲存") {
                    updateSpeaker()
                }
                .disabled(isUpdating)
            )
            .onAppear {
                fullName = speaker.full_name ?? ""
                nickname = speaker.nickname ?? ""
                gender = speaker.gender ?? ""
            }
            .alert("更新結果", isPresented: $showAlert) {
                Button("確定") {
                    if alertMessage.contains("成功") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateSpeaker() {
        isUpdating = true
        
        var updates: [String: Any] = [:]
        if !fullName.isEmpty { updates["full_name"] = fullName }
        if !nickname.isEmpty { updates["nickname"] = nickname }
        if !gender.isEmpty { updates["gender"] = gender }
        
        speakerListVM.updateSpeaker(speaker, updates: updates) { success, error in
            isUpdating = false
            alertMessage = success ? "更新成功" : (error ?? "更新失敗")
            showAlert = true
        }
    }
} 
