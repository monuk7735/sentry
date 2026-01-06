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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.default) {
                self.attempts += 1
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
