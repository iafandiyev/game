import SpriteKit
import UIKit

public enum ZombieType {
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
    
    // Status Effects
    public var burnTimer: TimeInterval = 0
    public var burnDamagePerSec: CGFloat = 0
    public var spitCooldown: TimeInterval = 2.5
    public var spitTimer: TimeInterval = 0
    
    // Nodes
    private var bodyNode: SKShapeNode?
    private var headNode: SKShapeNode?
    private var leftArm: SKShapeNode?
    private var rightArm: SKShapeNode?
    private var healthBarFg: SKShapeNode?
    
    private var walkAnimTimer: CGFloat = CGFloat.random(in: 0...5)
    
    public init(type: ZombieType, wave: Int) {
        self.zombieType = type
        let waveMultiplier = 1.0 + (CGFloat(wave - 1) * 0.16)
        
        switch type {
        case .walker:
            self.maxHealth = 45 * waveMultiplier
            self.moveSpeed = 75 + CGFloat(wave * 2)
            self.damage = 15
            self.cashValue = 15
            self.isBoss = false
            
        case .runner:
            self.maxHealth = 30 * waveMultiplier
            self.moveSpeed = 160 + CGFloat(wave * 3)
            self.damage = 10
            self.cashValue = 25
            self.isBoss = false
            
        case .acidSpitter:
            self.maxHealth = 60 * waveMultiplier
            self.moveSpeed = 65
            self.damage = 20
            self.cashValue = 40
            self.isBoss = false
            
        case .boomer:
            self.maxHealth = 90 * waveMultiplier
            self.moveSpeed = 55
            self.damage = 45 // Explodes
            self.cashValue = 50
            self.isBoss = false
            
        case .abominationBoss(_, let baseHp):
            self.maxHealth = baseHp * waveMultiplier
            self.moveSpeed = 60
            self.damage = 35
            self.cashValue = 500
            self.isBoss = true
        }
        
        self.currentHealth = self.maxHealth
        super.init()
        
        setupAppearance()
        setupPhysics()
        setupHealthBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        let sizeScale: CGFloat = isBoss ? 2.4 : (caseBoomer ? 1.4 : 1.0)
        
        // Torso / Body
        let body = SKShapeNode(circleOfRadius: 14 * sizeScale)
        body.fillColor = getSkinColor()
        body.strokeColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        body.lineWidth = 1.5
        addChild(body)
        self.bodyNode = body
        
        // Tattered clothes / blood spots
        let shirt = SKShapeNode(rectOf: CGSize(width: 16 * sizeScale, height: 12 * sizeScale), cornerRadius: 2)
        shirt.fillColor = isBoss ? SKColor.darkGray : (caseRunner ? SKColor.red : SKColor(red: 0.3, green: 0.35, blue: 0.3, alpha: 1.0))
        shirt.strokeColor = .clear
        body.addChild(shirt)
        
        // Arms reaching forward
        let lArm = SKShapeNode(rectOf: CGSize(width: 14 * sizeScale, height: 4 * sizeScale), cornerRadius: 1)
        lArm.fillColor = getSkinColor()
        lArm.strokeColor = .black
        lArm.position = CGPoint(x: 14 * sizeScale, y: -6 * sizeScale)
        body.addChild(lArm)
        self.leftArm = lArm
        
        let rArm = SKShapeNode(rectOf: CGSize(width: 14 * sizeScale, height: 4 * sizeScale), cornerRadius: 1)
        rArm.fillColor = getSkinColor()
        rArm.strokeColor = .black
        rArm.position = CGPoint(x: 14 * sizeScale, y: 6 * sizeScale)
        body.addChild(rArm)
        self.rightArm = rArm
        
        // Head with hollow glowing eyes
        let head = SKShapeNode(circleOfRadius: 8 * sizeScale)
        head.fillColor = getSkinColor()
        head.strokeColor = .black
        head.position = CGPoint(x: 2 * sizeScale, y: 0)
        body.addChild(head)
        self.headNode = head
        
        let eye = SKShapeNode(circleOfRadius: 2 * sizeScale)
        eye.fillColor = isBoss ? .yellow : (caseSpitter ? .green : .red)
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 5 * sizeScale, y: 2 * sizeScale)
        head.addChild(eye)
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
        case .walker: return SKColor(red: 0.35, green: 0.45, blue: 0.35, alpha: 1.0)
        case .runner: return SKColor(red: 0.45, green: 0.3, blue: 0.3, alpha: 1.0)
        case .acidSpitter: return SKColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1.0)
        case .boomer: return SKColor(red: 0.4, green: 0.48, blue: 0.25, alpha: 1.0)
        case .abominationBoss: return SKColor(red: 0.5, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
    
    private func setupPhysics() {
        let radius: CGFloat = isBoss ? 38 : (caseBoomer ? 20 : 16)
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
        guard isBoss || maxHealth > 70 else { return }
        
        let width: CGFloat = isBoss ? 80 : 32
        let yOffset: CGFloat = isBoss ? 55 : 24
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 4), cornerRadius: 1.5)
        bg.fillColor = SKColor.black.withAlphaComponent(0.6)
        bg.strokeColor = .gray
        bg.lineWidth = 0.5
        bg.position = CGPoint(x: 0, y: yOffset)
        addChild(bg)
        
        let fg = SKShapeNode(rectOf: CGSize(width: width, height: 4), cornerRadius: 1.5)
        fg.fillColor = isBoss ? .red : .green
        fg.strokeColor = .clear
        fg.position = CGPoint(x: 0, y: yOffset)
        addChild(fg)
        self.healthBarFg = fg
    }
    
    public func updateHealthBar() {
        guard let fg = healthBarFg else { return }
        let width: CGFloat = isBoss ? 80 : 32
        let ratio = max(0.0, min(1.0, currentHealth / maxHealth))
        let newWidth = width * ratio
        fg.path = CGPath(roundedRect: CGRect(x: -width/2, y: -2, width: newWidth, height: 4), cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
    }
    
    public func takeDamage(_ amount: CGFloat, knockbackAngle: CGFloat = 0, knockbackForce: CGFloat = 0) -> Bool {
        currentHealth -= amount
        updateHealthBar()
        
        // Flash red/white hit reaction
        bodyNode?.fillColor = .white
        bodyNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.run { [weak self] in
                self?.bodyNode?.fillColor = self?.getSkinColor() ?? .green
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
        bodyNode?.fillColor = .orange
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
        
        self.bodyNode?.zRotation = angle
        
        // Arm swinging animation
        walkAnimTimer += CGFloat(dt) * 10.0
        leftArm?.position.x = 14 + sin(walkAnimTimer) * 4
        rightArm?.position.x = 14 - sin(walkAnimTimer) * 4
        
        // Spitter behavior
        if case .acidSpitter = zombieType {
            spitTimer += dt
            if dist > 200 {
                self.position.x += cos(angle) * moveSpeed * CGFloat(dt)
                self.position.y += sin(angle) * moveSpeed * CGFloat(dt)
            } else if dist < 120 {
                // Back up slightly
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
