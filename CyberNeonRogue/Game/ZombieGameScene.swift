import SpriteKit
import SwiftUI
import UIKit

public final class ZombieGameScene: SKScene, SKPhysicsContactDelegate {
    
    public weak var gameState: ZombieGameState?
    
    // Entities
    public var survivor: SurvivorHeroNode?
    public var zombies: [ZombieNode] = []
    public var projectiles: [ProjectileNode] = []
    public var drops: [DropItemNode] = []
    public var explosiveBarrels: [SKShapeNode] = []
    
    // Systems
    public let waveManager = ZombieWaveManager()
    
    // Input vectors
    public var moveVector: CGVector = .zero
    public var aimVector: CGVector = .zero
    public var isAimingAndShooting: Bool = false
    
    // World layers (for screen shake)
    private let worldNode = SKNode()
    private let floorLayer = SKNode()
    private let entityLayer = SKNode()
    private let vfxLayer = SKNode()
    private let hudOverlayLayer = SKNode()
    
    private var lastUpdateTime: TimeInterval = 0
    private var waveBreakTimer: TimeInterval = 0
    private var isBetweenWaves: Bool = false
    
    // MARK: - Scene Setup
    
    override public func didMove(to view: SKView) {
        self.backgroundColor = SKColor(red: 0.05, green: 0.06, blue: 0.07, alpha: 1.0)
        self.physicsWorld.gravity = .zero
        self.physicsWorld.contactDelegate = self
        
        addChild(worldNode)
        worldNode.addChild(floorLayer)
        worldNode.addChild(entityLayer)
        worldNode.addChild(vfxLayer)
        addChild(hudOverlayLayer)
        
        setupAtmosphericArena()
        startNewGame()
    }
    
