//
//  LockView.swift
//  Sentry
//
//  Created by Monu Kumar on 06/01/26.
//

import SwiftUI
import Combine

struct LockView: View {
    
    @StateObject private var lockManager = LockManager.shared
    @StateObject private var cliManager = CLIManager.shared
    @StateObject private var settings = SettingsManager.shared

    @State private var attempts: Int = 0
    @State private var tapCount: Int = 0
    @State private var currentDate = Date()
    @State private var verticalOffset: CGFloat = 0
    @State private var pulseState: Bool = false
    @State private var isHoveringLockBtn: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm"
        return formatter.string(from: currentDate)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        let isSystem = settings.lockBehavior == .system
        
        ZStack {
            if isSystem {
                Color.clear.edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
            }
            
            if isSystem {
                if cliManager.isVisible {
                    cliProgressCard
                }
            } else {
                VStack {
                    if settings.showClockWidget {
                        VStack(spacing: -8) {
                            Text(dateString)
                                .font(.system(size: 40, weight: .semibold))
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(timeString)
                                .font(.system(size: 140, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                    } else {
                        Spacer()
                            .frame(height: 40)
                    }
                    
                    Spacer()
                    
                    if cliManager.isVisible {
                        cliProgressCard
                            .padding(.bottom, 20)
                    }
                    
                    if tapCount >= 2 {
                        VStack(spacing: 10) {
                            Text("Having trouble with Touch ID?")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: {
                                lockManager.lockmacOS()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Lock Mac")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(isHoveringLockBtn ? 0.25 : 0.15))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(isHoveringLockBtn ? 0.4 : 0.2), lineWidth: 1)
                                )
                                .scaleEffect(isHoveringLockBtn ? 1.03 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: isHoveringLockBtn)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringLockBtn = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            .padding(.top, 2)
                            
                            Text("to stop Sentry")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    }
                }
                .padding(.vertical, 60)
                
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
                        }
                    }
                }
                .modifier(Shake(animatableData: CGFloat(attempts)))
            }
        }
        .offset(y: isSystem ? 0 : verticalOffset)
        .onReceive(timer) { input in
            guard !isSystem else { return }
            let lastMinute = Calendar.current.component(.minute, from: currentDate)
            currentDate = input
            let currentMinute = Calendar.current.component(.minute, from: input)
            
            if lastMinute != currentMinute {
                withAnimation(.easeInOut(duration: 2.0)) {
                    verticalOffset = CGFloat.random(in: -20...20)
                }
            }
        }
        .onTapGesture {
            guard !isSystem else { return }
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
    
    private var cliProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if settings.cliShowTitleBar {
                HStack(spacing: 8) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(cliManager.title)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        if cliManager.status == "running" {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                                .opacity(pulseState ? 0.3 : 1.0)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                        pulseState = true
                                    }
                                }
                                .onDisappear {
                                    pulseState = false
                                }
                            
                            Text("Running")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)
                        } else if cliManager.status == "success" {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            
                            Text("Success")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        } else if cliManager.status == "failed" {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            
                            Text("Failed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Text("Completed")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                
                Divider()
                    .background(Color.white.opacity(0.15))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                let displayLines = Array(cliManager.lines.suffix(settings.cliLineLimit))
                ForEach(Array(displayLines.enumerated()), id: \.offset) { index, line in
                    let isLast = index == displayLines.count - 1
                    Text(line)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(isLast ? .white : .white.opacity(0.5))
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: 640)
        .applyProgressCardBackground(isSystemLock: settings.lockBehavior == .system)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(
            .move(edge: .bottom).combined(with: .opacity)
        )
    }
}

struct ProgressCardBackgroundModifier: ViewModifier {
    let isSystemLock: Bool
    
    func body(content: Content) -> some View {
        if isSystemLock {
            if #available(macOS 26.0, *) {
                content
                    .glassEffect(in: RoundedRectangle(cornerRadius: 16))
            } else {
                content
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.5))
                            .background(.ultraThinMaterial)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.5))
                        .background(.ultraThinMaterial)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

extension View {
    func applyProgressCardBackground(isSystemLock: Bool) -> some View {
        self.modifier(ProgressCardBackgroundModifier(isSystemLock: isSystemLock))
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
