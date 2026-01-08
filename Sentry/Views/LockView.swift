//
//  LockView.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import SwiftUI

struct LockView: View {
    
    @StateObject private var lockManager = LockManager.shared
    @State private var attempts: Int = 0
    @State private var tapCount: Int = 0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Text("Sentry Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if lockManager.canUseTouchID {
                    Text("Touch ID to unlock")
                    .font(.title2)
                    .foregroundColor(.gray)
                } else {
                    VStack(spacing: 8) {
                        Text("Touch ID Unavailable")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        
                        Text("Press Cmd + Ctrl + Q to Lock System")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
            }
            .modifier(Shake(animatableData: CGFloat(attempts)))
            
            if tapCount >= 5 {
                VStack(spacing: 12) {
                    Spacer()
                    
                    Text("Having trouble with Touch ID?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 6) {
                        KeyView(label: "⌘")
                        Text("+")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 16, weight: .semibold))
                        KeyView(label: "⌃")
                        Text("+")
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 16, weight: .semibold))
                        KeyView(label: "Q")
                    }
                    
                    Text("to lock system & stop Sentry")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.bottom, 60)
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.default) {
                self.attempts += 1
                self.tapCount += 1
                
                if self.tapCount == 5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        withAnimation {
                            self.tapCount = 0
                        }
                    }
                }
            }
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct KeyView: View {
    let label: String
    
    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}
