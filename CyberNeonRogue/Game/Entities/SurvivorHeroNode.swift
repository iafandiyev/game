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
    
    // Nodes
    private var bodyNode: SKShapeNode?
    private var headNode: SKShapeNode?
    private var gunNode: SKShapeNode?
    private var laserSight: SKShapeNode?
    private var healthBarFg: SKShapeNode?
    private var reloadIndicator: SKLabelNode?
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
        
        setupVisuals()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Legs
        let lLeg = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 2)
        lLeg.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        lLeg.strokeColor = .black
        lLeg.position = CGPoint(x: -6, y: -6)
        addChild(lLeg)
        self.leftLeg = lLeg
        
        let rLeg = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 2)
        rLeg.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        rLeg.strokeColor = .black
        rLeg.position = CGPoint(x: 6, y: -6)
        addChild(rLeg)
        self.rightLeg = rLeg
        
        // Torso / Body
        let body = SKShapeNode(circleOfRadius: 16)
        body.fillColor = SKColor(red: 0.2, green: 0.3, blue: 0.25, alpha: 1.0) // Military Green
        body.strokeColor = SKColor(red: 0.1, green: 0.2, blue: 0.15, alpha: 1.0)
        body.lineWidth = 2.0
        addChild(body)
        self.bodyNode = body
        
        // Tactical Vest
        let vest = SKShapeNode(rectOf: CGSize(width: 18, height: 16), cornerRadius: 3)
        vest.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.12, alpha: 1.0)
        vest.strokeColor = .black
        body.addChild(vest)
        
        // Helmet / Head
        let head = SKShapeNode(circleOfRadius: 10)
        head.fillColor = SKColor(red: 0.18, green: 0.22, blue: 0.18, alpha: 1.0)
        head.strokeColor = .black
        body.addChild(head)
        self.headNode = head
        
        // Glowing Red Visor
        let visor = SKShapeNode(rectOf: CGSize(width: 10, height: 4), cornerRadius: 1)
        visor.fillColor = .red
        visor.strokeColor = .clear
        visor.glowWidth = 4.0
        visor.position = CGPoint(x: 4, y: 0)
        head.addChild(visor)
        
        // Gun in hands
        let gun = SKShapeNode(rectOf: CGSize(width: 22, height: 6), cornerRadius: 1.5)
        gun.fillColor = SKColor.darkGray
        gun.strokeColor = .black
        gun.position = CGPoint(x: 18, y: 4)
        body.addChild(gun)
        self.gunNode = gun
        
        // Laser Sight line
        let laserPath = CGMutablePath()
        laserPath.move(to: CGPoint(x: 28, y: 4))
        laserPath.addLine(to: CGPoint(x: 180, y: 4))
        let laser = SKShapeNode(path: laserPath)
        laser.strokeColor = SKColor.red.withAlphaComponent(0.45)
        laser.lineWidth = 1.0
        laser.glowWidth = 2.0
        laser.blendMode = .add
        body.addChild(laser)
        self.laserSight = laser
        
        // Health Bar above head
        let hpBg = SKShapeNode(rectOf: CGSize(width: 44, height: 5), cornerRadius: 2)
        hpBg.fillColor = SKColor.black.withAlphaComponent(0.6)
        hpBg.strokeColor = .gray
        hpBg.lineWidth = 0.5
        hpBg.position = CGPoint(x: 0, y: 28)
        addChild(hpBg)
        
        let hpFg = SKShapeNode(rectOf: CGSize(width: 44, height: 5), cornerRadius: 2)
        hpFg.fillColor = .green
        hpFg.strokeColor = .clear
        hpFg.position = CGPoint(x: 0, y: 28)
        addChild(hpFg)
        self.healthBarFg = hpFg
        
        // Reloading Text Indicator
        let reloadLabel = SKLabelNode(text: "RELOADING...")
        reloadLabel.fontName = "HelveticaNeue-Bold"
        reloadLabel.fontSize = 9
        reloadLabel.fontColor = .yellow
        reloadLabel.position = CGPoint(x: 0, y: 38)
        reloadLabel.isHidden = true
        addChild(reloadLabel)
        self.reloadIndicator = reloadLabel
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
    
    // MARK: - Aiming & Rotation
    
    public func setAimAngle(_ angle: CGFloat) {
        self.aimAngle = angle
        self.bodyNode?.zRotation = angle
    }
    
    public func updateMovementAnim(isMoving: Bool, moveAngle: CGFloat, dt: TimeInterval) {
        if isMoving {
            walkAnimTimer += CGFloat(dt) * 12.0
            leftLeg?.position.x = -6 + sin(walkAnimTimer) * 5
            rightLeg?.position.x = 6 - sin(walkAnimTimer) * 5
        } else {
            leftLeg?.position = CGPoint(x: -6, y: -6)
            rightLeg?.position = CGPoint(x: 6, y: -6)
        }
    }
    
    // MARK: - Reloading & Firing
    
    public func startReload() {
        guard !isReloading && currentMag < currentWeapon.currentMagSize else { return }
        isReloading = true
        reloadTimer = 0.0
        reloadIndicator?.isHidden = false
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
            reloadIndicator?.isHidden = true
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
        
        triggerInvulnerability(duration: 0.5)
        return currentHealth <= 0
    }
    
    public func heal(_ amount: CGFloat) {
        currentHealth = min(maxHealth, currentHealth + amount)
        updateHealthBar()
    }
    
    public func updateHealthBar() {
        let ratio = max(0.0, min(1.0, currentHealth / maxHealth))
        let width: CGFloat = 44.0 * ratio
        healthBarFg?.path = CGPath(roundedRect: CGRect(x: -22, y: -2.5, width: width, height: 5), cornerWidth: 2, cornerHeight: 2, transform: nil)
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
