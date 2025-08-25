import Foundation
import AVFoundation
import AVKit

enum Mode {
    case transcribe
    case stream
}

class RecordingViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var outputs: [String] = []
    @Published var isRecording = false
    @Published var isUploading = false
    @Published var mode: Mode = .transcribe
    @Published var sessionID: String? = nil

    private var recorder: AVAudioRecorder?
    private var tempFileURL: URL?

    // WebSocket & Stream
    private var webSocketTask: URLSessionWebSocketTask?
    // AVCaptureSession 已移除
    // private var session: AVCaptureSession?
    private var audioSession: AVAudioSession?
    // AVAudioEngine 相關
    private var audioEngine: AVAudioEngine?
    private var inputFormat: AVAudioFormat?
    private var outputFormat: AVAudioFormat?

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        if mode == .stream {
            startStreaming()
        } else {
            startTranscribeRecording()
        }
    }

    private func stopRecording() {
        if mode == .stream {
            stopStreaming()
        } else {
            stopTranscribeRecording()
        }
    }

    // MARK: - Transcribe 模式（原始錄音儲存並上傳）
    private func startTranscribeRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".wav"
        tempFileURL = tempDir.appendingPathComponent(filename)

        do {
            recorder = try AVAudioRecorder(url: tempFileURL!, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
            outputs = ["🎙️ 開始錄音..."]
        } catch {
            outputs = ["❌ 錄音失敗：\(error.localizedDescription)"]
        }
    }

    private func stopTranscribeRecording() {
        recorder?.stop()
        isRecording = false
        outputs.append("🛑 錄音結束，準備上傳...")

        if let url = tempFileURL {
            uploadAudio(fileURL: url)
        }
    }
    
    private var audioConverter: AVAudioConverter?
    private let targetSampleRate: Double = 16000
    private var targetFormat: AVAudioFormat?

    // MARK: - Stream 模式（用 AVAudioEngine 傳送 16bit PCM 到 WebSocket）
    private func startStreaming() {
        outputs = ["🎙️ 開始建立音訊串流..."]

        var wsURLString = Config.API.stream
        if let sessionID = sessionID, !sessionID.isEmpty {
            wsURLString += "?session=\(sessionID)"
        }
        let url = URL(string: wsURLString)!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession?.setPreferredSampleRate(16000)
            try audioSession?.setActive(true)
        } catch {
            outputs.append("❌ 初始化失敗：\(error.localizedDescription)")
            return
        }

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        let inputNode = audioEngine.inputNode
        let hwFormat = inputNode.inputFormat(forBus: 0) // 硬體格式
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

        let converter = AVAudioConverter(from: hwFormat, to: targetFormat)!

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(targetFormat.sampleRate) * buffer.frameLength / AVAudioFrameCount(hwFormat.sampleRate))!
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            let data = Data(bytes: convertedBuffer.int16ChannelData![0], count: Int(convertedBuffer.frameLength * 2))
            self.webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.outputs.append("❌ 傳送失敗：\(error.localizedDescription)")
                    }
                }
            }
        }

        do {
            try audioEngine.start()
            isRecording = true
            outputs.append("🌐 WebSocket 已連線，開始串流...")
        } catch {
            outputs.append("❌ AudioEngine 啟動失敗：\(error.localizedDescription)")
        }

        receiveMessages()
    }

    private func stopStreaming() {
        isRecording = false
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        webSocketTask?.send(.string("stop")) { _ in }
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        outputs.append("🛑 已停止串流錄音")
    }

    // MARK: - WebSocket 接收訊息
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleWebSocketData(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self.handleWebSocketData(data)
                    } else {
                        self.outputs.append("⚠️ 字串轉資料失敗")
                    }
                @unknown default:
                    self.outputs.append("⚠️ 未知的 WebSocket 訊息格式")
                }
                self.receiveMessages() // 持續接收

            case .failure(let error):
                DispatchQueue.main.async {
                    self.outputs.append("❌ 接收失敗：\(error.localizedDescription)")
                }
            }
        }
    }

    private func handleWebSocketData(_ data: Data) {
        do {
            // 解析整份 JSON 為 [String: Any]
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let speakers = json["speakers"] as? [[String: Any]] {

                DispatchQueue.main.async {
                    for speakerInfo in speakers {
                        let speaker = speakerInfo["speaker"] as? String ?? "未知"
                        let text = speakerInfo["text"] as? String ?? ""
                        let line = "\(speaker)：\(text)"
                        self.outputs.append(line)
                    }
                }

            } else {
                // 如果 speakers 欄位不存在，印出原始 JSON 字串
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 回傳格式不含 speakers：\n\(rawString)")
                    DispatchQueue.main.async {
                        self.outputs.append("📩 \(rawString)")
                    }
                }
            }

        } catch {
            DispatchQueue.main.async {
                self.outputs.append("❌ JSON 解析錯誤：\(error.localizedDescription)")
            }
        }
    }



    // MARK: - Transcribe 上傳音訊
    func uploadAudio(fileURL: URL) {
        isUploading = true
        outputs.append("⏫ 上傳中...")

        var request = URLRequest(url: URL(string: Config.API.transcribe)!)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n")
        body.append("Content-Type: audio/wav\r\n\r\n")
        body.append((try? Data(contentsOf: fileURL)) ?? Data())
        body.append("\r\n--\(boundary)--\r\n")

        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            DispatchQueue.main.async {
                self.isUploading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.outputs.append("❌ 上傳錯誤：\(error.localizedDescription)")
                }
                return
            }

            guard let data = data else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let pretty = json["pretty"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    for item in pretty {
                        let line = "\(item["speaker"] ?? "未知")：\(item["text"] ?? "")"
                        self.outputs.append(line)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.outputs.append("⚠️ 回傳格式解析失敗")
                }
            }
        }.resume()
    }
}

// MARK: - Data Append Helper
fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

import AVFoundation

extension AVAudioPCMBuffer {
    convenience init?(from sampleBuffer: CMSampleBuffer) {
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else { return nil }
        let format = AVAudioFormat(streamDescription: asbd)
        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        self.init(pcmFormat: format!, frameCapacity: AVAudioFrameCount(numSamples))
        self.frameLength = AVAudioFrameCount(numSamples)
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        if let dataPointer = dataPointer {
            switch format!.commonFormat {
            case .pcmFormatFloat32:
                memcpy(self.floatChannelData![0], dataPointer, length)
            case .pcmFormatInt16:
                memcpy(self.int16ChannelData![0], dataPointer, length)
            default:
                return nil
            }
        }
    }
}
