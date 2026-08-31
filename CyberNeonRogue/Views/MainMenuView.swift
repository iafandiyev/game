import SwiftUI

public struct MainMenuView: View {
    @StateObject private var gameState = GameState.shared
    
    @State private var isPlaying = false
    @State private var showShop = false
    @State private var showSettings = false
    @State private var pulseLogo = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if isPlaying {
                GameContainerView(gameState: gameState) {
                    withAnimation {
                        isPlaying = false
                    }
                }
                .transition(.opacity)
            } else {
                menuContent
                    .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showShop) {
            ShopView(gameState: gameState)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(gameState: gameState)
        }
    }
    
    private var menuContent: some View {
        ZStack {
            gameState.selectedTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Top Bar with Crystal Counter & Settings Icon
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        Text("\(gameState.cyberCrystals)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(14)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticsManager.shared.playLight()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Pulsing Cyber Neon Logo & Emblem
                VStack(spacing: 14) {
                    Image("GameLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 125, height: 125)
                        .cornerRadius(28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(gameState.selectedTheme.primaryColor, lineWidth: 2)
                        )
                        .shadow(color: gameState.selectedTheme.primaryColor.opacity(0.7), radius: pulseLogo ? 20 : 8)
                        .scaleEffect(pulseLogo ? 1.03 : 0.98)
                    
                    VStack(spacing: 3) {
                        Text("CYBER NEON")
                            .font(.system(size: 32, weight: .black, design: .monospaced))
                            .foregroundColor(gameState.selectedTheme.primaryColor)
                            .shadow(color: gameState.selectedTheme.primaryColor, radius: pulseLogo ? 16 : 6)
                        
                        Text("QUANTUM ROGUE")
                            .font(.system(size: 16, weight: .heavy, design: .monospaced))
                            .foregroundColor(gameState.selectedTheme.secondaryColor)
                            .tracking(4)
                            .shadow(color: gameState.selectedTheme.secondaryColor, radius: 8)
                    }
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        pulseLogo = true
                    }
                }
                
                // Active Ship Display
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(gameState.selectedTheme.primaryColor.opacity(0.12))
                            .frame(width: 110, height: 110)
                            .overlay(Circle().stroke(gameState.selectedTheme.primaryColor.opacity(0.5), lineWidth: 2))
                            .shadow(color: gameState.selectedTheme.primaryColor.opacity(0.3), radius: 15)
                        
                        Image(systemName: gameState.selectedShip.iconName)
                            .font(.system(size: 52))
                            .foregroundColor(gameState.selectedTheme.primaryColor)
                    }
                    
                    Text(gameState.selectedShip.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Əsas Silah: \(gameState.selectedShip.primaryWeapon.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 14) {
                    // Play Button
                    Button(action: {
                        HapticsManager.shared.playHeavy()
                        AudioManager.shared.playPowerupSound()
                        withAnimation {
                            isPlaying = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                            Text("OYUNA BAŞLA")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(gameState.selectedTheme.primaryColor)
                        .cornerRadius(16)
                        .shadow(color: gameState.selectedTheme.primaryColor.opacity(0.6), radius: 14)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Shop / Hangar Button
                    Button(action: {
                        HapticsManager.shared.playMedium()
                        showShop = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                            Text("KİBER ANQAR & MAĞAZA")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                
                // Bottom Quick Stats Banner
                HStack(spacing: 20) {
                    StatPill(title: "REKORD", value: "\(gameState.highScore)")
                    StatPill(title: "MAX DALĞA", value: "\(gameState.highestWave)")
                    StatPill(title: "MƏHV EDİLƏN", value: "\(gameState.totalEnemiesDestroyed)")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

fileprivate struct StatPill: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
        .cornerRadius(10)
    }
}
