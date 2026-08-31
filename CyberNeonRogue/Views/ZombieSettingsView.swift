import SwiftUI

public struct ZombieSettingsView: View {
    @ObservedObject var gameState: ZombieGameState
    @Environment(\.presentationMode) var presentationMode
    
    public var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.09).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    Button(action: {
                        HapticsManager.shared.playLight()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("GERİ")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text("TƏNZİMLƏMƏLƏR")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 60, height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
                HStack(spacing: 20) {
                    // Left Column: Audio & Graphics
                    VStack(spacing: 12) {
                        ZombieSettingToggle(icon: "speaker.wave.3.fill", title: "Səs Effektləri", isOn: $gameState.soundEnabled)
                        ZombieSettingToggle(icon: "iphone.radiowaves.left.and.right", title: "Taptic Vibrasiya", isOn: $gameState.hapticsEnabled)
                        ZombieSettingToggle(icon: "bolt.fill", title: "ProMotion 120 FPS", isOn: $gameState.is120FpsEnabled)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06).cornerRadius(12))
                    .frame(maxWidth: .infinity)
                    
                    // Right Column: Controls Sensitivity
                    VStack(alignment: .leading, spacing: 14) {
                        Text("İDARƏETMƏ")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white.opacity(0.6))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Coystik Həssaslığı")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(String(format: "%.1fx", gameState.joystickSensitivity))
                                    .font(.system(size: 13, weight: .heavy))
                                    .foregroundColor(.yellow)
                            }
                            
                            Slider(value: $gameState.joystickSensitivity, in: 0.5...2.0, step: 0.1)
                                .accentColor(.yellow)
                        }
                        
                        Spacer()
                        
                        Text("DeadZone: Last Survivor v1.0")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06).cornerRadius(12))
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

fileprivate struct ZombieSettingToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}
