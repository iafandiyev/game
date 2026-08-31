import SwiftUI

public struct GameOverView: View {
    @ObservedObject var gameState: GameState
    let onRetry: () -> Void
    let onMenu: () -> Void
    let onRevive: () -> Void
    
    @State private var appearAnimation = false
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("MİSSİYA BİTDİ")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(Color.red)
                        .shadow(color: Color.red, radius: 15)
                    
                    if gameState.currentScore >= gameState.highScore && gameState.currentScore > 0 {
                        Text("★ YENİ REKORD! ★")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .scaleEffect(appearAnimation ? 1.0 : 0.6)
                
                // Stats Card
                VStack(spacing: 16) {
                    StatRow(icon: "star.fill", title: "Toplanan Xal", value: "\(gameState.currentScore)", color: .yellow)
                    StatRow(icon: "waveform.path.ecg", title: "Çatılan Dalğa", value: "\(gameState.currentWave)", color: .cyan)
                    StatRow(icon: "scope", title: "Məhv Edilən Düşmən", value: "\(gameState.runKills)", color: .red)
                    StatRow(icon: "sparkles", title: "Qazanılan Kristallar", value: "+\(gameState.runCrystals)", color: .green)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(white: 0.1).opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 28)
                .offset(y: appearAnimation ? 0 : 30)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Revive Button if crystals available
                    if gameState.cyberCrystals >= 30 {
                        Button(action: {
                            gameState.cyberCrystals -= 30
                            HapticsManager.shared.playSuccess()
                            onRevive()
                        }) {
                            HStack {
                                Image(systemName: "heart.circle.fill")
                                Text("GƏMİNİ DİRİLT (30 💎)")
                            }
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.5), radius: 10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Retry
                    Button(action: {
                        HapticsManager.shared.playMedium()
                        onRetry()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("YENİDƏN BAŞLA")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(gameState.selectedTheme.primaryColor)
                        .cornerRadius(14)
                        .shadow(color: gameState.selectedTheme.primaryColor.opacity(0.5), radius: 10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Main Menu
                    Button(action: {
                        HapticsManager.shared.playLight()
                        onMenu()
                    }) {
                        Text("ƏSAS MENYU")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
    }
}

fileprivate struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
