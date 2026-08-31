import SwiftUI

public struct SettingsView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        ZStack {
            gameState.selectedTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header Bar
                HStack {
                    Button(action: {
                        HapticsManager.shared.playLight()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("TƏNZİMLƏMƏLƏR")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(gameState.selectedTheme.primaryColor)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Audio & Haptics Section
                        SectionCard(title: "AUDİO VƏ HAPTİK") {
                            ToggleRow(icon: "speaker.wave.3.fill", title: "Səs Effektləri", isOn: $gameState.soundEnabled)
                            Divider().background(Color.white.opacity(0.1))
                            ToggleRow(icon: "iphone.radiowaves.left.and.right", title: "Taptic / Haptik Vibrasiya", isOn: $gameState.hapticsEnabled)
                        }
                        
                        // Performance Section
                        SectionCard(title: "QRAFİKA VƏ PERFORMANS") {
                            ToggleRow(icon: "bolt.fill", title: "ProMotion 120 FPS Modu", isOn: $gameState.is120FpsEnabled)
                        }
                        
                        // Theme Palette Section
                        SectionCard(title: "RƏNG TEMASI") {
                            VStack(spacing: 10) {
                                ForEach(ThemePalette.allCases) { theme in
                                    let isSelected = (gameState.selectedTheme == theme)
                                    Button(action: {
                                        gameState.selectedTheme = theme
                                        HapticsManager.shared.playLight()
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(theme.primaryColor)
                                                .frame(width: 20, height: 20)
                                                .overlay(Circle().stroke(theme.secondaryColor, lineWidth: 2))
                                            
                                            Text(theme.rawValue)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if isSelected {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(theme.primaryColor)
                                            }
                                        }
                                        .padding(12)
                                        .background(isSelected ? theme.primaryColor.opacity(0.15) : Color.clear)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        // Controls Sensitivity
                        SectionCard(title: "İDARƏETMƏ HƏSSASLIĞI") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Coystik Həssaslığı")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Text(String(format: "%.1fx", gameState.joystickSensitivity))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(gameState.selectedTheme.primaryColor)
                                }
                                
                                Slider(value: $gameState.joystickSensitivity, in: 0.5...2.0, step: 0.1)
                                    .accentColor(gameState.selectedTheme.primaryColor)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

fileprivate struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 4)
            
            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.1).opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
            )
        }
    }
}

fileprivate struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.cyan)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}
