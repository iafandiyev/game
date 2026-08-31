import SpriteKit
import UIKit

public final class SurvivorHeroNode: SKNode {
    public let heroModel: HeroModel
    public var currentWeapon: WeaponModel
    public var maxHealth: CGFloat
    public var currentHealth: CGFloat
    public var moveSpeed: CGFloat
    public var armorReduction: CGFloat
    
    // Weapon State
    public var currentMag: Int
    public var isReloading: Bool = false
    public var reloadTimer: TimeInterval = 0
    public var lastShotTime: TimeInterval = 0
    public var aimAngle: CGFloat = 0
    
    // Visual Nodes
    private var shadowNode: SKShapeNode?
    private var bodyContainer: SKNode = SKNode()
    private var torsoNode: SKShapeNode?
    private var headNode: SKShapeNode?
    private var leftArmNode: SKNode = SKNode()
    private var rightArmNode: SKNode = SKNode()
    private var gunContainer: SKNode = SKNode()
    private var flashlightCone: SKShapeNode?
    private var laserSight: SKShapeNode?
    private var healthBarFg: SKShapeNode?
    private var reloadBadge: SKNode = SKNode()
    private var reloadProgressCircle: SKShapeNode?
    private var leftLeg: SKShapeNode?
    private var rightLeg: SKShapeNode?
    
    private var walkAnimTimer: CGFloat = 0
    public var isInvulnerable: Bool = false
    
    public init(hero: HeroModel, weapon: WeaponModel) {
        self.heroModel = hero
        self.currentWeapon = weapon
        self.maxHealth = hero.baseHealth
        self.currentHealth = self.maxHealth
        self.moveSpeed = hero.baseSpeed
        self.armorReduction = hero.armorReduction
        self.currentMag = weapon.currentMagSize
        super.init()
        
        setupHighDetailVisuals()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - AAA Visual Setup
    
    private func setupHighDetailVisuals() {
        self.zPosition = 10
        
        // 1. Soft Dynamic Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 38, height: 26))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.38)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -1
        addChild(shadow)
        self.shadowNode = shadow
        
        // 2. Legs (with combat boots)
        let lLeg = SKShapeNode(rectOf: CGSize(width: 9, height: 16), cornerRadius: 3)
        lLeg.fillColor = SKColor(red: 0.16, green: 0.18, blue: 0.16, alpha: 1.0)
        lLeg.strokeColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1.0)
        lLeg.lineWidth = 1.0
        lLeg.position = CGPoint(x: -7, y: -6)
        addChild(lLeg)
        self.leftLeg = lLeg
        
        let rLeg = SKShapeNode(rectOf: CGSize(width: 9, height: 16), cornerRadius: 3)
        rLeg.fillColor = SKColor(red: 0.16, green: 0.18, blue: 0.16, alpha: 1.0)
        rLeg.strokeColor = SKColor(red: 0.08, green: 0.10, blue: 0.08, alpha: 1.0)
        rLeg.lineWidth = 1.0
        rLeg.position = CGPoint(x: 7, y: -6)
        addChild(rLeg)
        self.rightLeg = rLeg
        
        // 3. Rotating Body Container (turns with aiming direction)
        addChild(bodyContainer)
        
        // Tactical Flashlight Cone (Projected from soldier's chest forward)
        let lightPath = CGMutablePath()
        lightPath.move(to: CGPoint(x: 10, y: 0))
        lightPath.addLine(to: CGPoint(x: 240, y: -70))
        lightPath.addLine(to: CGPoint(x: 250, y: 0))
        lightPath.addLine(to: CGPoint(x: 240, y: 70))
        lightPath.closeSubpath()
        let light = SKShapeNode(path: lightPath)
        light.fillColor = SKColor(red: 1.0, green: 0.98, blue: 0.85, alpha: 0.14)
        light.strokeColor = .clear
        light.blendMode = .add
        light.zPosition = 1
        bodyContainer.addChild(light)
        self.flashlightCone = light
        
        // Tactical Backpack
        let pack = SKShapeNode(rectOf: CGSize(width: 14, height: 18), cornerRadius: 4)
        pack.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.12, alpha: 1.0)
        pack.strokeColor = .black
        pack.position = CGPoint(x: -12, y: 0)
        bodyContainer.addChild(pack)
        
