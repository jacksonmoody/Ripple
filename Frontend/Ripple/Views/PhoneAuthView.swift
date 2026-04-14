import SwiftUI

struct PhoneAuthView: View {
    @Bindable var appState: AppState
    var onAuthenticated: () -> Void

    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var codeSent = false
    @State private var isAnimating = false
    @FocusState private var focusedField: Field?

    private enum Field { case phone, code }

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 1.0).ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: codeSent ? "lock.shield" : "phone.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                    .contentTransition(.symbolEffect(.replace))

                VStack(spacing: 8) {
                    Text(codeSent ? "Enter Verification Code" : "What's your number?")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    Text(codeSent
                         ? "We sent a 6-digit code to \(formattedPhone)"
                         : "We'll send you a code to verify your identity.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                if codeSent {
                    codeEntryField
                } else {
                    phoneEntryField
                }

                Button(action: codeSent ? verifyCode : sendCode) {
                    HStack(spacing: 8) {
                        Text(codeSent ? "Verify" : "Send Code")
                            .font(.headline)
                        if isAnimating {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        buttonEnabled
                            ? Color(red: 0.25, green: 0.4, blue: 0.85)
                            : Color.gray.opacity(0.4),
                        in: Capsule()
                    )
                }
                .disabled(!buttonEnabled || isAnimating)
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
        }
        .onAppear { focusedField = .phone }
    }

    private var phoneEntryField: some View {
        HStack(spacing: 8) {
            Text("🇺🇸 +1")
                .font(.body.monospaced())
                .foregroundStyle(.secondary)

            TextField("(555) 123-4567", text: $phoneNumber)
                .keyboardType(.phonePad)
                .font(.title3.monospaced())
                .focused($focusedField, equals: .phone)
                .onChange(of: phoneNumber) { _, newValue in
                    phoneNumber = formatPhoneInput(newValue)
                }
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.25, green: 0.4, blue: 0.85).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 32)
    }

    private var codeEntryField: some View {
        TextField("000000", text: $verificationCode)
            .keyboardType(.numberPad)
            .font(.system(size: 32, weight: .semibold, design: .monospaced))
            .multilineTextAlignment(.center)
            .focused($focusedField, equals: .code)
            .onChange(of: verificationCode) { _, newValue in
                verificationCode = String(newValue.filter(\.isNumber).prefix(6))
            }
            .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.25, green: 0.4, blue: 0.85).opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 60)
    }

    private var buttonEnabled: Bool {
        if codeSent {
            return verificationCode.count == 6
        } else {
            return phoneNumber.filter(\.isNumber).count >= 10
        }
    }

    private var formattedPhone: String {
        let digits = phoneNumber.filter(\.isNumber)
        if digits.count == 10 {
            let area = digits.prefix(3)
            let mid = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "(\(area)) \(mid)-\(last)"
        }
        return phoneNumber
    }

    private func formatPhoneInput(_ input: String) -> String {
        let digits = String(input.filter(\.isNumber).prefix(10))
        let count = digits.count
        if count <= 3 { return digits }
        if count <= 6 {
            let area = digits.prefix(3)
            let rest = digits.dropFirst(3)
            return "(\(area)) \(rest)"
        }
        let area = digits.prefix(3)
        let mid = digits.dropFirst(3).prefix(3)
        let last = digits.dropFirst(6)
        return "(\(area)) \(mid)-\(last)"
    }

    private func sendCode() {
        isAnimating = true
        // Mock delay to simulate sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAnimating = false
            withAnimation { codeSent = true }
            focusedField = .code
        }
    }

    private func verifyCode() {
        isAnimating = true
        // Mock: accept any 6-digit code
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAnimating = false
            appState.userPhoneNumber = "+1\(phoneNumber.filter(\.isNumber))"
            appState.isAuthenticated = true
            onAuthenticated()
        }
    }
}
