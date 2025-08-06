//
//  SilentModeView.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import SwiftUI

struct SilentModeView: View {
    @StateObject private var recordingVM = RecordingViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                recordingVM.mode = .stream
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
    }
} 