        // Main Torso / Heavy Kevlar Armor
        let torso = SKShapeNode(rectOf: CGSize(width: 24, height: 26), cornerRadius: 6)
        torso.fillColor = heroModel.id == "juggernaut" ? SKColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0) : SKColor(red: 0.22, green: 0.28, blue: 0.22, alpha: 1.0) // Camo Olive
        torso.strokeColor = SKColor(red: 0.08, green: 0.12, blue: 0.08, alpha: 1.0)
        torso.lineWidth = 1.5
        bodyContainer.addChild(torso)
        self.torsoNode = torso
        
        // Tactical Plate Carrier / Ammo Pouches
        let vest = SKShapeNode(rectOf: CGSize(width: 16, height: 18), cornerRadius: 4)
        vest.fillColor = SKColor(red: 0.14, green: 0.16, blue: 0.14, alpha: 1.0)
        vest.strokeColor = .black
        vest.lineWidth = 1.0
        torso.addChild(vest)
        
        // Shoulder Armor Pauldrons
        let lShoulder = SKShapeNode(circleOfRadius: 6)
        lShoulder.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.18, alpha: 1.0)
        lShoulder.strokeColor = .black
        lShoulder.position = CGPoint(x: 0, y: -14)
        bodyContainer.addChild(lShoulder)
        
        let rShoulder = SKShapeNode(circleOfRadius: 6)
        rShoulder.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.18, alpha: 1.0)
        rShoulder.strokeColor = .black
        rShoulder.position = CGPoint(x: 0, y: 14)
        bodyContainer.addChild(rShoulder)
        
        // Head / Fast-Ops Tactical Helmet
        let head = SKShapeNode(circleOfRadius: 11)
        head.fillColor = SKColor(red: 0.16, green: 0.20, blue: 0.16, alpha: 1.0)
        head.strokeColor = .black
        head.lineWidth = 1.2
        head.position = CGPoint(x: 0, y: 0)
        bodyContainer.addChild(head)
        self.headNode = head
        
        // Dual Glowing Night-Vision Visor / Goggles
        let visor = SKShapeNode(rectOf: CGSize(width: 7, height: 12), cornerRadius: 2)
        visor.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 1.0) // Glowing Crimson
        visor.strokeColor = .yellow
        visor.lineWidth = 0.5
        visor.glowWidth = 4.0
        visor.position = CGPoint(x: 8, y: 0)
        head.addChild(visor)
        
        // Arms & Gun
        bodyContainer.addChild(gunContainer)
        setupDetailedGun()
        
        // Laser Sight Line
        let laserPath = CGMutablePath()
        laserPath.move(to: CGPoint(x: 28, y: 5))
        laserPath.addLine(to: CGPoint(x: 220, y: 5))
        let laser = SKShapeNode(path: laserPath)
        laser.strokeColor = SKColor.red.withAlphaComponent(0.4)
        laser.lineWidth = 1.0
        laser.glowWidth = 2.5
        laser.blendMode = .add
        gunContainer.addChild(laser)
        self.laserSight = laser
        
        // 4. Floating HUD Elements (Health bar & Reload badge)
        setupStatusOverlays()
    }
    
    private func setupDetailedGun() {
        gunContainer.removeAllChildren()
        
        let gun = SKNode()
        
        switch currentWeapon.id {
        case "shotgun":
            // Heavy Spas-12
            let barrel = SKShapeNode(rectOf: CGSize(width: 26, height: 6), cornerRadius: 1.5)
            barrel.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            barrel.strokeColor = .black
            barrel.position = CGPoint(x: 20, y: 5)
            gun.addChild(barrel)
            
            let heatShield = SKShapeNode(rectOf: CGSize(width: 14, height: 8), cornerRadius: 1)
            heatShield.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
            heatShield.strokeColor = .black
            heatShield.position = CGPoint(x: 16, y: 5)
            gun.addChild(heatShield)
            
        case "ak47":
            // AK-74M with banana curved magazine
            let barrel = SKShapeNode(rectOf: CGSize(width: 28, height: 5), cornerRadius: 1.5)
            barrel.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
            barrel.strokeColor = .black
            barrel.position = CGPoint(x: 22, y: 5)
            gun.addChild(barrel)
            
            let mag = SKShapeNode(rectOf: CGSize(width: 8, height: 10), cornerRadius: 2)
            mag.fillColor = SKColor(red: 0.45, green: 0.25, blue: 0.10, alpha: 1.0) // Wood/Bakelite
            mag.strokeColor = .black
            mag.position = CGPoint(x: 15, y: 1)
            gun.addChild(mag)
            
        case "minigun":
            // Vulcan Minigun with triple barrels
            let barrels = SKShapeNode(rectOf: CGSize(width: 32, height: 10), cornerRadius: 2)
            barrels.fillColor = SKColor.darkGray
            barrels.strokeColor = .black
            barrels.position = CGPoint(x: 24, y: 5)
            gun.addChild(barrels)
            
            let drum = SKShapeNode(circleOfRadius: 8)
            drum.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            drum.strokeColor = .yellow
            drum.lineWidth = 1.0
            drum.position = CGPoint(x: 12, y: 5)
            gun.addChild(drum)
            
        case "flamethrower":
            // Inferno Flamethrower
            let nozzle = SKShapeNode(rectOf: CGSize(width: 26, height: 8), cornerRadius: 2)
            nozzle.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1.0)
            nozzle.strokeColor = .orange
            nozzle.position = CGPoint(x: 22, y: 5)
            gun.addChild(nozzle)
            
        case "rpg":
            // RPG-7 Rocket Launcher
            let tube = SKShapeNode(rectOf: CGSize(width: 32, height: 7), cornerRadius: 1.5)
            tube.fillColor = SKColor(red: 0.25, green: 0.35, blue: 0.25, alpha: 1.0)
            tube.strokeColor = .black
            tube.position = CGPoint(x: 22, y: 5)
            gun.addChild(tube)
            
            let warhead = SKShapeNode(rectOf: CGSize(width: 10, height: 10), cornerRadius: 2)
            warhead.fillColor = SKColor(red: 0.1, green: 0.7, blue: 0.2, alpha: 1.0)
            warhead.strokeColor = .black
            warhead.position = CGPoint(x: 36, y: 5)
            gun.addChild(warhead)
            
        default:
            // Tactical Pistol M9
            let slide = SKShapeNode(rectOf: CGSize(width: 18, height: 5), cornerRadius: 1.5)
            slide.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            slide.strokeColor = .black
            slide.position = CGPoint(x: 18, y: 5)
            gun.addChild(slide)
        }
        
        // Hands holding the gun
        let lHand = SKShapeNode(circleOfRadius: 4.5)
        lHand.fillColor = SKColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0) // Gloves
        lHand.strokeColor = .black
        lHand.position = CGPoint(x: 14, y: -4)
        gun.addChild(lHand)
        
        let rHand = SKShapeNode(circleOfRadius: 4.5)
        rHand.fillColor = SKColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1.0)
        rHand.strokeColor = .black
        rHand.position = CGPoint(x: 22, y: 4)
        gun.addChild(rHand)
        
        gunContainer.addChild(gun)
    }
    
    private func setupStatusOverlays() {
        // Health Bar
        let hpBg = SKShapeNode(rectOf: CGSize(width: 48, height: 6), cornerRadius: 2.5)
        hpBg.fillColor = SKColor.black.withAlphaComponent(0.7)
        hpBg.strokeColor = SKColor.white.withAlphaComponent(0.2)
        hpBg.lineWidth = 0.5
        hpBg.position = CGPoint(x: 0, y: 32)
        hpBg.zPosition = 30
        addChild(hpBg)
        
        let hpFg = SKShapeNode(rectOf: CGSize(width: 48, height: 6), cornerRadius: 2.5)
        hpFg.fillColor = .green
        hpFg.strokeColor = .clear
        hpFg.position = CGPoint(x: 0, y: 32)
        hpFg.zPosition = 31
        addChild(hpFg)
        self.healthBarFg = hpFg
        
        // Reload Badge
        reloadBadge.position = CGPoint(x: 0, y: 44)
        reloadBadge.zPosition = 32
        reloadBadge.isHidden = true
        
        let rCircleBg = SKShapeNode(circleOfRadius: 10)
        rCircleBg.fillColor = SKColor.black.withAlphaComponent(0.8)
        rCircleBg.strokeColor = .yellow
        rCircleBg.lineWidth = 1.5
        reloadBadge.addChild(rCircleBg)
        
        let rLabel = SKLabelNode(text: "R")
        rLabel.fontName = "HelveticaNeue-Black"
        rLabel.fontSize = 11
        rLabel.fontColor = .yellow
        rLabel.verticalAlignmentMode = .center
        rLabel.horizontalAlignmentMode = .center
        reloadBadge.addChild(rLabel)
        
        addChild(reloadBadge)
    }
    
    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = ZombiePhysicsCategory.player
        body.contactTestBitMask = ZombiePhysicsCategory.zombie | ZombiePhysicsCategory.boss | ZombiePhysicsCategory.zombieProjectile | ZombiePhysicsCategory.dropItem
        body.collisionBitMask = ZombiePhysicsCategory.obstacle
        self.physicsBody = body
    }
    
    // MARK: - Aiming, Movement & Recoil
    
    public func setAimAngle(_ angle: CGFloat) {
        self.aimAngle = angle
        self.bodyContainer.zRotation = angle
    }
    
    public func triggerGunRecoil() {
        let kickBack = SKAction.moveBy(x: -4, y: 0, duration: 0.04)
        let returnPos = SKAction.moveBy(x: 4, y: 0, duration: 0.08)
        gunContainer.run(SKAction.sequence([kickBack, returnPos]))
    }
    
    public func updateMovementAnim(isMoving: Bool, moveAngle: CGFloat, dt: TimeInterval) {
        if isMoving {
            walkAnimTimer += CGFloat(dt) * 14.0
            leftLeg?.position.y = -6 + sin(walkAnimTimer) * 6
            rightLeg?.position.y = -6 - sin(walkAnimTimer) * 6
            leftLeg?.position.x = -7 + cos(walkAnimTimer) * 2
            rightLeg?.position.x = 7 - cos(walkAnimTimer) * 2
            
            // Subtle body breathing bob
            bodyContainer.position.y = sin(walkAnimTimer * 2) * 1.5
        } else {
            leftLeg?.position = CGPoint(x: -7, y: -6)
            rightLeg?.position = CGPoint(x: 7, y: -6)
            bodyContainer.position = .zero
        }
    }
    
    // MARK: - Reloading & Shooting
    
    public func startReload() {
        guard !isReloading && currentMag < currentWeapon.currentMagSize else { return }
        isReloading = true
        reloadTimer = 0.0
        reloadBadge.isHidden = false
        
        let spin = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.8)
        reloadBadge.run(SKAction.repeatForever(spin))
        
        AudioManager.shared.playReloadSound()
        HapticsManager.shared.playLight()
    }
    
    public func updateReload(dt: TimeInterval) -> (isFinished: Bool, progress: CGFloat) {
        guard isReloading else { return (false, 0.0) }
        
        reloadTimer += dt
        let totalTime = currentWeapon.currentReloadTime
        let progress = min(1.0, CGFloat(reloadTimer / totalTime))
        
        if reloadTimer >= totalTime {
            isReloading = false
            currentMag = currentWeapon.currentMagSize
            reloadBadge.removeAllActions()
            reloadBadge.isHidden = true
            AudioManager.shared.playReloadSound()
            HapticsManager.shared.playSuccess()
            return (true, 1.0)
        }
        return (false, progress)
    }
    
    public func canShoot(currentTime: TimeInterval) -> Bool {
        guard !isReloading else { return false }
        guard currentMag > 0 else {
            AudioManager.shared.playEmptyGunClick()
            startReload()
            return false
        }
        return currentTime - lastShotTime >= currentWeapon.fireRate
    }
    
    public func recordShot(currentTime: TimeInterval) {
        lastShotTime = currentTime
        currentMag -= 1
        triggerGunRecoil()
        if currentMag <= 0 {
            startReload()
        }
    }
    
    public func takeDamage(_ amount: CGFloat) -> Bool {
        guard !isInvulnerable else { return false }
        
        let reduced = amount * (1.0 - armorReduction)
        currentHealth -= reduced
        updateHealthBar()
        
        AudioManager.shared.playZombieBite()
        HapticsManager.shared.playHeavy()
        
        triggerInvulnerability(duration: 0.45)
        return currentHealth <= 0
    }
    
    public func heal(_ amount: CGFloat) {
        currentHealth = min(maxHealth, currentHealth + amount)
        updateHealthBar()
    }
    
    public func updateHealthBar() {
        let ratio = max(0.0, min(1.0, currentHealth / maxHealth))
        let width: CGFloat = 48.0 * ratio
        healthBarFg?.path = CGPath(roundedRect: CGRect(x: -24, y: -3, width: width, height: 6), cornerWidth: 2.5, cornerHeight: 2.5, transform: nil)
        healthBarFg?.fillColor = ratio > 0.4 ? .green : (ratio > 0.2 ? .orange : .red)
    }
    
    private func triggerInvulnerability(duration: TimeInterval) {
        isInvulnerable = true
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        ])
        let repeatAction = SKAction.repeat(flash, count: Int(duration / 0.16))
        run(SKAction.sequence([
            repeatAction,
            SKAction.run { [weak self] in
                self?.isInvulnerable = false
                self?.alpha = 1.0
            }
        ]))
    }
}
