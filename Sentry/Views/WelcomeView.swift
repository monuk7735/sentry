//
//  WelcomeView.swift
//  Sentry
//
//  Created by Monu Kumar on 10/08/26.
//

import SwiftUI

enum OnboardingStep {
    case overview
    case setup
}

struct WelcomeView: View {
    @StateObject private var lockManager = LockManager.shared
    @State private var currentStep: OnboardingStep = .overview
    @State private var isHoveringPrimaryBtn = false
    
    var body: some View {
        ZStack {
            // Background subtle gradient fill
            LinearGradient(
                colors: [Color.blue.opacity(0.04), Color.indigo.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Navigation Bar / Step Indicator
                HStack {
                    if currentStep == .setup {
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                currentStep = .overview
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Step indicator pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(currentStep == .overview ? Color.blue : Color.primary.opacity(0.2))
                            .frame(width: 7, height: 7)
                        Circle()
                            .fill(currentStep == .setup ? Color.blue : Color.primary.opacity(0.2))
                            .frame(width: 7, height: 7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .frame(height: 32)
                
                // Content View with Spring Animation
                ZStack {
                    if currentStep == .overview {
                        overviewScreen
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                )
                            )
                    } else {
                        setupScreen
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                )
                            )
                    }
                }
                
                Spacer(minLength: 12)
                
                // Bottom CTA Button Area
                VStack(spacing: 0) {
                    if currentStep == .overview {
                        Button(action: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                currentStep = .setup
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                    .font(.system(size: 15, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                isHoveringPrimaryBtn ? Color.blue.opacity(0.9) : Color.blue,
                                                isHoveringPrimaryBtn ? Color.indigo.opacity(0.9) : Color.indigo
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 4)
                            )
                            .scaleEffect(isHoveringPrimaryBtn ? 1.015 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringPrimaryBtn)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringPrimaryBtn = hovering
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    } else {
                        Button(action: {
                            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                            WelcomeWindowManager.shared.close()
                        }) {
                            Text("Done")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    isHoveringPrimaryBtn ? Color.blue.opacity(0.9) : Color.blue,
                                                    isHoveringPrimaryBtn ? Color.indigo.opacity(0.9) : Color.indigo
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 4)
                                )
                                .scaleEffect(isHoveringPrimaryBtn ? 1.015 : 1.0)
                                .animation(.easeInOut(duration: 0.15), value: isHoveringPrimaryBtn)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.defaultAction)
                        .onHover { hovering in
                            isHoveringPrimaryBtn = hovering
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 680, height: 500)
    }
    
    // MARK: - Screen 1: Overview (Static Non-Clickable Preview)
    private var overviewScreen: some View {
        VStack(spacing: 20) {
            // Hero Header
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.9), Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 5)
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    Text("Welcome to Sentry")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Sentry protects your Mac with custom lock screen security, live terminal task progress, and keeps your display awake whenever you need uninterrupted workflow.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.top, 4)
            
            // 2x2 Overview Feature Cards Grid (Static Non-Clickable)
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    OverviewCard(
                        icon: "lock.fill",
                        color: .blue,
                        title: "Lock Screen",
                        subtitle: "Touch ID, widgets & screen dimming"
                    )
                    
                    OverviewCard(
                        icon: "cup.and.saucer.fill",
                        color: .orange,
                        title: "Keep Awake",
                        subtitle: "Prevent display & system sleep"
                    )
                }
                
                HStack(spacing: 14) {
                    OverviewCard(
                        icon: "terminal.fill",
                        color: .green,
                        title: "Task Monitor",
                        subtitle: "Live sentry-cli output on lockscreen"
                    )
                    
                    OverviewCard(
                        icon: "keyboard.fill",
                        color: .purple,
                        title: "Global Hotkeys",
                        subtitle: "Instant shortcuts from anywhere"
                    )
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Screen 2: Actionable Setup (Wide 2x2 Grid)
    private var setupScreen: some View {
        VStack(spacing: 18) {
            // Header
            VStack(spacing: 4) {
                Text("Quick Setup")
                    .font(.system(size: 26, weight: .bold))
                
                Text("Configure your shortcuts and test protection features right now.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
            
            // 2x2 Action Cards Grid
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ActionCard(
                        icon: "keyboard.fill",
                        iconColor: .purple,
                        title: "Setup Shortcuts",
                        description: "Configure key combinations to lock screen or toggle Keep Awake.",
                        actionTitle: "Configure",
                        action: {
                            SettingsWindowManager.shared.show(tab: .shortcuts)
                        }
                    )
                    
                    ActionCard(
                        icon: "cup.and.saucer.fill",
                        iconColor: .orange,
                        title: "Keep Awake",
                        description: "Prevent display & Mac sleep during long jobs.",
                        actionTitle: lockManager.caffeineMode ? "Active" : "Enable",
                        isActionActive: lockManager.caffeineMode,
                        action: {
                            lockManager.caffeineMode.toggle()
                        }
                    )
                }
                
                HStack(spacing: 14) {
                    ActionCard(
                        icon: "lock.fill",
                        iconColor: .blue,
                        title: "Test Lock Screen",
                        description: "Immediately lock Mac with Touch ID & live progress widget.",
                        actionTitle: "Lock Mac",
                        action: {
                            LockManager.shared.lock()
                        }
                    )
                    
                    ActionCard(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        title: "Customize Settings",
                        description: "Adjust keyboard shortcuts, caffeine mode, and CLI settings.",
                        actionTitle: "Settings",
                        action: {
                            SettingsWindowManager.shared.show(tab: .shortcuts)
                        }
                    )
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Supporting Views

private struct OverviewCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)
                
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let actionTitle: String
    var isActionActive: Bool = false
    let action: () -> Void
    
    @State private var isHoveringButton = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.14))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 4)
            
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isActionActive ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(
                                isActionActive
                                ? (isHoveringButton ? Color.orange.opacity(0.9) : Color.orange)
                                : (isHoveringButton ? Color.primary.opacity(0.12) : Color.primary.opacity(0.07))
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(isActionActive ? Color.clear : Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .scaleEffect(isHoveringButton ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isHoveringButton)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringButton = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.primary.opacity(0.025))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
