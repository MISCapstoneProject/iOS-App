//
//  SilentModeView.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import SwiftUI

struct SilentModeView: View {
    @StateObject private var recordingVM = RecordingViewModel()
    @StateObject private var sessionListVM = SessionListViewModel()
    @State private var selectedSession: Session? = nil
    @State private var showingCreateSheet = false

    var body: some View {
        VStack(spacing: 16) {
            // 會議選擇器
            HStack {
                Picker("選擇會議", selection: $selectedSession) {
                    Text("").tag(nil as Session?)
                    ForEach(sessionListVM.sessions) { session in
                        Text(session.title ?? session.session_id ?? "未命名")
                            .tag(session as Session?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 200)
                Button("新增會議") {
                    showingCreateSheet = true
                }
            }
            .padding(.horizontal)

            Button(action: {
                recordingVM.mode = .stream
                // 傳入 session_id 給 WebSocket
                recordingVM.sessionID = selectedSession?.session_id
                recordingVM.toggleRecording()
            }) {
                Text(recordingVM.isRecording ? "停止錄音" : "開始錄音")
                    .font(.title2)
                    .padding()
                    .background(recordingVM.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recordingVM.outputs, id: \.self) { line in
                        Text(line)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            sessionListVM.fetchSessions()
        }
        .onChange(of: sessionListVM.sessions) { newSessions in
            print("SilentModeView sessions updated:", newSessions)
            if selectedSession == nil, let first = newSessions.first {
                selectedSession = first
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateSessionView(sessionListVM: sessionListVM)
        }
    }
}