    private func setupAtmosphericArena() {
        floorLayer.removeAllChildren()
        
        // 1. Dark Asphalt Grid & Concrete Tiles
        let grid = SKShapeNode()
        let path = CGMutablePath()
        let step: CGFloat = 55
        
        for x in stride(from: 0, to: self.size.width, by: step) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: self.size.height))
        }
        for y in stride(from: 0, to: self.size.height, by: step) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: self.size.width, y: y))
        }
        grid.path = path
        grid.strokeColor = SKColor.white.withAlphaComponent(0.035)
        grid.lineWidth = 1.0
        floorLayer.addChild(grid)
        
        // 2. Ruined Road Asphalt Cracks / Details
        for _ in 0..<12 {
            let cx = CGFloat.random(in: 40...(self.size.width - 40))
            let cy = CGFloat.random(in: 40...(self.size.height - 40))
            let crack = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 20...60), height: CGFloat.random(in: 2...4)), cornerRadius: 1)
            crack.fillColor = SKColor.black.withAlphaComponent(0.4)
            crack.strokeColor = .clear
            crack.position = CGPoint(x: cx, y: cy)
            crack.zRotation = CGFloat.random(in: 0...CGFloat.pi)
            floorLayer.addChild(crack)
        }
        
        // 3. Floating Atmospheric Dust/Fog Motes
        let dustEmitter = SKEmitterNode()
        dustEmitter.particleTexture = BloodDecalFactory.circleTexture
        dustEmitter.particlePosition = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        dustEmitter.particlePositionRange = CGVector(dx: self.size.width, dy: self.size.height)
        dustEmitter.particleBirthRate = 25
        dustEmitter.particleLifetime = 6.0
        dustEmitter.particleSpeed = 15
        dustEmitter.particleSpeedRange = 10
        dustEmitter.emissionAngleRange = CGFloat.pi * 2
        dustEmitter.particleScale = 0.15
        dustEmitter.particleScaleRange = 0.1
        dustEmitter.particleAlpha = 0.15
        dustEmitter.particleColor = SKColor.white
        dustEmitter.zPosition = 1
        floorLayer.addChild(dustEmitter)
    }
    
    private func spawnExplosiveBarrels() {
        for b in explosiveBarrels { b.removeFromParent() }
        explosiveBarrels.removeAll()
        
        let barrelPositions: [CGPoint] = [
            CGPoint(x: self.size.width * 0.25, y: self.size.height * 0.35),
            CGPoint(x: self.size.width * 0.75, y: self.size.height * 0.35),
            CGPoint(x: self.size.width * 0.25, y: self.size.height * 0.70),
            CGPoint(x: self.size.width * 0.75, y: self.size.height * 0.70)
        ]
        
        for pos in barrelPositions {
            let barrel = SKShapeNode(circleOfRadius: 14)
            barrel.fillColor = SKColor(red: 0.85, green: 0.15, blue: 0.1, alpha: 1.0)
            barrel.strokeColor = .yellow
            barrel.lineWidth = 1.5
            barrel.position = pos
            barrel.zPosition = 8
            
            let label = SKLabelNode(text: "☣")
            label.fontSize = 13
            label.fontColor = .yellow
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            barrel.addChild(label)
            
            let body = SKPhysicsBody(circleOfRadius: 15)
            body.isDynamic = false
            body.categoryBitMask = ZombiePhysicsCategory.obstacle
            body.contactTestBitMask = ZombiePhysicsCategory.playerBullet
            barrel.physicsBody = body
            
            entityLayer.addChild(barrel)
            explosiveBarrels.append(barrel)
        }
    }
    
    public func startNewGame() {
        for z in zombies { z.removeFromParent() }
        for p in projectiles { p.removeFromParent() }
        for d in drops { d.removeFromParent() }
        survivor?.removeFromParent()
        
        zombies.removeAll()
        projectiles.removeAll()
        drops.removeAll()
        
        guard let state = gameState else { return }
        
        // Spawn Survivor in the center
        let hero = SurvivorHeroNode(hero: state.selectedHero, weapon: state.selectedWeapon)
        hero.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        entityLayer.addChild(hero)
        self.survivor = hero
        
        spawnExplosiveBarrels()
        
        waveManager.startWave(waveNumber: 1)
        isBetweenWaves = false
        state.currentWave = 1
        state.currentMagAmmo = hero.currentMag
        state.playerHP = hero.currentHealth
        state.playerMaxHP = hero.maxHealth
    }
    
    // MARK: - Screen Shake Engine
    
    public func triggerScreenShake(intensity: CGFloat, duration: TimeInterval) {
        worldNode.removeAction(forKey: "screenShake")
        
        let numberOfShakes = Int(duration / 0.02)
        var actions: [SKAction] = []
        
        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            let move = SKAction.move(to: CGPoint(x: dx, y: dy), duration: 0.02)
            actions.append(move)
        }
        actions.append(SKAction.move(to: .zero, duration: 0.02))
        
        worldNode.run(SKAction.sequence(actions), withKey: "screenShake")
    }
    
    // MARK: - Update Loop
    
    override public func update(_ currentTime: TimeInterval) {
        guard let state = gameState, !state.isPaused, !state.isGameOver else { return }
        
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(0.08, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        guard let survivor = survivor else { return }
        
        // 1. Move Player
        if moveVector != .zero {
            let speed = survivor.moveSpeed * CGFloat(state.joystickSensitivity)
            let mx = moveVector.dx * speed * CGFloat(dt)
            let my = moveVector.dy * speed * CGFloat(dt)
            
            survivor.position.x = max(35, min(self.size.width - 35, survivor.position.x + mx))
            survivor.position.y = max(35, min(self.size.height - 35, survivor.position.y + my))
            
            let moveAngle = atan2(moveVector.dy, moveVector.dx)
            survivor.updateMovementAnim(isMoving: true, moveAngle: moveAngle, dt: dt)
        } else {
            survivor.updateMovementAnim(isMoving: false, moveAngle: 0, dt: dt)
        }
        
        // 2. Aim & Shoot
        if isAimingAndShooting && aimVector != .zero {
            let aimAngle = atan2(aimVector.dy, aimVector.dx)
            survivor.setAimAngle(aimAngle)
            
            if survivor.canShoot(currentTime: currentTime) {
                fireSurvivorWeapon(currentTime: currentTime, aimAngle: aimAngle)
            }
        }
        
        // Update Reloading
        let reloadStatus = survivor.updateReload(dt: dt)
        state.isReloading = survivor.isReloading
        state.reloadProgress = reloadStatus.progress
        state.currentMagAmmo = survivor.currentMag
        state.playerHP = survivor.currentHealth
        
        // 3. Update Zombies AI
        for zombie in zombies {
            zombie.updateAI(playerPosition: survivor.position, dt: dt) { [weak self] spitterPos, spitAngle in
                self?.spawnAcidSpit(from: spitterPos, angle: spitAngle)
            }
        }
        
        // 4. Update Projectiles & Boundaries
        for proj in projectiles {
            if proj.position.x < -60 || proj.position.x > self.size.width + 60 || proj.position.y < -60 || proj.position.y > self.size.height + 60 {
                proj.removeFromParent()
            }
        }
        projectiles.removeAll(where: { $0.parent == nil })
        
        // 5. Wave Progression
        if !isBetweenWaves {
            waveManager.update(
                dt: dt,
                arenaSize: self.size,
                onSpawn: { [weak self] type, pos in
                    self?.spawnZombie(type: type, at: pos)
                },
                onBossSpawn: { [weak self] pos in
                    self?.spawnBossZombie(at: pos)
                }
            )
            
            // Check if wave is cleared
            if waveManager.zombiesRemainingInWave <= 0 && zombies.isEmpty {
                startWaveBreak()
            }
        } else {
            waveBreakTimer += dt
            if waveBreakTimer >= 3.5 {
                advanceToNextWave()
            }
        }
    }
    
    // MARK: - Weapon Firing
    
    private func fireSurvivorWeapon(currentTime: TimeInterval, aimAngle: CGFloat) {
        guard let survivor = survivor, let state = gameState else { return }
        
        survivor.recordShot(currentTime: currentTime)
        state.currentMagAmmo = survivor.currentMag
        HapticsManager.shared.playLight()
        
        let weapon = survivor.currentWeapon
        let spawnPos = CGPoint(
            x: survivor.position.x + cos(aimAngle) * 30,
            y: survivor.position.y + sin(aimAngle) * 30
        )
        
        // Muzzle Flash
        let flash = BloodDecalFactory.createMuzzleFlash(at: spawnPos, angle: aimAngle)
        vfxLayer.addChild(flash)
        
        // Ejected Shell Casing
        let casing = BloodDecalFactory.createShellCasing(at: survivor.position, angle: aimAngle)
        floorLayer.addChild(casing)
        
        switch weapon.id {
        case "shotgun":
            AudioManager.shared.playShotgunShot()
            triggerScreenShake(intensity: 5.0, duration: 0.12)
            for _ in 0..<weapon.pelletCount {
                let spread = CGFloat.random(in: -weapon.spreadAngle...weapon.spreadAngle)
                let finalAngle = aimAngle + spread
                let pellet = ProjectileNode(kind: .shotgunPellet, damage: weapon.currentDamage, angle: finalAngle)
                pellet.position = spawnPos
                pellet.physicsBody?.velocity = CGVector(dx: cos(finalAngle) * weapon.bulletSpeed, dy: sin(finalAngle) * weapon.bulletSpeed)
                vfxLayer.addChild(pellet)
                projectiles.append(pellet)
            }
            
        case "ak47":
            AudioManager.shared.playRifleShot()
            triggerScreenShake(intensity: 2.2, duration: 0.08)
            let spread = CGFloat.random(in: -weapon.spreadAngle...weapon.spreadAngle)
            let finalAngle = aimAngle + spread
            let bullet = ProjectileNode(kind: .bullet, damage: weapon.currentDamage, angle: finalAngle)
            bullet.position = spawnPos
            bullet.physicsBody?.velocity = CGVector(dx: cos(finalAngle) * weapon.bulletSpeed, dy: sin(finalAngle) * weapon.bulletSpeed)
            vfxLayer.addChild(bullet)
            projectiles.append(bullet)
            
        case "minigun":
            AudioManager.shared.playMinigunShot()
            triggerScreenShake(intensity: 3.0, duration: 0.06)
            let spread = CGFloat.random(in: -weapon.spreadAngle...weapon.spreadAngle)
            let finalAngle = aimAngle + spread
            let bullet = ProjectileNode(kind: .bullet, damage: weapon.currentDamage, angle: finalAngle)
            bullet.position = spawnPos
            bullet.physicsBody?.velocity = CGVector(dx: cos(finalAngle) * weapon.bulletSpeed, dy: sin(finalAngle) * weapon.bulletSpeed)
            vfxLayer.addChild(bullet)
            projectiles.append(bullet)
            
        case "flamethrower":
            AudioManager.shared.playFlamethrower()
            let spread = CGFloat.random(in: -weapon.spreadAngle...weapon.spreadAngle)
            let finalAngle = aimAngle + spread
            let flame = ProjectileNode(kind: .flamethrower, damage: weapon.currentDamage, angle: finalAngle)
            flame.position = spawnPos
            flame.physicsBody?.velocity = CGVector(dx: cos(finalAngle) * weapon.bulletSpeed, dy: sin(finalAngle) * weapon.bulletSpeed)
            vfxLayer.addChild(flame)
            projectiles.append(flame)
            
        case "rpg":
            AudioManager.shared.playRifleShot()
            triggerScreenShake(intensity: 6.0, duration: 0.15)
            let rocket = ProjectileNode(kind: .rocket, damage: weapon.currentDamage, angle: aimAngle)
            rocket.position = spawnPos
            rocket.physicsBody?.velocity = CGVector(dx: cos(aimAngle) * weapon.bulletSpeed, dy: sin(aimAngle) * weapon.bulletSpeed)
            vfxLayer.addChild(rocket)
            projectiles.append(rocket)
            
        default: // Pistol
            AudioManager.shared.playPistolShot()
            triggerScreenShake(intensity: 1.5, duration: 0.05)
            let bullet = ProjectileNode(kind: .bullet, damage: weapon.currentDamage, angle: aimAngle)
            bullet.position = spawnPos
            bullet.physicsBody?.velocity = CGVector(dx: cos(aimAngle) * weapon.bulletSpeed, dy: sin(aimAngle) * weapon.bulletSpeed)
            vfxLayer.addChild(bullet)
            projectiles.append(bullet)
        }
    }
    
    // MARK: - Action Buttons
    
    public func manualReload() {
        survivor?.startReload()
    }
    
    public func throwGrenade() {
        guard let survivor = survivor, let state = gameState, state.grenadeCount > 0 else { return }
        state.grenadeCount -= 1
        HapticsManager.shared.playMedium()
        
        let grenade = ProjectileNode(kind: .grenade, damage: 280, angle: survivor.aimAngle)
        grenade.position = survivor.position
        
        let throwDistance: CGFloat = 170.0
        let targetPoint = CGPoint(
            x: survivor.position.x + cos(survivor.aimAngle) * throwDistance,
            y: survivor.position.y + sin(survivor.aimAngle) * throwDistance
        )
        
        vfxLayer.addChild(grenade)
        
        let move = SKAction.move(to: targetPoint, duration: 0.6)
        move.timingMode = .easeOut
        
        grenade.run(SKAction.sequence([
            move,
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self, weak grenade] in
                guard let self = self, let grenade = grenade else { return }
                self.triggerExplosion(at: grenade.position, radius: grenade.explosionRadius, damage: grenade.damage)
                grenade.removeFromParent()
            }
        ]))
    }
    
    public func deployTurret() {
        guard let survivor = survivor, let state = gameState, state.sentryTurretCount > 0 else { return }
        state.sentryTurretCount -= 1
        HapticsManager.shared.playSuccess()
        
        let turret = SKShapeNode(circleOfRadius: 18)
        turret.fillColor = SKColor.darkGray
        turret.strokeColor = .cyan
        turret.lineWidth = 2.5
        turret.glowWidth = 4.0
        turret.position = CGPoint(x: survivor.position.x, y: survivor.position.y - 20)
        entityLayer.addChild(turret)
        
        let autoShoot = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: 0.22),
            SKAction.run { [weak self, weak turret] in
                guard let self = self, let turret = turret else { return }
                guard let target = self.zombies.first(where: { $0.parent != nil }) else { return }
                
                let dx = target.position.x - turret.position.x
                let dy = target.position.y - turret.position.y
                let angle = atan2(dy, dx)
                
                AudioManager.shared.playPistolShot()
                let bullet = ProjectileNode(kind: .bullet, damage: 38, angle: angle)
                bullet.position = turret.position
                bullet.physicsBody?.velocity = CGVector(dx: cos(angle) * 880, dy: sin(angle) * 880)
                self.vfxLayer.addChild(bullet)
                self.projectiles.append(bullet)
            }
        ]), count: 45) // 10s
        
        turret.run(SKAction.sequence([
            autoShoot,
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Spawning
    
    private func spawnZombie(type: ZombieType, at point: CGPoint) {
        let zombie = ZombieNode(type: type, wave: waveManager.currentWave)
        zombie.position = point
        entityLayer.addChild(zombie)
        zombies.append(zombie)
    }
    
    private func spawnBossZombie(at point: CGPoint) {
        AudioManager.shared.playBossRoar()
        HapticsManager.shared.playWarning()
        triggerScreenShake(intensity: 8.0, duration: 0.6)
        
        let boss = ZombieNode(type: .abominationBoss(name: "ABOMINATION TITAN", maxHp: CGFloat(1300 + waveManager.currentWave * 600)), wave: waveManager.currentWave)
        boss.position = point
        entityLayer.addChild(boss)
        zombies.append(boss)
    }
    
    private func spawnAcidSpit(from origin: CGPoint, angle: CGFloat) {
        let acid = ProjectileNode(kind: .acidSpit, damage: 20, angle: angle, isPlayer: false)
        acid.position = origin
        acid.physicsBody?.velocity = CGVector(dx: cos(angle) * 340, dy: sin(angle) * 340)
        vfxLayer.addChild(acid)
        projectiles.append(acid)
    }
    
    // MARK: - Physics & Collisions
    
    public func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // Bullet <-> Zombie / Boss
        if mask == (ZombiePhysicsCategory.playerBullet | ZombiePhysicsCategory.zombie) ||
           mask == (ZombiePhysicsCategory.playerBullet | ZombiePhysicsCategory.boss) {
            let bulletBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.playerBullet ? contact.bodyA : contact.bodyB
            let zombieBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.playerBullet ? contact.bodyB : contact.bodyA
            
            if let bullet = bulletBody.node as? ProjectileNode, let zombie = zombieBody.node as? ZombieNode {
                hitZombie(zombie: zombie, with: bullet, contactPoint: contact.contactPoint)
            }
        }
        
        // Bullet <-> Explosive Barrel
        else if mask == (ZombiePhysicsCategory.playerBullet | ZombiePhysicsCategory.obstacle) {
            let bulletBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.playerBullet ? contact.bodyA : contact.bodyB
            let barrelBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.playerBullet ? contact.bodyB : contact.bodyA
            
            if let barrel = barrelBody.node as? SKShapeNode, explosiveBarrels.contains(barrel) {
                bulletBody.node?.removeFromParent()
                barrel.removeFromParent()
                explosiveBarrels.removeAll(where: { $0 == barrel })
                triggerExplosion(at: barrel.position, radius: 180, damage: 350)
            }
        }
        
        // Player <-> Zombie Attack
        else if mask == (ZombiePhysicsCategory.player | ZombiePhysicsCategory.zombie) ||
                mask == (ZombiePhysicsCategory.player | ZombiePhysicsCategory.boss) {
            let zombieBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.player ? contact.bodyB : contact.bodyA
            if let zombie = zombieBody.node as? ZombieNode {
                playerAttacked(by: zombie)
            }
        }
        
        // Player <-> Zombie Acid Projectile
        else if mask == (ZombiePhysicsCategory.player | ZombiePhysicsCategory.zombieProjectile) {
            let projBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.zombieProjectile ? contact.bodyA : contact.bodyB
            if let proj = projBody.node as? ProjectileNode {
                proj.removeFromParent()
                playerHitByAcid(damage: proj.damage)
            }
        }
        
        // Player <-> DropItem
        else if mask == (ZombiePhysicsCategory.player | ZombiePhysicsCategory.dropItem) {
            let dropBody = contact.bodyA.categoryBitMask == ZombiePhysicsCategory.dropItem ? contact.bodyA : contact.bodyB
            if let drop = dropBody.node as? DropItemNode {
                collectDrop(drop: drop)
            }
        }
    }
    
    private func hitZombie(zombie: ZombieNode, with bullet: ProjectileNode, contactPoint: CGPoint) {
        if bullet.kind == .rocket {
            bullet.removeFromParent()
            triggerExplosion(at: contactPoint, radius: bullet.explosionRadius, damage: bullet.damage)
            return
        }
        
        if bullet.kind != .flamethrower {
            bullet.pierceCount -= 1
            if bullet.pierceCount <= 0 {
                bullet.removeFromParent()
            }
        }
        
        // Blood Spray VFX
        let isAcid = (zombie.zombieType == .acidSpitter)
        let bloodSpray = BloodDecalFactory.createBloodSpray(at: contactPoint, angle: bullet.zRotation, isAcid: isAcid)
        vfxLayer.addChild(bloodSpray)
        
        // Floating Damage Popup
        let isCrit = Double.random(in: 0...1.0) < 0.2
        let actualDmg = isCrit ? bullet.damage * 1.5 : bullet.damage
        let dmgPopup = BloodDecalFactory.createDamagePopup(at: zombie.position, damage: Int(actualDmg), isCrit: isCrit)
        vfxLayer.addChild(dmgPopup)
        
        // Knockback calculation
        let knockback: CGFloat = (bullet.kind == .shotgunPellet) ? 38 : 12
        let isDead = zombie.takeDamage(actualDmg, knockbackAngle: bullet.zRotation, knockbackForce: knockback)
        
        if isDead {
            destroyZombie(zombie: zombie, wasExplosion: false)
        }
    }
    
    private func destroyZombie(zombie: ZombieNode, wasExplosion: Bool) {
        guard zombie.parent != nil else { return }
        
        AudioManager.shared.playZombieDeath()
        
        // Floor blood decal
        let isAcid = (zombie.zombieType == .acidSpitter)
        let bloodDecal = BloodDecalFactory.createBloodDecal(at: zombie.position, isGreenAcid: isAcid)
        floorLayer.addChild(bloodDecal)
        
        // Flying zombie flesh chunks (Gibs)
        let gibs = BloodDecalFactory.createZombieGibs(at: zombie.position, isAcid: isAcid)
        for g in gibs { floorLayer.addChild(g) }
        
        // State updates
        gameState?.runCash += zombie.cashValue
        gameState?.currentScore += zombie.cashValue * 10
        gameState?.runKills += 1
        
        // Boomer Explosion on death
        if case .boomer = zombie.zombieType {
            triggerExplosion(at: zombie.position, radius: 120, damage: 50)
        }
        
        // Drop Lottery (28% chance)
        if Double.random(in: 0...1.0) < 0.28 {
            spawnDrop(at: zombie.position)
        }
        
        zombie.removeFromParent()
        zombies.removeAll(where: { $0 == zombie })
    }
    
    private func spawnDrop(at point: CGPoint) {
        let rand = Double.random(in: 0...1.0)
        let kind: DropItemKind
        if rand < 0.45 {
            kind = .cashBag(amount: Int.random(in: 30...90))
        } else if rand < 0.75 {
            kind = .ammoCrate
        } else if rand < 0.92 {
            kind = .medkit
        } else {
            kind = .sentryTurret
        }
        
        let drop = DropItemNode(kind: kind)
        drop.position = point
        entityLayer.addChild(drop)
        drops.append(drop)
    }
    
    private func collectDrop(drop: DropItemNode) {
        guard let survivor = survivor, let state = gameState else { return }
        drop.removeFromParent()
        drops.removeAll(where: { $0 == drop })
        
        switch drop.kind {
        case .medkit:
            AudioManager.shared.playMedkitPick()
            HapticsManager.shared.playSuccess()
            survivor.heal(40)
            state.playerHP = survivor.currentHealth
            
        case .ammoCrate:
            AudioManager.shared.playAmmoPick()
            HapticsManager.shared.playSuccess()
            survivor.currentMag = survivor.currentWeapon.currentMagSize
            survivor.isReloading = false
            state.currentMagAmmo = survivor.currentMag
            
        case .cashBag(let amount):
            AudioManager.shared.playAmmoPick()
            state.runCash += amount
            
        case .sentryTurret:
            AudioManager.shared.playAmmoPick()
            state.sentryTurretCount += 1
        }
    }
    
    private func playerAttacked(by zombie: ZombieNode) {
        guard let survivor = survivor, let state = gameState else { return }
        triggerScreenShake(intensity: 6.0, duration: 0.15)
        let isDead = survivor.takeDamage(zombie.damage)
        state.playerHP = survivor.currentHealth
        
        if isDead {
            AudioManager.shared.playZombieGrowl()
            survivor.removeFromParent()
            state.endRun()
        }
    }
    
    private func playerHitByAcid(damage: CGFloat) {
        guard let survivor = survivor, let state = gameState else { return }
        triggerScreenShake(intensity: 5.0, duration: 0.12)
        let isDead = survivor.takeDamage(damage)
        state.playerHP = survivor.currentHealth
        if isDead {
            survivor.removeFromParent()
            state.endRun()
        }
    }
    
    private func triggerExplosion(at point: CGPoint, radius: CGFloat, damage: CGFloat) {
        AudioManager.shared.playExplosionSound()
        HapticsManager.shared.playHeavy()
        triggerScreenShake(intensity: 9.0, duration: 0.3)
        
        let explosion = BloodDecalFactory.createExplosion(at: point, radius: radius)
        vfxLayer.addChild(explosion)
        
        // Damage nearby zombies
        for zombie in zombies {
            let dx = zombie.position.x - point.x
            let dy = zombie.position.y - point.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist <= radius {
                let falloff = 1.0 - (dist / radius)
                let dmg = damage * falloff
                if zombie.takeDamage(dmg, knockbackAngle: atan2(dy, dx), knockbackForce: 45) {
                    destroyZombie(zombie: zombie, wasExplosion: true)
                }
            }
        }
        
        // Damage player if close
        if let survivor = survivor {
            let dx = survivor.position.x - point.x
            let dy = survivor.position.y - point.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist <= radius * 0.7 {
                _ = survivor.takeDamage(35)
                gameState?.playerHP = survivor.currentHealth
            }
        }
    }
    
    // MARK: - Wave Break & Advance
    
    private func startWaveBreak() {
        isBetweenWaves = true
        waveBreakTimer = 0
        AudioManager.shared.playMedkitPick()
        HapticsManager.shared.playSuccess()
        
        let label = SKLabelNode(text: "DALĞA \(waveManager.currentWave) TƏMİZLƏNDİ! (+$250)")
        label.fontName = "HelveticaNeue-Black"
        label.fontSize = 24
        label.fontColor = .green
        label.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 40)
        vfxLayer.addChild(label)
        
        gameState?.runCash += 250
        
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }
    
    private func advanceToNextWave() {
        isBetweenWaves = false
        let nextWave = waveManager.currentWave + 1
        waveManager.startWave(waveNumber: nextWave)
        gameState?.currentWave = nextWave
        
        // Respawn barrels on new wave
        spawnExplosiveBarrels()
        
        survivor?.heal(25)
        gameState?.playerHP = survivor?.currentHealth ?? 100
        
        let label = SKLabelNode(text: "DALĞA \(nextWave) BAŞLAYIR!")
        label.fontName = "HelveticaNeue-Black"
        label.fontSize = 26
        label.fontColor = (nextWave % 5 == 0) ? .red : .yellow
        label.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2 + 40)
        vfxLayer.addChild(label)
        
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ]))
    }
}
