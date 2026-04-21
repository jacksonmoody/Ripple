import PhotosUI
import SwiftUI
import UIKit

struct ProfileTab: View {
    @Bindable var appState: AppState
    let provider: NetworkDataProvider

    @State private var profile: NetworkService.ProfileResponse?
    @State private var isLoading = true
    @State private var isEditingName = false
    @State private var nameInput = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    @State private var avatarImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Avatar + name
                profileHeader
                    .padding(.horizontal, 18)
                    .padding(.top, 20)

                // Stats cards
                statsSection
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                // Account info
                accountSection
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                // Sign out
                signOutButton
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
            }
        }
        .task {
            await fetchProfile()
        }
        .alert("Edit Name", isPresented: $isEditingName) {
            TextField("Your name", text: $nameInput)
            Button("Save") {
                Task { await saveName() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your display name")
        }
        .onChange(of: selectedPhoto) {
            Task { await handlePhotoSelection() }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar with photo picker
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 100, height: 100)

                    if let avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 2))
                    } else if let avatarUrl = profile?.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 2))
                            default:
                                initialsAvatar
                            }
                        }
                    } else {
                        initialsAvatar
                    }

                    // Camera badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(NetworkColors.darkBlue)
                                    .frame(width: 28, height: 28)
                                Image(systemName: isUploadingAvatar ? "arrow.trianglehead.2.counterclockwise" : "camera.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }

            // Name
            VStack(spacing: 4) {
                if let name = profile?.name, !name.isEmpty {
                    Text(name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(displayPhone)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Button {
                    nameInput = profile?.name ?? ""
                    isEditingName = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                        Text(profile?.name != nil ? "Edit name" : "Add name")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
        )
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(.white.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 2))
            .overlay(
                Text(avatarInitials)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(NetworkColors.darkBlue)
                    .frame(width: 68, height: 68)
                    .background(.white, in: Circle())
            )
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR STATS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
                statCard(value: "\(profile?.nudgeCount ?? provider.nudgedCount)", label: "Total nudges")
                statCard(value: "\(profile?.uniqueContactsNudged ?? 0)", label: "People nudged")
                statCard(value: provider.daysToElection.map { "\($0)" } ?? "--", label: "Days to election")
                statCard(value: memberSince, label: "Member since")
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(NetworkColors.glassBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NetworkColors.glassBorder, lineWidth: 1))
        )
    }

    // MARK: - Account Info

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACCOUNT")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)

            VStack(spacing: 0) {
                infoRow(icon: "phone.fill", label: "Phone", value: displayPhone)

                Divider().background(.white.opacity(0.08))

                infoRow(icon: "person.fill", label: "Name", value: profile?.name ?? "Not set")

                Divider().background(.white.opacity(0.08))

                infoRow(icon: "calendar", label: "Joined", value: memberSince)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 1))
            )
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 15)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            appState.clearSession()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.square")
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.2), lineWidth: 1))
            )
        }
    }

    // MARK: - Helpers

    private var avatarInitials: String {
        if let name = profile?.name, !name.isEmpty {
            let parts = name.split(separator: " ")
            let first = parts.first?.first.map(String.init) ?? ""
            let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
            return (first + last).uppercased()
        }
        return "ME"
    }

    private var displayPhone: String {
        profile?.phoneNumber ?? appState.userPhoneNumber
    }

    private var memberSince: String {
        guard let dateString = profile?.createdAt else { return "--" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: dateString) ?? {
            let f2 = ISO8601DateFormatter()
            return f2.date(from: dateString)
        }()
        guard let d = date else { return "--" }
        let display = DateFormatter()
        display.dateFormat = "MMM yyyy"
        return display.string(from: d)
    }

    // MARK: - Network

    private func fetchProfile() async {
        isLoading = true
        defer { isLoading = false }

        let token = appState.sessionToken
        guard !token.isEmpty else { return }

        profile = try? await NetworkService.getProfile(token: token)
    }

    private func saveName() async {
        let token = appState.sessionToken
        guard !token.isEmpty, !nameInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        if let result = try? await NetworkService.updateName(name: nameInput, token: token) {
            profile = NetworkService.ProfileResponse(
                id: profile?.id ?? appState.userId,
                name: result.name,
                phoneNumber: profile?.phoneNumber,
                createdAt: profile?.createdAt,
                nudgeCount: profile?.nudgeCount ?? 0,
                uniqueContactsNudged: profile?.uniqueContactsNudged ?? 0,
                firstNudgeAt: profile?.firstNudgeAt,
                avatarUrl: profile?.avatarUrl
            )
        }
    }

    // MARK: - Photo Upload

    private func handlePhotoSelection() async {
        guard let selectedPhoto else { return }

        isUploadingAvatar = true
        defer { isUploadingAvatar = false }

        guard let data = try? await selectedPhoto.loadTransferable(type: Data.self) else { return }

        // Compress to JPEG
        guard let uiImage = UIImage(data: data) else { return }
        let maxSize: CGFloat = 800
        let scale = min(maxSize / uiImage.size.width, maxSize / uiImage.size.height, 1.0)
        let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else { return }

        // Show immediately
        avatarImage = resized

        // Upload to backend
        let token = appState.sessionToken
        guard !token.isEmpty else { return }

        if let result = try? await NetworkService.uploadAvatar(
            imageData: jpegData,
            mimeType: "image/jpeg",
            token: token
        ) {
            profile = NetworkService.ProfileResponse(
                id: profile?.id ?? appState.userId,
                name: profile?.name,
                phoneNumber: profile?.phoneNumber,
                createdAt: profile?.createdAt,
                nudgeCount: profile?.nudgeCount ?? 0,
                uniqueContactsNudged: profile?.uniqueContactsNudged ?? 0,
                firstNudgeAt: profile?.firstNudgeAt,
                avatarUrl: result.avatarUrl
            )
        }
    }
}
