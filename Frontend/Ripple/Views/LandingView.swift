import SwiftUI

struct LandingView: View {
    var onGetStarted: () -> Void

    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 1.0
    @State private var showContent = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.25, blue: 0.65), Color(red: 0.35, green: 0.55, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            rippleCircles
                .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.35)

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white)
                        .symbolEffect(.breathe, options: .repeating)

                    Text("Ripple")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Your voice creates a ripple.")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                VStack(spacing: 16) {
                    Text("Make a difference, one text at a time.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)

                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.15, green: 0.25, blue: 0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white, in: Capsule())
                    }
                    .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            startRippleAnimation()
        }
    }

    private var rippleCircles: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(.white.opacity(0.08), lineWidth: 1.5)
                    .frame(width: 200 + CGFloat(i) * 120, height: 200 + CGFloat(i) * 120)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity * (1.0 - Double(i) * 0.25))
            }
        }
    }

    private func startRippleAnimation() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            rippleScale = 1.1
            rippleOpacity = 0.6
        }
    }
}
