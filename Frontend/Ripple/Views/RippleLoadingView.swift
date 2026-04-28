//
//  RippleLoadingView.swift
//  Ripple
//
//  Created by Jackson Moody on 4/28/26.
//

import SwiftUI

struct RippleLoadingView: View {
    @State private var isRippling = false
    
    private let rippleBlue = Color(red: 0.25, green: 0.4, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.97, blue: 1.0)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(rippleBlue.opacity(0.28 - Double(index) * 0.05), lineWidth: 2)
                            .frame(
                                width: 72 + CGFloat(index) * 38,
                                height: 72 + CGFloat(index) * 38
                            )
                            .scaleEffect(isRippling ? 1.35 : 0.72)
                            .opacity(isRippling ? 0.08 : 0.75)
                            .animation(
                                .easeOut(duration: 1.7)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.24),
                                value: isRippling
                            )
                    }
                    
                    Circle()
                        .fill(rippleBlue)
                        .frame(width: 58, height: 58)
                        .shadow(color: rippleBlue.opacity(0.25), radius: 18, y: 10)
                    
                    Image(systemName: "water.waves")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.breathe, options: .repeating)
                }
                .frame(width: 180, height: 180)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Ripple")
        .onAppear {
            isRippling = true
        }
    }
}

#Preview {
    RippleLoadingView()
}
