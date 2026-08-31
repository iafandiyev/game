import SwiftUI
import SpriteKit

public struct ZombieGameHUDView: View {
    @ObservedObject var gameState: ZombieGameState
    let onExitToMenu: () -> Void
    
    @State private var scene: ZombieGameScene?
    
    // Left Move Joystick
    @State private var moveOffset: CGSize = .zero
    @State private var moveBaseLoc: CGPoint = CGPoint(x: 100, y: 280)
    @State private var isMoving = false
    
    // Right Aim Joystick
    @State private var aimOffset: CGSize = .zero
    @State private var aimBaseLoc: CGPoint = CGPoint(x: 700, y: 280)
    @State private var isAiming = false
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Main SpriteKit Game View
                if let scene = scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: gameState.is120FpsEnabled ? 120 : 60)
                        .edgesIgnoringSafeArea(.all)
                }
                
                // Top HUD Bar
                VStack {
                    HStack(alignment: .top, spacing: 14) {
                        // Health Bar
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                
                                Text("\(Int(gameState.playerHP)) / \(Int(gameState.playerMaxHP)) HP")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 140, height: 8)
                                
                                let hpRatio = max(0.0, min(1.0, gameState.playerHP / gameState.playerMaxHP))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(hpRatio > 0.4 ? Color.green : Color.red)
                                    .frame(width: 140 * hpRatio, height: 8)
                            }
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.6).cornerRadius(10))
                        
                        // Wave & Zombie count
                        HStack(spacing: 8) {
                            Text("DALĞA \(gameState.currentWave)")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(.yellow)
                            
                            if let sc = scene {
                                Text("🧟 \(sc.zombies.count + sc.waveManager.zombiesRemainingInWave)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6).cornerRadius(10))
                        
                        Spacer()
                        
                        // Cash & Score
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Text("$")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.green)
                                Text("\(gameState.runCash)")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            
                            Text("Xal: \(gameState.currentScore)")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6).cornerRadius(10))
                        
                        // Pause Button
                        Button(action: {
                            HapticsManager.shared.playLight()
                            gameState.isPaused.toggle()
                        }) {
                            Image(systemName: gameState.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    
                    Spacer()
                    
                    // Bottom Controls Bar (Reload & Abilities)
                    HStack(alignment: .bottom) {
                        Spacer()
                        
                        // Quick Action Buttons
                        HStack(spacing: 16) {
                            // Turret Deploy Button
                            Button(action: {
                                scene?.deployTurret()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.8))
                                        .frame(width: 52, height: 52)
                                        .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                                    
                                    VStack(spacing: 1) {
                                        Image(systemName: "shield.righthalf.filled")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                        Text("\(gameState.sentryTurretCount)")
                                            .font(.system(size: 10, weight: .heavy))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(gameState.sentryTurretCount <= 0)
                            .opacity(gameState.sentryTurretCount > 0 ? 1.0 : 0.4)
                            
                            // Grenade Button
                            Button(action: {
                                scene?.throwGrenade()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.85))
                                        .frame(width: 56, height: 56)
                                        .overlay(Circle().stroke(Color.yellow, lineWidth: 2))
                                    
                                    VStack(spacing: 1) {
                                        Image(systemName: "burst.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white)
                                        Text("\(gameState.grenadeCount)")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(gameState.grenadeCount <= 0)
                            .opacity(gameState.grenadeCount > 0 ? 1.0 : 0.4)
                            
                            // Big Reload Button with Ammo Count
                            Button(action: {
                                scene?.manualReload()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.75))
                                        .frame(width: 68, height: 68)
                                        .overlay(
                                            Circle()
                                                .stroke(gameState.isReloading ? Color.yellow : Color.white.opacity(0.3), lineWidth: 3)
                                        )
                                    
                                    if gameState.isReloading {
                                        Circle()
                                            .trim(from: 0.0, to: gameState.reloadProgress)
                                            .stroke(Color.yellow, lineWidth: 4)
                                            .frame(width: 68, height: 68)
                                            .rotationEffect(.degrees(-90))
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(gameState.currentMagAmmo)")
                                            .font(.system(size: 18, weight: .black, design: .monospaced))
                                            .foregroundColor(gameState.currentMagAmmo > 0 ? .white : .red)
                                        Text("RELOAD")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(gameState.isReloading ? .yellow : .white.opacity(0.6))
                                    }
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.trailing, 140)
                    }
                    .padding(.bottom, 20)
                }
                
                // Left Screen Half: Movement Touch Gesture
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    if !isMoving {
                                        isMoving = true
                                        moveBaseLoc = val.startLocation
                                    }
                                    let maxD: CGFloat = 45.0
                                    let dx = val.location.x - moveBaseLoc.x
                                    let dy = val.location.y - moveBaseLoc.y
                                    let dist = sqrt(dx * dx + dy * dy)
                                    
                                    if dist > maxD {
                                        moveOffset = CGSize(width: (dx / dist) * maxD, height: (dy / dist) * maxD)
                                    } else {
                                        moveOffset = CGSize(width: dx, height: dy)
                                    }
                                    
                                    let nx = moveOffset.width / maxD
                                    let ny = -moveOffset.height / maxD // Invert Y for SpriteKit
                                    scene?.moveVector = CGVector(dx: nx, dy: ny)
                                }
                                .onEnded { _ in
                                    isMoving = false
                                    moveOffset = .zero
                                    scene?.moveVector = .zero
                                }
                        )
                    
                    // Right Screen Half: Aim & Fire Touch Gesture
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    if !isAiming {
                                        isAiming = true
                                        aimBaseLoc = val.startLocation
                                    }
                                    let maxD: CGFloat = 45.0
                                    let dx = val.location.x - aimBaseLoc.x
                                    let dy = val.location.y - aimBaseLoc.y
                                    let dist = sqrt(dx * dx + dy * dy)
                                    
                                    if dist > maxD {
                                        aimOffset = CGSize(width: (dx / dist) * maxD, height: (dy / dist) * maxD)
                                    } else {
                                        aimOffset = CGSize(width: dx, height: dy)
                                    }
                                    
                                    let nx = aimOffset.width / maxD
                                    let ny = -aimOffset.height / maxD
                                    scene?.aimVector = CGVector(dx: nx, dy: ny)
                                    scene?.isAimingAndShooting = true
                                }
                                .onEnded { _ in
                                    isAiming = false
                                    aimOffset = .zero
                                    scene?.aimVector = .zero
                                    scene?.isAimingAndShooting = false
                                }
                        )
                }
                
                // Left Joystick Visualizer
                if isMoving {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 90)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 38, height: 38)
                            .offset(moveOffset)
                    }
                    .position(moveBaseLoc)
                    .allowsHitTesting(false)
                }
                
                // Right Joystick Visualizer
                if isAiming {
                    ZStack {
                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .frame(width: 90, height: 90)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 38, height: 38)
                            .offset(aimOffset)
                    }
                    .position(aimBaseLoc)
                    .allowsHitTesting(false)
                }
                
                // Pause Menu
                if gameState.isPaused && !gameState.isGameOver {
                    ZStack {
                        Color.black.opacity(0.75).edgesIgnoringSafeArea(.all)
                        VStack(spacing: 16) {
                            Text("PAUZA")
                                .font(.system(size: 26, weight: .black, design: .monospaced))
                                .foregroundColor(.yellow)
                            
                            HStack(spacing: 14) {
                                Button(action: {
                                    gameState.isPaused = false
                                }) {
                                    Text("DAVAM ET")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.yellow)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    gameState.startNewRun()
                                    scene?.startNewGame()
                                }) {
                                    Text("YENİDƏN BAŞLA")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    onExitToMenu()
                                }) {
                                    Text("MENYUYA ÇIX")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding(24)
                        .background(Color(white: 0.12).cornerRadius(18))
                    }
                }
                
                // Game Over Overlay
                if gameState.isGameOver {
                    ZombieGameOverView(
                        gameState: gameState,
                        onRetry: {
                            gameState.startNewRun()
                            scene?.startNewGame()
                        },
                        onMenu: {
                            onExitToMenu()
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
        let actualSize = CGSize(
            width: size.width > 0 ? size.width : UIScreen.main.bounds.width,
            height: size.height > 0 ? size.height : UIScreen.main.bounds.height
        )
        let sc = ZombieGameScene(size: actualSize)
        sc.scaleMode = .resizeFill
        sc.gameState = gameState
        self.scene = sc
        gameState.startNewRun()
    }
}
