import SwiftUI

struct ContentView: View {
    enum UIMode { case ar, silent, users, sessions }
    @State private var mode: UIMode = .ar

    var body: some View {
        VStack {
            HStack {
                Button("AR模式") { mode = .ar }
                    .padding(8)
                    .background(mode == .ar ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                Button("沈默模式") { mode = .silent }
                    .padding(8)
                    .background(mode == .silent ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                Button("用戶列表") { mode = .users }
                    .padding(8)
                    .background(mode == .users ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                Button("會議管理") { mode = .sessions }
                    .padding(8)
                    .background(mode == .sessions ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)

                Spacer()
            }
            .padding()

            Group {
                switch mode {
                case .ar:
                    ARModeView()
                case .silent:
                    SilentModeView()
                case .users:
                    UsersModeView()
                case .sessions:
                    SessionsModeView()
                }
            }
            .animation(.default, value: mode)
        }
    }
}

#Preview {
    ContentView()
}
