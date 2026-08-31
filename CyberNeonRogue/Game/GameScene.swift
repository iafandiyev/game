import SpriteKit
import SwiftUI
import UIKit

public final class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // References
    public weak var gameState: GameState?
    
    // Entities
    public var player: PlayerNode?
    public var enemies: [EnemyNode] = []
    public var bullets: [BulletNode] = []
    public var powerUps: [PowerUpNode] = []
    
    // Systems
    public let waveManager = WaveManager()
    
    // Joystick & Input
    public var joystickOffset: CGVector = .zero
    public var isTouchingJoystick: Bool = false
    public var touchStartLocation: CGPoint = .zero
    
    // Time & Effects
    private var lastUpdateTime: TimeInterval = 0
    public var timeDilationTimer: TimeInterval = 0
    public var timeDilationFactor: CGFloat = 1.0
    
    // Screen shake
    private var shakeNode = SKNode()
    
    // MARK: - Scene Lifecycle
    
    override public func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.physicsWorld.gravity = .zero
        self.physicsWorld.contactDelegate = self
        
        setupSceneHierarchy()
        startNewGame()
    }
    
    private func setupSceneHierarchy() {
        addChild(shakeNode)
        
        // Starfield background
        let starfield = ParticleFactory.createStarfield(sceneSize: self.size)
        shakeNode.addChild(starfield)
    }
    
    public func startNewGame() {
        // Clear all previous
        for e in enemies { e.removeFromParent() }
        for b in bullets { b.removeFromParent() }
        for p in powerUps { p.removeFromParent() }
        player?.removeFromParent()
        
        enemies.removeAll()
        bullets.removeAll()
        powerUps.removeAll()
        
        waveManager.reset()
        
        guard let state = gameState else { return }
        
        // Spawn Player with upgraded permanent stats
        let p = PlayerNode(
            ship: state.selectedShip,
            bonusHP: state.getUpgradeBonus(for: "hp"),
            bonusShield: state.getUpgradeBonus(for: "shield"),
            bonusDamage: state.getUpgradeBonus(for: "damage"),
            bonusFireRate: state.getUpgradeBonus(for: "firerate"),
            bonusMagnet: state.getUpgradeBonus(for: "magnet"),
            bonusCrit: state.getUpgradeBonus(for: "crit")
        )
        p.position = CGPoint(x: self.size.width / 2, y: 150)
        shakeNode.addChild(p)
        self.player = p
    }
    
    // MARK: - Update Loop
    
    override public func update(_ currentTime: TimeInterval) {
        guard let state = gameState, !state.isPaused, !state.isGameOver else { return }
        
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(0.1, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        guard let player = player else { return }
        
        // Handle Time Dilation (Matrix slow)
        if timeDilationTimer > 0 {
            timeDilationTimer -= dt
            timeDilationFactor = 0.25
        } else {
            timeDilationFactor = 1.0
        }
        
        // 1. Move Player by Joystick
        if joystickOffset != .zero {
            let speed = player.shipModel.baseSpeed * player.speedMultiplier * CGFloat(state.joystickSensitivity)
            let moveX = joystickOffset.dx * speed * CGFloat(dt)
            let moveY = joystickOffset.dy * speed * CGFloat(dt)
            
            player.position.x = max(30, min(self.size.width - 30, player.position.x + moveX))
            player.position.y = max(60, min(self.size.height - 80, player.position.y + moveY))
            player.applyTilt(vector: joystickOffset)
        } else {
            player.applyTilt(vector: .zero)
        }
        
        player.updateState(dt: dt)
        
        // 2. Weapon Auto-Fire Logic
        handleWeapons(currentTime: currentTime, dt: dt)
        
        // 3. Update Enemies
        for enemy in enemies {
            enemy.updateAI(playerPosition: player.position, timeDilationFactor: timeDilationFactor, dt: dt)
            
            // Enemy Shooting
            enemy.shootTimer += dt * Double(timeDilationFactor)
            if enemy.shootTimer >= 2.0 {
                enemy.shootTimer = 0
                spawnEnemyBullet(from: enemy)
            }
            
            // Remove if past bottom screen
            if enemy.position.y < -50 {
                enemy.removeFromParent()
            }
        }
        enemies.removeAll(where: { $0.parent == nil })
        
        // 4. Update Homing Bullets & Bounds
        for bullet in bullets {
            bullet.updateHoming(dt: dt)
            if bullet.position.y > self.size.height + 50 || bullet.position.y < -50 || bullet.position.x < -50 || bullet.position.x > self.size.width + 50 {
                bullet.removeFromParent()
            }
        }
        bullets.removeAll(where: { $0.parent == nil })
        
        // 5. Magnetize PowerUps and Gems
        let magnetRange = player.magnetRadius
        for powerUp in powerUps {
            let dx = player.position.x - powerUp.position.x
            let dy = player.position.y - powerUp.position.y
            let dist = sqrt(dx * dx + dy * dy)
            
            if dist <= magnetRange || (player.activePerks["quantum_magnet"] ?? 0) > 0 {
                let speed: CGFloat = dist < 50 ? 550 : 350
                powerUp.magnetizeTowards(target: player.position, speed: speed, dt: dt)
            }
            
            if powerUp.position.y < -40 {
                powerUp.removeFromParent()
            }
        }
        powerUps.removeAll(where: { $0.parent == nil })
        
        // 6. Wave Progression
        waveManager.update(
            dt: dt,
            onSpawnEnemy: { [weak self] type, pos in
                self?.spawnEnemy(type: type, at: pos)
            },
            onBossSpawn: { [weak self] in
                self?.spawnBoss()
            },
            onWaveComplete: { [weak self] newWave in
                self?.handleWaveCompleted(newWave: newWave)
            }
        )
    }
    
    // MARK: - Weapon System
    
    private func handleWeapons(currentTime: TimeInterval, dt: TimeInterval) {
        guard let player = player else { return }
        
        let fireRate = player.shipModel.baseFireRate * Double(player.fireRateMultiplier)
        let ratePerk = Double(player.activePerks["hyper_drive"] ?? 0) * 0.18
        let actualFireInterval = max(0.12, fireRate - ratePerk)
        
        if currentTime - player.lastFireTime >= actualFireInterval {
            player.lastFireTime = currentTime
            firePlayerWeapons()
        }
        
        // Vortex Perk auto cast
        let vortexLvl = player.activePerks["vortex_bomb"] ?? 0
        if vortexLvl > 0 && currentTime - player.lastVortexTime >= max(4.0, 9.0 - Double(vortexLvl) * 1.5) {
            player.lastVortexTime = currentTime
            fireVortexSingularity()
        }
    }
    
    private func firePlayerWeapons() {
        guard let player = player else { return }
        
        let multishotLvl = player.activePerks["multishot"] ?? 0
        let plasmaLvl = player.activePerks["plasma_charge"] ?? 0
        let freezeLvl = player.activePerks["cryo_freeze"] ?? 0
        let isQuad = player.quadDamageTimer > 0
        
        var baseDmg = (player.shipModel.baseDamage + CGFloat(plasmaLvl * 12)) * player.damageMultiplier
        if isQuad { baseDmg *= 4.0 }
        
        let isCrit = Double.random(in: 0...1.0) < Double(player.critChance)
        let finalDamage = isCrit ? (baseDmg * 2.2) : baseDmg
        
        switch player.shipModel.primaryWeapon {
        case .laser:
            AudioManager.shared.playLaserSound()
            let bulletCount = 1 + multishotLvl
            let spreadAngle: CGFloat = 0.14
            
            for i in 0..<bulletCount {
                let bullet = BulletNode(kind: .playerLaser, damage: finalDamage, isPlayer: true, isCritical: isCrit)
                bullet.position = CGPoint(x: player.position.x, y: player.position.y + 20)
                bullet.isFreezing = (freezeLvl > 0)
                
                let angleOffset = (CGFloat(i) - CGFloat(bulletCount - 1) / 2.0) * spreadAngle
                let bulletAngle = .pi / 2 + angleOffset
                bullet.zRotation = angleOffset
                
                let speed: CGFloat = 850.0
                bullet.physicsBody?.velocity = CGVector(dx: cos(bulletAngle) * speed, dy: sin(bulletAngle) * speed)
                
                shakeNode.addChild(bullet)
                bullets.append(bullet)
            }
            
        case .plasma:
            AudioManager.shared.playPlasmaSound()
            let bullet = BulletNode(kind: .playerPlasma, damage: finalDamage * 1.6, isPlayer: true, isCritical: isCrit)
            bullet.position = CGPoint(x: player.position.x, y: player.position.y + 24)
            bullet.isFreezing = (freezeLvl > 0)
            bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 650)
            shakeNode.addChild(bullet)
            bullets.append(bullet)
            
        case .tesla:
            AudioManager.shared.playTeslaSound()
            let bullet = BulletNode(kind: .playerTesla, damage: finalDamage * 1.2, isPlayer: true, isCritical: isCrit)
            bullet.position = CGPoint(x: player.position.x, y: player.position.y + 22)
            bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 900)
            shakeNode.addChild(bullet)
            bullets.append(bullet)
            
        case .homing:
            AudioManager.shared.playLaserSound(pitch: 620)
            for i in 0..<2 {
                let bullet = BulletNode(kind: .playerHoming, damage: finalDamage * 0.9, isPlayer: true, isCritical: isCrit)
                bullet.position = CGPoint(x: player.position.x + (i == 0 ? -16 : 16), y: player.position.y)
                bullet.targetEnemy = enemies.randomElement()
                bullet.physicsBody?.velocity = CGVector(dx: (i == 0 ? -120 : 120), dy: 450)
                shakeNode.addChild(bullet)
                bullets.append(bullet)
            }
            
        default:
            break
        }
    }
    
    private func fireVortexSingularity() {
        guard let player = player else { return }
        let vortex = BulletNode(kind: .playerVortex, damage: 180, isPlayer: true)
        vortex.position = CGPoint(x: player.position.x, y: player.position.y + 120)
        vortex.physicsBody?.velocity = CGVector(dx: 0, dy: 150)
        shakeNode.addChild(vortex)
        bullets.append(vortex)
        
        AudioManager.shared.playPowerupSound()
        
        // Auto explode vortex after 3.5 seconds
        vortex.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.5),
            SKAction.run { [weak self, weak vortex] in
                guard let vortex = vortex else { return }
                self?.triggerExplosion(at: vortex.position, color: .magenta, isBig: true)
                vortex.removeFromParent()
            }
        ]))
    }
    
    // MARK: - Spawners
    
    public func spawnEnemy(type: EnemyType, at point: CGPoint) {
        let enemy = EnemyNode(type: type, wave: waveManager.currentWave)
        enemy.position = point
        shakeNode.addChild(enemy)
        enemies.append(enemy)
    }
    
    public func spawnBoss() {
        AudioManager.shared.playBossAlarm()
        HapticsManager.shared.playWarning()
        
        let bossName = "CYBER TITAN MK-\(waveManager.currentWave)"
        let boss = EnemyNode(type: .boss(name: bossName, maxHp: CGFloat(1000 + waveManager.currentWave * 450)), wave: waveManager.currentWave)
        boss.position = CGPoint(x: self.size.width / 2, y: self.size.height + 60)
        shakeNode.addChild(boss)
        enemies.append(boss)
    }
    
    private func spawnEnemyBullet(from enemy: EnemyNode) {
        guard enemy.parent != nil else { return }
        
        if enemy.isBoss {
            // Boss 3-way spread attack
            for offset in [-0.25, 0.0, 0.25] {
                let bullet = BulletNode(kind: .enemyBossLaser, damage: 25, isPlayer: false)
                bullet.position = CGPoint(x: enemy.position.x, y: enemy.position.y - 30)
                let angle = -.pi / 2 + offset
                let speed: CGFloat = 400.0
                bullet.physicsBody?.velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
                shakeNode.addChild(bullet)
                bullets.append(bullet)
            }
        } else if case .cruiser = enemy.enemyType {
            let bullet = BulletNode(kind: .enemyBullet, damage: 18, isPlayer: false)
            bullet.position = CGPoint(x: enemy.position.x, y: enemy.position.y - 20)
            bullet.physicsBody?.velocity = CGVector(dx: 0, dy: -320)
            shakeNode.addChild(bullet)
            bullets.append(bullet)
        } else if case .scout = enemy.enemyType {
            let bullet = BulletNode(kind: .enemyBullet, damage: 12, isPlayer: false)
            bullet.position = CGPoint(x: enemy.position.x, y: enemy.position.y - 15)
            bullet.physicsBody?.velocity = CGVector(dx: 0, dy: -280)
            shakeNode.addChild(bullet)
            bullets.append(bullet)
        }
    }
    
    private func handleWaveCompleted(newWave: Int) {
        gameState?.currentWave = newWave
        HapticsManager.shared.playSuccess()
        
        // Floating announcement text
        let label = SKLabelNode(text: "DALĞA \(newWave) BAŞLADI!")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 28
        label.fontColor = .cyan
        label.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 50)
        label.alpha = 0
        shakeNode.addChild(label)
        
        label.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.wait(forDuration: 1.0),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Physics & Collisions
    
    public func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Bullet <-> Enemy / Boss
        if mask == (PhysicsCategory.playerBullet | PhysicsCategory.enemy) ||
           mask == (PhysicsCategory.playerBullet | PhysicsCategory.boss) {
            let bulletBody = contact.bodyA.categoryBitMask == PhysicsCategory.playerBullet ? contact.bodyA : contact.bodyB
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.playerBullet ? contact.bodyB : contact.bodyA
            
            if let bullet = bulletBody.node as? BulletNode, let enemy = enemyBody.node as? EnemyNode {
                hitEnemy(enemy: enemy, with: bullet, contactPoint: contact.contactPoint)
            }
        }
        
        // Player <-> Enemy Bullet
        else if mask == (PhysicsCategory.player | PhysicsCategory.enemyBullet) {
            let bulletBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemyBullet ? contact.bodyA : contact.bodyB
            if let bullet = bulletBody.node as? BulletNode {
                bullet.removeFromParent()
                playerHit(damage: bullet.damage)
            }
        }
        
        // Player <-> Enemy Crash
        else if mask == (PhysicsCategory.player | PhysicsCategory.enemy) {
            let enemyBody = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA : contact.bodyB
            if let enemy = enemyBody.node as? EnemyNode {
                playerHit(damage: 25)
                destroyEnemy(enemy: enemy)
            }
        }
        
        // Player <-> PowerUp
        else if mask == (PhysicsCategory.player | PhysicsCategory.powerUp) {
            let powerUpBody = contact.bodyA.categoryBitMask == PhysicsCategory.powerUp ? contact.bodyA : contact.bodyB
            if let powerUp = powerUpBody.node as? PowerUpNode {
                collectPowerUp(powerUp: powerUp)
            }
        }
    }
    
    private func hitEnemy(enemy: EnemyNode, with bullet: BulletNode, contactPoint: CGPoint) {
        if bullet.kind != .playerVortex {
            bullet.removeFromParent()
        }
        
        // Show damage number
        showDamageNumber(amount: bullet.damage, at: contactPoint, isCrit: bullet.isCritical)
        
        if bullet.isFreezing {
            enemy.applyFreeze(duration: 2.0)
        }
        
        // Tesla Chain Reaction Perk
        let teslaLvl = player?.activePerks["tesla_chain"] ?? 0
        if teslaLvl > 0 && Double.random(in: 0...1.0) < 0.4 {
            triggerTeslaChain(from: enemy.position, jumps: teslaLvl + 1, damage: bullet.damage * 0.6)
        }
        
        let isDead = enemy.takeDamage(bullet.damage)
        if isDead {
            destroyEnemy(enemy: enemy)
        }
    }
    
    private func triggerTeslaChain(from origin: CGPoint, jumps: Int, damage: CGFloat) {
        var currentOrigin = origin
        let potentialTargets = enemies.filter { $0.position != origin && $0.currentHealth > 0 }
        let selectedTargets = potentialTargets.prefix(jumps)
        
        for target in selectedTargets {
            // Draw electric line
            let path = CGMutablePath()
            path.move(to: currentOrigin)
            path.addLine(to: target.position)
            
            let line = SKShapeNode(path: path)
            line.strokeColor = SKColor(red: 0.9, green: 0.2, blue: 1.0, alpha: 1.0)
            line.lineWidth = 2.5
            line.glowWidth = 4.0
            shakeNode.addChild(line)
            line.run(SKAction.sequence([SKAction.wait(forDuration: 0.12), SKAction.removeFromParent()]))
            
            showDamageNumber(amount: damage, at: target.position, isCrit: false)
            if target.takeDamage(damage) {
                destroyEnemy(enemy: target)
            }
            currentOrigin = target.position
        }
    }
    
    private func destroyEnemy(enemy: EnemyNode) {
        guard enemy.parent != nil else { return }
        
        AudioManager.shared.playExplosionSound(isBig: enemy.isBoss)
        HapticsManager.shared.playMedium()
        
        triggerExplosion(at: enemy.position, color: enemy.isBoss ? .yellow : .red, isBig: enemy.isBoss)
        
        // Score & State
        gameState?.currentScore += enemy.scoreValue
        gameState?.runKills += 1
        
        // Drop XP Gem
        let gem = PowerUpNode(kind: .expGem(amount: enemy.expAmount, color: enemy.isBoss ? .yellow : .cyan))
        gem.position = enemy.position
        shakeNode.addChild(gem)
        powerUps.append(gem)
        
        // Drop Cyber Crystal
        if Double.random(in: 0...1.0) < enemy.crystalDropChance {
            let crystal = PowerUpNode(kind: .cyberCrystal(value: enemy.isBoss ? 20 : 2))
            crystal.position = CGPoint(x: enemy.position.x + CGFloat.random(in: -15...15), y: enemy.position.y + CGFloat.random(in: -15...15))
            shakeNode.addChild(crystal)
            powerUps.append(crystal)
        }
        
        // Drop Rare Special Powerup (10% chance)
        if Double.random(in: 0...1.0) < 0.10 {
            let kinds: [PowerUpKind] = [.nukeEMP, .timeDilation, .superShield, .quadDamage]
            if let selectedKind = kinds.randomElement() {
                let powerNode = PowerUpNode(kind: selectedKind)
                powerNode.position = CGPoint(x: enemy.position.x + 10, y: enemy.position.y)
                shakeNode.addChild(powerNode)
                powerUps.append(powerNode)
            }
        }
        
        if enemy.isBoss {
            gameState?.totalBossesDefeated += 1
            waveManager.forceNextWave { [weak self] newWave in
                self?.handleWaveCompleted(newWave: newWave)
            }
        }
        
        enemy.removeFromParent()
    }
    
    private func playerHit(damage: CGFloat) {
        guard let player = player else { return }
        
        shakeCamera(intensity: 12)
        let isDead = player.takeDamage(damage)
        
        if isDead {
            triggerExplosion(at: player.position, color: .cyan, isBig: true)
            player.removeFromParent()
            HapticsManager.shared.playError()
            gameState?.endRun()
        }
    }
    
    private func collectPowerUp(powerUp: PowerUpNode) {
        guard let player = player, let state = gameState else { return }
        
        powerUp.removeFromParent()
        
        switch powerUp.kind {
        case .expGem(let amount, _):
            AudioManager.shared.playCoinSound()
            state.playerXP += amount
            if state.playerXP >= state.playerNextLevelXP {
                levelUpPlayer()
            }
            
        case .cyberCrystal(let value):
            AudioManager.shared.playCoinSound()
            state.runCrystals += value
            
        case .nukeEMP:
            AudioManager.shared.playExplosionSound(isBig: true)
            HapticsManager.shared.playHeavy()
            shakeCamera(intensity: 18)
            let shockwave = ParticleFactory.createShockwaveRing(at: player.position, color: .red, maxRadius: 500)
            shakeNode.addChild(shockwave)
            
            for enemy in enemies where !enemy.isBoss {
                destroyEnemy(enemy: enemy)
            }
            
        case .timeDilation:
            AudioManager.shared.playPowerupSound()
            HapticsManager.shared.playSuccess()
            timeDilationTimer = 6.0
            
        case .superShield:
            AudioManager.shared.playPowerupSound()
            HapticsManager.shared.playSuccess()
            player.currentShield = player.maxShield
            player.triggerInvulnerability(duration: 4.0)
            
        case .quadDamage:
            AudioManager.shared.playPowerupSound()
            HapticsManager.shared.playSuccess()
            player.quadDamageTimer = 8.0
        }
    }
    
    private func levelUpPlayer() {
        guard let state = gameState else { return }
        state.playerLevel += 1
        state.playerXP -= state.playerNextLevelXP
        state.playerNextLevelXP = CGFloat(Int(Double(state.playerNextLevelXP) * 1.35))
        
        AudioManager.shared.playLevelUpSound()
        HapticsManager.shared.playSuccess()
        
        state.isLevelingUp = true
        state.isPaused = true
    }
    
    // MARK: - Visual & Sound Helpers
    
    private func showDamageNumber(amount: CGFloat, at point: CGPoint, isCrit: Bool) {
        let label = SKLabelNode(text: "\(Int(amount))\(isCrit ? "!" : "")")
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = isCrit ? 20 : 15
        label.fontColor = isCrit ? .yellow : .white
        label.position = CGPoint(x: point.x + CGFloat.random(in: -10...10), y: point.y)
        label.blendMode = .add
        shakeNode.addChild(label)
        
        let moveUp = SKAction.moveBy(x: CGFloat.random(in: -12...12), y: 35, duration: 0.45)
        let fadeOut = SKAction.fadeOut(withDuration: 0.45)
        let group = SKAction.group([moveUp, fadeOut])
        label.run(SKAction.sequence([group, SKAction.removeFromParent()]))
    }
    
    private func triggerExplosion(at point: CGPoint, color: SKColor, isBig: Bool) {
        let emitter = ParticleFactory.createExplosion(at: point, color: color, scale: isBig ? 2.2 : 1.0)
        shakeNode.addChild(emitter)
    }
    
    private func shakeCamera(intensity: CGFloat) {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: CGFloat.random(in: -intensity...intensity), y: CGFloat.random(in: -intensity...intensity), duration: 0.04),
            SKAction.moveBy(x: CGFloat.random(in: -intensity...intensity), y: CGFloat.random(in: -intensity...intensity), duration: 0.04),
            SKAction.move(to: .zero, duration: 0.04)
        ])
        shakeNode.run(shake)
    }
}
