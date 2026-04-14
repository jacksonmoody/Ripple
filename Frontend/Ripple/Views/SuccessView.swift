import SwiftUI

struct SuccessView: View {
    let nudgedCount: Int
    var onInviteMore: () -> Void

    @State private var showContent = false
    @State private var rippleScale: CGFloat = 0.3

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.55, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 300, height: 300)
                .scaleEffect(rippleScale)

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .nonRepeating)

                VStack(spacing: 12) {
                    Text("Ripple Sent!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("You've nudged **\(nudgedCount) \(nudgedCount == 1 ? "person" : "people")** to vote.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 8) {
                    Text("Every nudge creates a ripple.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Keep going!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button(action: onInviteMore) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Invite More Contacts")
                    }
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.15, green: 0.25, blue: 0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: Capsule())
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                rippleScale = 1.2
            }
        }
    }
}
