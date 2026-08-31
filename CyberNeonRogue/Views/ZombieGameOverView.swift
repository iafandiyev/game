import SwiftUI

public struct ZombieGameOverView: View {
    @ObservedObject var gameState: ZombieGameState
    let onRetry: () -> Void
    let onMenu: () -> Void
    
    @State private var appear = false
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.88).edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 40) {
                // Left Column: Skull & Title
                VStack(spacing: 8) {
                    Text("☠")
                        .font(.system(size: 52))
                        .foregroundColor(.red)
                        .shadow(color: .red, radius: 15)
                    
                    Text("MƏHV OLDUNUZ")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                    
                    if gameState.currentScore >= gameState.highScore && gameState.currentScore > 0 {
                        Text("★ YENİ REKORD! ★")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(6)
                    }
                }
                
                // Center Column: Stats Summary
                VStack(alignment: .leading, spacing: 10) {
                    GameOverStat(icon: "waveform.path.ecg", title: "Çatılan Dalğa", value: "Dalğa \(gameState.currentWave)", color: .yellow)
                    GameOverStat(icon: "cross.fill", title: "Məhv Edilən Zombi", value: "\(gameState.runKills)", color: .red)
                    GameOverStat(icon: "dollarsign.circle.fill", title: "Qazanılan Pul", value: "+$\(gameState.runCash)", color: .green)
                    GameOverStat(icon: "star.fill", title: "Yekun Xal", value: "\(gameState.currentScore)", color: .cyan)
                }
                .padding(16)
                .background(Color(white: 0.12).cornerRadius(14))
                
                // Right Column: Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        HapticsManager.shared.playMedium()
                        onRetry()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("YENİDƏN BAŞLA")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .frame(width: 180)
                        .background(Color.yellow)
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: {
                        HapticsManager.shared.playLight()
                        onMenu()
                    }) {
                        Text("ƏSAS MENYU")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(width: 180)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .scaleEffect(appear ? 1.0 : 0.8)
            .opacity(appear ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appear = true
            }
        }
    }
}

fileprivate struct GameOverStat: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(width: 210)
    }
}
