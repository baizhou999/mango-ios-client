import SwiftUI
import Foundation

struct LoginView: View {
    @EnvironmentObject private var state: AppState
    @State private var phone = ""
    @State private var code = ""
    @State private var step: Step = .phone
    @State private var errorText: String?

    private enum Step {
        case phone
        case code
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text(AppInfo.displayName)
                    .font(.largeTitle.bold())
                Text("第三方 Telegram 客户端")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 12) {
                if step == .phone {
                    TextField("手机号（含国家区号）", text: $phone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                } else {
                    Text("验证码已发送至 \(phone)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("验证码", text: $code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }

            if let errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundColor(.red)
            }

            Button(action: advance) {
                Text(step == .phone ? "继续" : "登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)

            Text("当前为演示模式：验证码不会真正发送，也不会连接 Telegram 服务器。")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(24)
    }

    private func advance() {
        errorText = nil
        switch step {
        case .phone:
            guard phone.trimmingCharacters(in: .whitespaces).count >= 5 else {
                errorText = "请输入完整的手机号（含国家区号）"
                return
            }
            step = .code
        case .code:
            guard code.count >= 4 else {
                errorText = "请输入验证码"
                return
            }
            state.signIn(phone: phone)
        }
    }
}
