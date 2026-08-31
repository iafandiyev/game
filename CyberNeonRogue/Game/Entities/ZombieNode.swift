import SpriteKit
import UIKit

public enum ZombieType: Equatable {
    case walker
    case runner
    case acidSpitter
    case boomer
    case abominationBoss(name: String, maxHp: CGFloat)
}

public final class ZombieNode: SKNode {
    public let zombieType: ZombieType
    public var maxHealth: CGFloat
    public var currentHealth: CGFloat
    public var moveSpeed: CGFloat
    public var damage: CGFloat
    public var cashValue: Int
    public var isBoss: Bool = false
    
    public var isAcidSpitter: Bool {
        if case .acidSpitter = zombieType { return true }
        return false
    }
    public var isBoomer: Bool {
        if case .boomer = zombieType { return true }
        return false
    }
    
    // Status Effects
    public var burnTimer: TimeInterval = 0
    public var burnDamagePerSec: CGFloat = 0
    public var spitCooldown: TimeInterval = 2.4
    public var spitTimer: TimeInterval = 0
    
    // Visual Nodes
    private var shadowNode: SKShapeNode?
    private var bodyContainer: SKNode = SKNode()
    private var torsoNode: SKShapeNode?
    private var headNode: SKShapeNode?
    private var leftArm: SKShapeNode?
    private var rightArm: SKShapeNode?
    private var healthBarFg: SKShapeNode?
    private var toxicSacs: [SKShapeNode] = []
    
    private var walkAnimTimer: CGFloat = CGFloat.random(in: 0...5)
    
