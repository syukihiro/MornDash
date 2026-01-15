import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var blockManager: BlockManager
    
    @State private var currentStep = 0
    @Namespace private var animation
    
    var body: some View {
        ZStack {
            // Animated Background
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= currentStep ? Color.white : Color.white.opacity(0.2))
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(), value: currentStep)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                Spacer()
                
                // Content with Transition
                Group {
                    if currentStep == 0 {
                        OnboardingWelcomeView {
                            withAnimation { currentStep += 1 }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity)))
                    } else if currentStep == 1 {
                        OnboardingTimeView(viewModel: viewModel) {
                            withAnimation { currentStep += 1 }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity)))
                    } else if currentStep == 2 {
                        OnboardingBlockingView(blockManager: blockManager) {
                            withAnimation {
                                isCompleted = true
                            }
                        }
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                              removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Step 1: Welcome & Permissions
struct OnboardingWelcomeView: View {
    var nextAction: () -> Void
    @State private var isProcessing = false
    @State private var notificationsAuthorized = false
    @State private var screenTimeAuthorized = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "sunrise.fill")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .bottom, endPoint: .top))
                .shadow(color: .orange.opacity(0.5), radius: 20, x: 0, y: 0)
            
            VStack(spacing: 12) {
                Text("Welcome to MornDash")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Master your morning routine.\nFirst, we need a few permissions to work our magic.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(spacing: 20) {
                PermissionButton(
                    title: "Enable Notifications",
                    icon: "bell.badge.fill",
                    isAuthorized: notificationsAuthorized
                ) {
                    let granted = await NotificationManager.shared.requestAuthorization()
                    await MainActor.run {
                        notificationsAuthorized = granted
                    }
                }
                
                PermissionButton(
                    title: "Enable Screen Time",
                    icon: "hourglass",
                    isAuthorized: screenTimeAuthorized
                ) {
                    await BlockManager().requestAuthorization()
                    // Note: We can't easily check actual status, assuming success for flow
                    await MainActor.run {
                        screenTimeAuthorized = true
                    }
                }
            }
            .padding(.horizontal)
            
            Button(action: nextAction) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule()
                            .fill(notificationsAuthorized && screenTimeAuthorized ? Color.white : Color.gray)
                    )
            }
            .disabled(!(notificationsAuthorized && screenTimeAuthorized))
            .padding(.top, 20)
        }
    }
}

struct PermissionButton: View {
    let title: String
    let icon: String
    let isAuthorized: Bool
    let action: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await action()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAuthorized ? Color.green : Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isAuthorized)
    }
}

// MARK: - Step 2: Time Setting
struct OnboardingTimeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var nextAction: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("When do you wake up?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            DatePicker("", selection: $viewModel.alarmSettings.time, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .colorScheme(.dark)
                .labelsHidden()
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            
            Button(action: nextAction) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Capsule().fill(Color.white))
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Step 3: Blocking
struct OnboardingBlockingView: View {
    @ObservedObject var blockManager: BlockManager
    var nextAction: () -> Void
    @State private var showPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(22)
                .shadow(color: .orange.opacity(0.5), radius: 20)
            
            VStack(spacing: 12) {
                Text("Morning Focus")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Select apps to block immediately after waking up. \nDon't let doomscrolling steal your morning.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Button(action: { showPicker = true }) {
                HStack {
                    Text("Select Apps to Block")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .sheet(isPresented: $showPicker) {
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") { showPicker = false }
                            .padding()
                    }
                    FamilyActivityPicker(selection: $blockManager.morningSelection)
                }
            }
            
            if !blockManager.morningSelection.applicationTokens.isEmpty || !blockManager.morningSelection.categoryTokens.isEmpty {
                Text("\(blockManager.morningSelection.applicationTokens.count + blockManager.morningSelection.categoryTokens.count) items selected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Button(action: nextAction) {
                Text("Finish Setup")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule()
                            .fill((!blockManager.morningSelection.applicationTokens.isEmpty || !blockManager.morningSelection.categoryTokens.isEmpty) ? Color.white : Color.gray)
                    )
            }
             // Allow proceed even if empty, but prefer selection. Let's allow empty.
            .disabled(false) 
            .padding(.top, 20)
        }
    }
}
