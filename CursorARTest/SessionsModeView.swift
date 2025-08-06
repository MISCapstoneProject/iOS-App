//
//  SessionsModeView.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import SwiftUI

struct SessionsModeView: View {
    @StateObject private var sessionListVM = SessionListViewModel()
    @State private var selectedSession: Session? = nil
    @State private var showingCreateSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if sessionListVM.isLoading {
                    ProgressView("載入中...")
                } else if let error = sessionListVM.error {
                    Text("錯誤：\(error)")
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(sessionListVM.sessions) { session in
                                SessionCardView(session: session) {
                                    selectedSession = session
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("會議管理")
            .navigationBarItems(
                leading: Button("重新載入") {
                    sessionListVM.fetchSessions()
                },
                trailing: Button("新增會議") {
                    showingCreateSheet = true
                }
            )
            .onAppear {
                sessionListVM.fetchSessions()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session, sessionListVM: sessionListVM)
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSessionView(sessionListVM: sessionListVM)
            }
        }
    }
}

struct SessionCardView: View {
    let session: Session
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title ?? "未命名會議")
                    .font(.headline)
                    .foregroundColor(.primary)
                HStack(spacing: 16) {
                    if let sessionId = session.session_id {
                        Text("ID: \(sessionId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let sessionType = session.session_type {
                        Text("類型: \(sessionType)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if let startTime = session.start_time {
                    Text("開始時間: \(startTime)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                if let participants = session.participants, !participants.isEmpty {
                    Text("參與者: \(participants.count) 人")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                Text("UUID: \(session.uuid)")
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

struct SessionDetailView: View {
    let session: Session
    @ObservedObject var sessionListVM: SessionListViewModel
    @State private var showingEditSheet = false
    @State private var speechLogs: [SpeechLog] = []
    @State private var isLoadingSpeechLogs = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title ?? "未命名會議")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let sessionId = session.session_id {
                        Text("會議ID: \(sessionId)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let sessionType = session.session_type {
                        Text("會議類型: \(sessionType)")
                            .font(.subheadline)
                    }
                    
                    if let startTime = session.start_time {
                        Text("開始時間: \(startTime)")
                            .font(.subheadline)
                    }
                    
                    if let endTime = session.end_time {
                        Text("結束時間: \(endTime)")
                            .font(.subheadline)
                    }
                    
                    if let summary = session.summary {
                        Text("摘要: \(summary)")
                            .font(.subheadline)
                    }
                    
                    if let participants = session.participants, !participants.isEmpty {
                        Text("參與者: \(participants.joined(separator: ", "))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Text("UUID: \(session.uuid)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // 語音記錄
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("語音記錄")
                            .font(.headline)
                        Spacer()
                        Button("重新載入") {
                            loadSpeechLogs()
                        }
                        .font(.caption)
                    }
                    
                    if isLoadingSpeechLogs {
                        ProgressView("載入語音記錄...")
                    } else if speechLogs.isEmpty {
                        Text("無語音記錄")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(speechLogs) { log in
                            SpeechLogView(speechLog: log)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                HStack {
                    Button("編輯會議") {
                        showingEditSheet = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("刪除會議") {
                        deleteSession()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("會議詳情")
        .sheet(isPresented: $showingEditSheet) {
            EditSessionView(session: session, sessionListVM: sessionListVM)
        }
        .onAppear {
            loadSpeechLogs()
        }
    }
    
    private func loadSpeechLogs() {
        isLoadingSpeechLogs = true
        sessionListVM.fetchSessionSpeechLogs(sessionUUID: session.uuid) { logs, error in
            isLoadingSpeechLogs = false
            if let error = error {
                print("載入語音記錄失敗: \(error)")
            } else {
                speechLogs = logs ?? []
            }
        }
    }
    
    private func deleteSession() {
        sessionListVM.deleteSession(session) { success, error in
            if success {
                // 關閉詳情頁面
            } else {
                print("刪除會議失敗: \(error ?? "未知錯誤")")
            }
        }
    }
}

struct SpeechLogView: View {
    let speechLog: SpeechLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let content = speechLog.content {
                Text(content)
                    .font(.body)
            }
            HStack {
                if let timestamp = speechLog.timestamp {
                    Text(timestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let confidence = speechLog.confidence {
                    Text("信心度: \(String(format: "%.2f", confidence))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let duration = speechLog.duration {
                    Text("時長: \(String(format: "%.1f", duration))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

struct CreateSessionView: View {
    @ObservedObject var sessionListVM: SessionListViewModel
    @State private var title = ""
    @State private var sessionType = ""
    @State private var participants = ""
    @State private var isCreating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("會議資訊")) {
                    TextField("會議標題", text: $title)
                    TextField("會議類型", text: $sessionType)
                    TextField("參與者UUID（用逗號分隔）", text: $participants)
                }
                
                Section {
                    Button(action: createSession) {
                        if isCreating {
                            ProgressView("建立中...")
                        } else {
                            Text("建立會議")
                        }
                    }
                    .disabled(isCreating || title.isEmpty)
                }
            }
            .navigationTitle("新增會議")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("建立") {
                    createSession()
                }
                .disabled(isCreating || title.isEmpty)
            )
            .alert("建立結果", isPresented: $showAlert) {
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
    
    private func createSession() {
        isCreating = true
        
        let participantList = participants.isEmpty ? [] : participants.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        sessionListVM.createSession(title: title, sessionType: sessionType, participants: participantList) { success, error in
            isCreating = false
            alertMessage = success ? "會議建立成功" : (error ?? "建立失敗")
            showAlert = true
        }
    }
}

struct EditSessionView: View {
    let session: Session
    @ObservedObject var sessionListVM: SessionListViewModel
    @State private var title = ""
    @State private var sessionType = ""
    @State private var summary = ""
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("會議資訊")) {
                    TextField("會議標題", text: $title)
                    TextField("會議類型", text: $sessionType)
                    TextField("會議摘要", text: $summary)
                }
                
                Section {
                    Button(action: updateSession) {
                        if isUpdating {
                            ProgressView("更新中...")
                        } else {
                            Text("更新會議")
                        }
                    }
                    .disabled(isUpdating)
                }
            }
            .navigationTitle("編輯會議")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("儲存") {
                    updateSession()
                }
                .disabled(isUpdating)
            )
            .onAppear {
                title = session.title ?? ""
                sessionType = session.session_type ?? ""
                summary = session.summary ?? ""
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
    
    private func updateSession() {
        isUpdating = true
        
        var updates: [String: Any] = [:]
        if !title.isEmpty { updates["title"] = title }
        if !sessionType.isEmpty { updates["session_type"] = sessionType }
        if !summary.isEmpty { updates["summary"] = summary }
        
        sessionListVM.updateSession(session, updates: updates) { success, error in
            isUpdating = false
            alertMessage = success ? "更新成功" : (error ?? "更新失敗")
            showAlert = true
        }
    }
} 