    public init(type: ZombieType, wave: Int) {
        self.zombieType = type
        let waveMultiplier = 1.0 + (CGFloat(wave - 1) * 0.18)
        
        switch type {
        case .walker:
            self.maxHealth = 48 * waveMultiplier
            self.moveSpeed = 75 + CGFloat(wave * 2)
            self.damage = 16
            self.cashValue = 15
            self.isBoss = false
            
        case .runner:
            self.maxHealth = 32 * waveMultiplier
            self.moveSpeed = 165 + CGFloat(wave * 3)
            self.damage = 12
            self.cashValue = 25
            self.isBoss = false
            
        case .acidSpitter:
            self.maxHealth = 65 * waveMultiplier
            self.moveSpeed = 65
            self.damage = 22
            self.cashValue = 40
            self.isBoss = false
            
        case .boomer:
            self.maxHealth = 100 * waveMultiplier
            self.moveSpeed = 55
            self.damage = 50
            self.cashValue = 50
            self.isBoss = false
            
        case .abominationBoss(_, let baseHp):
            self.maxHealth = baseHp * waveMultiplier
            self.moveSpeed = 65
            self.damage = 38
            self.cashValue = 500
            self.isBoss = true
        }
        
        self.currentHealth = self.maxHealth
        super.init()
        
        setupHighDetailAppearance()
        setupPhysics()
        setupHealthBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - AAA Appearance Setup
    
    private func setupHighDetailAppearance() {
        self.zPosition = isBoss ? 12 : 9
        let scale: CGFloat = isBoss ? 2.5 : (caseBoomer ? 1.4 : 1.0)
        
        // 1. Soft Dynamic Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 32 * scale, height: 20 * scale))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.35)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -1
        addChild(shadow)
        self.shadowNode = shadow
        
        // 2. Body Container
        addChild(bodyContainer)
        
        // Torso / Rotten Flesh Body
        let torso = SKShapeNode(rectOf: CGSize(width: 22 * scale, height: 24 * scale), cornerRadius: 5 * scale)
        torso.fillColor = getSkinColor()
        torso.strokeColor = SKColor(red: 0.08, green: 0.1, blue: 0.08, alpha: 1.0)
        torso.lineWidth = 1.2
        bodyContainer.addChild(torso)
        self.torsoNode = torso
        
        // Tattered Clothes / Bloody Wounds
        let shirt = SKShapeNode(rectOf: CGSize(width: 18 * scale, height: 16 * scale), cornerRadius: 3 * scale)
        shirt.fillColor = isBoss ? SKColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0) : (caseRunner ? SKColor(red: 0.55, green: 0.1, blue: 0.1, alpha: 1.0) : SKColor(red: 0.22, green: 0.26, blue: 0.24, alpha: 1.0))
        shirt.strokeColor = .black
        shirt.lineWidth = 0.5
        torso.addChild(shirt)
        
        // Flesh Wounds / Exposed Ribs
        let wound = SKShapeNode(rectOf: CGSize(width: 8 * scale, height: 4 * scale), cornerRadius: 1 * scale)
        wound.fillColor = SKColor(red: 0.7, green: 0.05, blue: 0.05, alpha: 0.9)
        wound.strokeColor = .clear
        wound.position = CGPoint(x: -2 * scale, y: -2 * scale)
        torso.addChild(wound)
        
        // Toxic Glowing Sacs on Acid Spitter & Boomer
        if caseSpitter || caseBoomer {
            for i in 0..<3 {
                let sac = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...7) * scale)
                sac.fillColor = caseSpitter ? SKColor(red: 0.1, green: 1.0, blue: 0.1, alpha: 0.85) : SKColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.85)
                sac.strokeColor = .white
                sac.lineWidth = 0.5
                sac.glowWidth = 3.0
                sac.blendMode = .add
                sac.position = CGPoint(x: CGFloat(i * 6 - 6) * scale, y: -10 * scale)
                bodyContainer.addChild(sac)
                toxicSacs.append(sac)
            }
        }
        
        // Head with rotting jaws and glowing eyes
        let head = SKShapeNode(circleOfRadius: 10 * scale)
        head.fillColor = getSkinColor()
        head.strokeColor = .black
        head.lineWidth = 1.2
        head.position = CGPoint(x: 4 * scale, y: 0)
        bodyContainer.addChild(head)
        self.headNode = head
        
        // Glowing Eyes
        let lEye = SKShapeNode(circleOfRadius: 2.2 * scale)
        lEye.fillColor = isBoss ? .yellow : (caseSpitter ? .green : .red)
        lEye.strokeColor = .white
        lEye.glowWidth = 3.0
        lEye.blendMode = .add
        lEye.position = CGPoint(x: 5 * scale, y: -3.5 * scale)
        head.addChild(lEye)
        
        let rEye = SKShapeNode(circleOfRadius: 2.2 * scale)
        rEye.fillColor = isBoss ? .yellow : (caseSpitter ? .green : .red)
        rEye.strokeColor = .white
        rEye.glowWidth = 3.0
        rEye.blendMode = .add
        rEye.position = CGPoint(x: 5 * scale, y: 3.5 * scale)
        head.addChild(rEye)
        
        // Rotten Reaching Claws / Arms
        let lArm = SKShapeNode(rectOf: CGSize(width: 18 * scale, height: 5 * scale), cornerRadius: 2 * scale)
        lArm.fillColor = getSkinColor()
        lArm.strokeColor = .black
        lArm.lineWidth = 1.0
        lArm.position = CGPoint(x: 16 * scale, y: -10 * scale)
        bodyContainer.addChild(lArm)
        self.leftArm = lArm
        
        let rArm = SKShapeNode(rectOf: CGSize(width: 18 * scale, height: 5 * scale), cornerRadius: 2 * scale)
        rArm.fillColor = getSkinColor()
        rArm.strokeColor = .black
        rArm.lineWidth = 1.0
        rArm.position = CGPoint(x: 16 * scale, y: 10 * scale)
        bodyContainer.addChild(rArm)
        self.rightArm = rArm
        
        // Sharp Claws
        let lClaw = SKShapeNode(circleOfRadius: 2 * scale)
        lClaw.fillColor = .white
        lClaw.strokeColor = .black
        lClaw.position = CGPoint(x: 8 * scale, y: 0)
        lArm.addChild(lClaw)
        
        let rClaw = SKShapeNode(circleOfRadius: 2 * scale)
        rClaw.fillColor = .white
        rClaw.strokeColor = .black
        rClaw.position = CGPoint(x: 8 * scale, y: 0)
        rArm.addChild(rClaw)
    }
    
    private var caseBoomer: Bool {
        if case .boomer = zombieType { return true }
        return false
    }
    
    private var caseSpitter: Bool {
        if case .acidSpitter = zombieType { return true }
        return false
    }
    
    private var caseRunner: Bool {
        if case .runner = zombieType { return true }
        return false
    }
    
    private func getSkinColor() -> SKColor {
        switch zombieType {
        case .walker: return SKColor(red: 0.32, green: 0.44, blue: 0.32, alpha: 1.0)
        case .runner: return SKColor(red: 0.48, green: 0.28, blue: 0.28, alpha: 1.0)
        case .acidSpitter: return SKColor(red: 0.18, green: 0.52, blue: 0.20, alpha: 1.0)
        case .boomer: return SKColor(red: 0.42, green: 0.48, blue: 0.24, alpha: 1.0)
        case .abominationBoss: return SKColor(red: 0.48, green: 0.16, blue: 0.16, alpha: 1.0)
        }
    }
    
    private func setupPhysics() {
        let radius: CGFloat = isBoss ? 42 : (caseBoomer ? 22 : 17)
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = isBoss ? ZombiePhysicsCategory.boss : ZombiePhysicsCategory.zombie
        body.contactTestBitMask = ZombiePhysicsCategory.player | ZombiePhysicsCategory.playerBullet
        body.collisionBitMask = ZombiePhysicsCategory.obstacle
        self.physicsBody = body
    }
    
    private func setupHealthBar() {
        guard isBoss || maxHealth > 60 else { return }
        
        let width: CGFloat = isBoss ? 90 : 36
        let yOffset: CGFloat = isBoss ? 62 : 28
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 5), cornerRadius: 2)
        bg.fillColor = SKColor.black.withAlphaComponent(0.7)
        bg.strokeColor = SKColor.white.withAlphaComponent(0.2)
        bg.lineWidth = 0.5
        bg.position = CGPoint(x: 0, y: yOffset)
        bg.zPosition = 25
        addChild(bg)
        
        let fg = SKShapeNode(rectOf: CGSize(width: width, height: 5), cornerRadius: 2)
        fg.fillColor = isBoss ? .red : .green
        fg.strokeColor = .clear
        fg.position = CGPoint(x: 0, y: yOffset)
        fg.zPosition = 26
        addChild(fg)
        self.healthBarFg = fg
    }
    
    public func updateHealthBar() {
        guard let fg = healthBarFg else { return }
        let width: CGFloat = isBoss ? 90 : 36
        let ratio = max(0.0, min(1.0, currentHealth / maxHealth))
        let newWidth = width * ratio
        fg.path = CGPath(roundedRect: CGRect(x: -width/2, y: -2.5, width: newWidth, height: 5), cornerWidth: 2, cornerHeight: 2, transform: nil)
    }
    
    public func takeDamage(_ amount: CGFloat, knockbackAngle: CGFloat = 0, knockbackForce: CGFloat = 0) -> Bool {
        currentHealth -= amount
        updateHealthBar()
        
        // Hit flash reaction
        torsoNode?.fillColor = .white
        headNode?.fillColor = .white
        
        torsoNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in
                self?.torsoNode?.fillColor = self?.getSkinColor() ?? .green
                self?.headNode?.fillColor = self?.getSkinColor() ?? .green
            }
        ]))
        
        // Knockback physics impulse
        if knockbackForce > 0 {
            let kx = cos(knockbackAngle) * knockbackForce
            let ky = sin(knockbackAngle) * knockbackForce
            self.physicsBody?.applyImpulse(CGVector(dx: kx, dy: ky))
        }
        
        return currentHealth <= 0
    }
    
    public func applyBurn(duration: TimeInterval, dps: CGFloat) {
        burnTimer = duration
        burnDamagePerSec = dps
        torsoNode?.fillColor = .orange
    }
    
    // MARK: - AI Update
    
    public func updateAI(playerPosition: CGPoint, dt: TimeInterval, onSpitAcid: ((CGPoint, CGFloat) -> Void)? = nil) {
        // Burn status
        if burnTimer > 0 {
            burnTimer -= dt
            let dead = takeDamage(burnDamagePerSec * CGFloat(dt))
            if dead { return }
        }
        
        let dx = playerPosition.x - self.position.x
        let dy = playerPosition.y - self.position.y
        let dist = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        
        self.bodyContainer.zRotation = angle
        
        // Claw swinging animation
        walkAnimTimer += CGFloat(dt) * (caseRunner ? 18.0 : 10.0)
        let scale: CGFloat = isBoss ? 2.5 : 1.0
        leftArm?.position.x = (16 + sin(walkAnimTimer) * 5) * scale
        rightArm?.position.x = (16 - sin(walkAnimTimer) * 5) * scale
        
        // Spitter behavior
        if case .acidSpitter = zombieType {
            spitTimer += dt
            if dist > 210 {
                self.position.x += cos(angle) * moveSpeed * CGFloat(dt)
                self.position.y += sin(angle) * moveSpeed * CGFloat(dt)
            } else if dist < 120 {
                self.position.x -= cos(angle) * moveSpeed * CGFloat(dt)
                self.position.y -= sin(angle) * moveSpeed * CGFloat(dt)
            }
            
            if spitTimer >= spitCooldown {
                spitTimer = 0
                onSpitAcid?(self.position, angle)
            }
            return
        }
        
        // Standard chase movement
        if dist > 8 {
            self.position.x += cos(angle) * moveSpeed * CGFloat(dt)
            self.position.y += sin(angle) * moveSpeed * CGFloat(dt)
        }
    }
}
