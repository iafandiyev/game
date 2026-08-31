import SwiftUI
import SpriteKit

public struct GameContainerView: View {
    @ObservedObject var gameState: GameState
    let onExitToMenu: () -> Void
    
    @State private var scene: GameScene?
    @State private var joystickDragOffset: CGSize = .zero
    @State private var joystickBaseLocation: CGPoint = CGPoint(x: 100, y: 650)
    @State private var isTouching = false
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // SpriteKit Main Game View
                if let scene = scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: gameState.is120FpsEnabled ? 120 : 60)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // HUD Overlay (Top & Sides)
                VStack(spacing: 0) {
                    // Top Bar: Health, Shield, Score, Wave, Pause
                    HStack(alignment: .top, spacing: 14) {
                        // Health & Shield Bars
                        VStack(alignment: .leading, spacing: 4) {
                            // Health Bar
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 7)
                                    
                                    if let p = scene?.player {
                                        let hpRatio = max(0.0, min(1.0, p.currentHealth / p.maxHealth))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.red)
                                            .frame(width: 100 * hpRatio, height: 7)
                                    }
                                }
                            }
                            
                            // Shield Bar
                            HStack(spacing: 6) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.cyan)
                                
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 5)
                                    
                                    if let p = scene?.player {
                                        let shieldRatio = max(0.0, min(1.0, p.currentShield / p.maxShield))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.cyan)
                                            .frame(width: 100 * shieldRatio, height: 5)
                                    }
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.4).cornerRadius(10))
                        
                        Spacer()
                        
                        // Score & Crystals
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(gameState.currentScore)")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                                Text("\(gameState.runCrystals)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        // Pause Button
                        Button(action: {
                            HapticsManager.shared.playLight()
                            gameState.isPaused.toggle()
                        }) {
                            Image(systemName: gameState.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 46)
                    
                    // Wave Counter Indicator
                    HStack {
                        Text("DALĞA \(gameState.currentWave)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(gameState.selectedTheme.primaryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(gameState.selectedTheme.primaryColor.opacity(0.5), lineWidth: 1))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // XP Progress Bar
                    VStack(spacing: 3) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 5)
                            
                            let xpRatio = max(0.0, min(1.0, Double(gameState.playerXP / gameState.playerNextLevelXP)))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(gameState.selectedTheme.primaryColor)
                                .frame(width: (geo.size.width - 32) * xpRatio, height: 5)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    
                    Spacer()
                    
                    // Time Dilation Warning if active
                    if let s = scene, s.timeDilationTimer > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "hourglass")
                            Text("KVANT MATRİSİ: ZAMAN YAVAŞLADILDI (\(String(format: "%.1f", s.timeDilationTimer))s)")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.7).cornerRadius(20))
                        .padding(.bottom, 120)
                    }
                }
                
                // Virtual Touch / Joystick Area
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isTouching {
                                    isTouching = true
                                    joystickBaseLocation = value.startLocation
                                }
                                
                                let maxDist: CGFloat = 50.0
                                let dx = value.location.x - joystickBaseLocation.x
                                let dy = value.location.y - joystickBaseLocation.y
                                let dist = sqrt(dx * dx + dy * dy)
                                
                                if dist > maxDist {
                                    joystickDragOffset = CGSize(width: (dx / dist) * maxDist, height: (dy / dist) * maxDist)
                                } else {
                                    joystickDragOffset = CGSize(width: dx, height: dy)
                                }
                                
                                // Normalized vector (Y inverted for SpriteKit)
                                let normDx = joystickDragOffset.width / maxDist
                                let normDy = -joystickDragOffset.height / maxDist
                                scene?.joystickOffset = CGVector(dx: normDx, dy: normDy)
                            }
                            .onEnded { _ in
                                isTouching = false
                                joystickDragOffset = .zero
                                scene?.joystickOffset = .zero
                            }
                    )
                
                // Dynamic Virtual Joystick Visualizer
                if isTouching {
                    ZStack {
                        Circle()
                            .stroke(gameState.selectedTheme.primaryColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .background(Circle().fill(Color.black.opacity(0.2)))
                        
                        Circle()
                            .fill(gameState.selectedTheme.primaryColor.opacity(0.8))
                            .frame(width: 44, height: 44)
                            .offset(joystickDragOffset)
                            .shadow(color: gameState.selectedTheme.primaryColor, radius: 8)
                    }
                    .position(joystickBaseLocation)
                    .allowsHitTesting(false)
                }
                
                // Pause Menu Modal
                if gameState.isPaused && !gameState.isLevelingUp && !gameState.isGameOver {
                    ZStack {
                        Color.black.opacity(0.75).edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 20) {
                            Text("PAUZA")
                                .font(.system(size: 28, weight: .black, design: .monospaced))
                                .foregroundColor(gameState.selectedTheme.primaryColor)
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    gameState.isPaused = false
                                }) {
                                    Text("DAVAM ET")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(gameState.selectedTheme.primaryColor)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    gameState.startNewRun()
                                    scene?.startNewGame()
                                }) {
                                    Text("YENİDƏN BAŞLA")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    onExitToMenu()
                                }) {
                                    Text("MENYUYA ÇIX")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.9))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.red.opacity(0.15))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(24)
                        .background(Color(white: 0.12).cornerRadius(20))
                        .padding(.horizontal, 30)
                    }
                }
                
                // Level-Up Upgrade Modal
                if gameState.isLevelingUp {
                    UpgradeModalView(gameState: gameState) { selectedPerk in
                        applyPerk(selectedPerk)
                        gameState.isLevelingUp = false
                        gameState.isPaused = false
                    }
                }
                
                // Game Over View
                if gameState.isGameOver {
                    GameOverView(
                        gameState: gameState,
                        onRetry: {
                            gameState.startNewRun()
                            scene?.startNewGame()
                        },
                        onMenu: {
                            onExitToMenu()
                        },
                        onRevive: {
                            if let p = scene?.player {
                                p.currentHealth = p.maxHealth
                                p.currentShield = p.maxShield
                                p.triggerInvulnerability(duration: 4.0)
                                gameState.isGameOver = false
                                gameState.isPaused = false
                            }
                        }
                    )
                }
            }
            .onAppear {
                setupScene(size: geo.size)
            }
        }
        .statusBar(hidden: true)
    }
    
    private func setupScene(size: CGSize) {
        let sc = GameScene(size: size)
        sc.scaleMode = .resizeFill
        sc.gameState = gameState
        self.scene = sc
        gameState.startNewRun()
    }
    
    private func applyPerk(_ perk: InGamePerk) {
        guard let p = scene?.player else { return }
        p.activePerks[perk.id, default: 0] += 1
        
        switch perk.id {
        case "orbital_drone":
            p.updateOrbitalDrones(count: p.activePerks["orbital_drone"] ?? 1)
        case "shield_overcharge":
            p.currentShield = p.maxShield + CGFloat((p.activePerks["shield_overcharge"] ?? 1) * 25)
        default:
            break
        }
    }
}
