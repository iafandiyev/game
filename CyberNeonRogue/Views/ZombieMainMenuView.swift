import SwiftUI

public struct ZombieMainMenuView: View {
    @StateObject private var gameState = ZombieGameState.shared
    
    @State private var isPlaying = false
    @State private var showArmory = false
    @State private var showSettings = false
    @State private var pulsePlay = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            if isPlaying {
                ZombieGameHUDView(gameState: gameState) {
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
        .fullScreenCover(isPresented: $showArmory) {
            ArmoryShopView(gameState: gameState)
        }
        .fullScreenCover(isPresented: $showSettings) {
            ZombieSettingsView(gameState: gameState)
        }
    }
    
    private var menuContent: some View {
        ZStack {
            // Dark Apocalyptic Background
            Color(red: 0.05, green: 0.05, blue: 0.07).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Status Bar
                HStack {
                    // Currency
                    HStack(spacing: 6) {
                        Text("$")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.green)
                        Text("\(gameState.cash)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Quick Stats
                    HStack(spacing: 16) {
                        Text("REKORD: \(gameState.highScore)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        
                        Text("MAX DALĞA: \(gameState.highestWave)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("ÖLÜ ZOMBİ: \(gameState.totalZombiesKilled)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer()
                
                // Main Content (Split Landscape Layout)
                HStack(spacing: 30) {
                    // Left Column: Titles & Action Buttons
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DEADZONE")
                                .font(.system(size: 38, weight: .black, design: .monospaced))
                                .foregroundColor(.red)
                                .shadow(color: .red, radius: 10)
                            
                            Text("LAST SURVIVOR • 2D ZOMBIE SHOOTER")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(.yellow)
                                .tracking(2)
                        }
                        
                        // Active Loadout Pill
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                Text(gameState.selectedHero.name)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            
                            Divider().frame(height: 12).background(Color.white.opacity(0.3))
                            
                            HStack(spacing: 4) {
                                Image(systemName: gameState.selectedWeapon.iconName)
                                Text(gameState.selectedWeapon.name)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                        
                        // Action Buttons
                        VStack(spacing: 10) {
                            // Play Button
                            Button(action: {
                                HapticsManager.shared.playHeavy()
                                AudioManager.shared.playRifleShot()
                                withAnimation {
                                    isPlaying = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18))
                                    Text("OYUNA BAŞLA")
                                        .font(.system(size: 16, weight: .black, design: .monospaced))
                                }
                                .foregroundColor(.black)
                                .frame(width: 240)
                                .padding(.vertical, 14)
                                .background(Color.yellow)
                                .cornerRadius(12)
                                .shadow(color: Color.yellow.opacity(0.6), radius: pulsePlay ? 14 : 4)
                            }
                            .scaleEffect(pulsePlay ? 1.02 : 0.98)
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Armory Button
                            Button(action: {
                                HapticsManager.shared.playMedium()
                                showArmory = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                    Text("SİLAHXANA & QƏHRƏMANLAR")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 240)
                                .padding(.vertical, 11)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Settings Button
                            Button(action: {
                                HapticsManager.shared.playLight()
                                showSettings = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape.fill")
                                    Text("TƏNZİMLƏMƏLƏR")
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 240)
                                .padding(.vertical, 9)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    
                    Spacer()
                    
                    // Right Column: Full-Bleed Artwork Banner
                    Image("GameLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 220)
                        .cornerRadius(18)
                        .shadow(color: Color.red.opacity(0.6), radius: 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                        )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulsePlay = true
            }
        }
    }
}
