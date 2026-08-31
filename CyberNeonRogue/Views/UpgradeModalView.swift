import SwiftUI

public struct UpgradeModalView: View {
    @ObservedObject var gameState: GameState
    let onPerkSelected: (InGamePerk) -> Void
    public var activePerks: [String: Int]
    
    @State private var availablePerks: [InGamePerk] = []
    @State private var appearAnimation = false
    
    public init(gameState: GameState, activePerks: [String: Int] = [:], onPerkSelected: @escaping (InGamePerk) -> Void) {
        self.gameState = gameState
        self.activePerks = activePerks
        self.onPerkSelected = onPerkSelected
    }
    
    public var body: some View {
        ZStack {
            // Dark glowing overlay
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
                .blur(radius: 2)
            
            VStack(spacing: 22) {
                // Header
                VStack(spacing: 6) {
                    Text("SƏVİYYƏ ATLANDI!")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundColor(gameState.selectedTheme.primaryColor)
                        .shadow(color: gameState.selectedTheme.primaryColor, radius: 10)
                    
                    Text("Səviyyə \(gameState.playerLevel) • Bir gücləndirici seçin")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .scaleEffect(appearAnimation ? 1.0 : 0.6)
                .opacity(appearAnimation ? 1.0 : 0.0)
                
                // 3 Perk Choice Cards
                VStack(spacing: 14) {
                    ForEach(availablePerks) { perk in
                        Button(action: {
                            HapticsManager.shared.playSuccess()
                            AudioManager.shared.playPowerupSound()
                            onPerkSelected(perk)
                        }) {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(perk.rarity.color.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(Circle().stroke(perk.rarity.color, lineWidth: 2))
                                    
                                    Image(systemName: perk.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(perk.rarity.color)
                                }
                                
                                // Text info
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(perk.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(perk.rarity.rawValue)
                                            .font(.system(size: 11, weight: .heavy))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(perk.rarity.color.opacity(0.3))
                                            .foregroundColor(perk.rarity.color)
                                            .cornerRadius(6)
                                    }
                                    
                                    Text(perk.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.75))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("Səviyyə: \(perk.level)/\(perk.maxLevel)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(white: 0.1).opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(perk.rarity.color.opacity(0.8), lineWidth: 1.5)
                                    )
                                    .shadow(color: perk.rarity.color.opacity(0.3), radius: 8)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: appearAnimation ? 0 : 40)
                .opacity(appearAnimation ? 1.0 : 0.0)
            }
        }
        .onAppear {
            let perksMap: [String: Int] = activePerks
            self.availablePerks = UpgradeSystem.shared.getRandomPerks(activePerks: perksMap)
            
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                appearAnimation = true
            }
        }
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
