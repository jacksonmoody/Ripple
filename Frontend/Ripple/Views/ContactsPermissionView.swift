import SwiftUI
import Contacts

struct ContactsPermissionView: View {
    @Bindable var contactsManager: ContactsManager
    var onAccessGranted: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 1.0).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                    .symbolEffect(.bounce, options: .nonRepeating)

                VStack(spacing: 12) {
                    Text("Connect Your Contacts")
                        .font(.title2.bold())

                    Text("Ripple needs access to your contacts so you can invite friends and family to vote.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                featureList

                Spacer()

                switch contactsManager.authorizationStatus {
                case .notDetermined:
                    allowAccessButton
                case .denied, .restricted:
                    deniedView
                case .authorized, .limited:
                    continueButton
                @unknown default:
                    allowAccessButton
                }

                Spacer().frame(height: 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .onChange(of: contactsManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorized || newStatus == .limited {
                onAccessGranted()
            }
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "person.crop.circle.badge.checkmark", text: "See which friends have elections coming up")
            featureRow(icon: "envelope.fill", text: "Send personalized voting reminders")
            featureRow(icon: "lock.shield", text: "Your contacts stay on your device")
        }
        .padding(.horizontal, 40)
        .padding(.top, 8)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color(red: 0.25, green: 0.4, blue: 0.85))
                .frame(width: 32)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }

    private var allowAccessButton: some View {
        Button {
            Task { await contactsManager.requestAccess() }
        } label: {
            Text("Allow Access")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.25, green: 0.4, blue: 0.85), in: Capsule())
        }
        .padding(.horizontal, 40)
    }

    private var deniedView: some View {
        VStack(spacing: 12) {
            Text("Contact access was denied.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange, in: Capsule())
            }
            .padding(.horizontal, 40)
        }
    }

    private var continueButton: some View {
        Button(action: onAccessGranted) {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.25, green: 0.4, blue: 0.85), in: Capsule())
        }
        .padding(.horizontal, 40)
    }
}
