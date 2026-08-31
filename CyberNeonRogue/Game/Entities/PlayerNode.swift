import SpriteKit
import UIKit

public final class PlayerNode: SKNode {
    public let shipModel: ShipModel
    public var maxHealth: CGFloat
    public var currentHealth: CGFloat
    public var maxShield: CGFloat
    public var currentShield: CGFloat
    public var shieldRegenRate: CGFloat = 8.0 // Per second
    public var speedMultiplier: CGFloat = 1.0
    public var damageMultiplier: CGFloat = 1.0
    public var fireRateMultiplier: CGFloat = 1.0
    public var magnetRadius: CGFloat = 120.0
    public var critChance: CGFloat = 0.1
    
    // Active perks state
    public var activePerks: [String: Int] = [:]
    
    // Nodes
    private var hullNode: SKShapeNode?
    private var shieldNode: SKShapeNode?
    private var leftThruster: SKEmitterNode?
    private var rightThruster: SKEmitterNode?
    public var orbitDrones: [SKNode] = []
    
    // Timers
    public var lastFireTime: TimeInterval = 0
    public var lastVortexTime: TimeInterval = 0
    public var isInvulnerable: Bool = false
    public var quadDamageTimer: TimeInterval = 0
    
    public init(ship: ShipModel, bonusHP: Double = 0, bonusShield: Double = 0, bonusDamage: Double = 0, bonusFireRate: Double = 0, bonusMagnet: Double = 0, bonusCrit: Double = 0) {
        self.shipModel = ship
        self.maxHealth = ship.baseHealth + CGFloat(bonusHP)
        self.currentHealth = self.maxHealth
        self.maxShield = ship.baseShield + CGFloat(bonusShield)
        self.currentShield = self.maxShield
        self.damageMultiplier = 1.0 + CGFloat(bonusDamage)
        self.fireRateMultiplier = max(0.4, 1.0 - CGFloat(bonusFireRate))
        self.magnetRadius = 120.0 + CGFloat(bonusMagnet)
        self.critChance = 0.1 + CGFloat(bonusCrit)
        
        super.init()
        
        setupShipVisuals()
        setupShieldVisuals()
        setupThrusters()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupShipVisuals() {
        let path = CGMutablePath()
        let accentColor = UIColor(hex: shipModel.accentColorHex) ?? UIColor.cyan
        
        switch shipModel.id {
        case "striker":
            // Sharp interceptor delta wing
            path.move(to: CGPoint(x: 0, y: 26))
            path.addLine(to: CGPoint(x: 22, y: -16))
            path.addLine(to: CGPoint(x: 10, y: -10))
            path.addLine(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: -10, y: -10))
            path.addLine(to: CGPoint(x: -22, y: -16))
            path.closeSubpath()
            
        case "phantom":
            // Sleek stealth diamond needle
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 16, y: 2))
            path.addLine(to: CGPoint(x: 26, y: -20))
            path.addLine(to: CGPoint(x: 0, y: -14))
            path.addLine(to: CGPoint(x: -26, y: -20))
            path.addLine(to: CGPoint(x: -16, y: 2))
            path.closeSubpath()
            
        case "titan":
            // Heavy armored battleship
            path.move(to: CGPoint(x: 0, y: 22))
            path.addLine(to: CGPoint(x: 28, y: 8))
            path.addLine(to: CGPoint(x: 24, y: -22))
            path.addLine(to: CGPoint(x: 8, y: -18))
            path.addLine(to: CGPoint(x: 0, y: -24))
            path.addLine(to: CGPoint(x: -8, y: -18))
            path.addLine(to: CGPoint(x: -24, y: -22))
            path.addLine(to: CGPoint(x: -28, y: 8))
            path.closeSubpath()
            
        default: // spectre
            // Triple wing solar craft
            path.move(to: CGPoint(x: 0, y: 28))
            path.addLine(to: CGPoint(x: 18, y: 12))
            path.addLine(to: CGPoint(x: 24, y: -18))
            path.addLine(to: CGPoint(x: 6, y: -12))
            path.addLine(to: CGPoint(x: 0, y: -20))
            path.addLine(to: CGPoint(x: -6, y: -12))
            path.addLine(to: CGPoint(x: -24, y: -18))
            path.addLine(to: CGPoint(x: -18, y: 12))
            path.closeSubpath()
        }
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = SKColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.9)
        shape.strokeColor = accentColor
        shape.lineWidth = 2.5
        shape.glowWidth = 4.0
        shape.blendMode = .add
        addChild(shape)
        self.hullNode = shape
        
        // Cockpit canopy core
        let core = SKShapeNode(ellipseOf: CGSize(width: 8, height: 16))
        core.fillColor = .white
        core.strokeColor = accentColor
        core.glowWidth = 3.0
        core.position = CGPoint(x: 0, y: 2)
        shape.addChild(core)
    }
    
    private func setupShieldVisuals() {
        let shield = SKShapeNode(circleOfRadius: 36)
        shield.strokeColor = SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.8)
        shield.fillColor = SKColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.12)
        shield.lineWidth = 2.0
        shield.glowWidth = 6.0
        shield.blendMode = .add
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.6),
            SKAction.scale(to: 0.98, duration: 0.6)
        ])
        shield.run(SKAction.repeatForever(pulse))
        addChild(shield)
        self.shieldNode = shield
        shield.isHidden = (currentShield <= 0)
    }
    
    private func setupThrusters() {
        let color = UIColor(hex: shipModel.accentColorHex) ?? UIColor.cyan
        
        let left = ParticleFactory.createThrusterTrail(color: color)
        left.position = CGPoint(x: -8, y: -16)
        addChild(left)
        self.leftThruster = left
        
        let right = ParticleFactory.createThrusterTrail(color: color)
        right.position = CGPoint(x: 8, y: -16)
        addChild(right)
        self.rightThruster = right
    }
    
    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 20)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.boss | PhysicsCategory.enemyBullet | PhysicsCategory.powerUp
        body.collisionBitMask = 0
        self.physicsBody = body
    }
    
    // MARK: - Drone Upgrades
    public func updateOrbitalDrones(count: Int) {
        // Remove existing
        for d in orbitDrones { d.removeFromParent() }
        orbitDrones.removeAll()
        
        guard count > 0 else { return }
        for i in 0..<count {
            let drone = SKShapeNode(circleOfRadius: 6)
            drone.fillColor = .cyan
            drone.strokeColor = .white
            drone.lineWidth = 1.5
            drone.glowWidth = 4.0
            drone.blendMode = .add
            
            let angle = (Double(i) / Double(count)) * .pi * 2
            let radius: CGFloat = 55.0
            drone.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            
            // Orbit action
            let orbit = SKAction.customAction(withDuration: 1000.0) { node, elapsedTime in
                let curAngle = angle + Double(elapsedTime) * 3.0
                node.position = CGPoint(x: cos(curAngle) * radius, y: sin(curAngle) * radius)
            }
            drone.run(SKAction.repeatForever(orbit))
            addChild(drone)
            orbitDrones.append(drone)
        }
    }
    
    // MARK: - Damage and Shield Update
    public func takeDamage(_ amount: CGFloat) -> Bool {
        guard !isInvulnerable else { return false }
        
        HapticsManager.shared.playHeavy()
        AudioManager.shared.playPlayerHitSound()
        
        var damageRemaining = amount
        if currentShield > 0 {
            if currentShield >= damageRemaining {
                currentShield -= damageRemaining
                damageRemaining = 0
            } else {
                damageRemaining -= currentShield
                currentShield = 0
            }
        }
        
        shieldNode?.isHidden = (currentShield <= 0)
        
        if damageRemaining > 0 {
            currentHealth -= damageRemaining
        }
        
        // I-frames
        triggerInvulnerability(duration: 0.6)
        
        return currentHealth <= 0
    }
    
    public func triggerInvulnerability(duration: TimeInterval) {
        isInvulnerable = true
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.08),
            SKAction.fadeAlpha(to: 1.0, duration: 0.08)
        ])
        let flashRepeat = SKAction.repeat(flash, count: Int(duration / 0.16))
        
        run(SKAction.sequence([
            flashRepeat,
            SKAction.run { [weak self] in
                self?.isInvulnerable = false
                self?.alpha = 1.0
            }
        ]))
    }
    
    public func updateState(dt: TimeInterval) {
        // Shield regen
        if currentShield < maxShield {
            let regenPerk = CGFloat(activePerks["shield_overcharge"] ?? 0)
            let actualRegen = (shieldRegenRate + (regenPerk * 6.0)) * CGFloat(dt)
            currentShield = min(maxShield + (regenPerk * 25.0), currentShield + actualRegen)
            shieldNode?.isHidden = (currentShield <= 0)
        }
        
        // Quad damage timer
        if quadDamageTimer > 0 {
            quadDamageTimer -= dt
        }
    }
    
    public func applyTilt(vector: CGVector) {
        let maxTilt: CGFloat = 0.35
        let targetRotation = -vector.dx * maxTilt
        self.zRotation += (targetRotation - self.zRotation) * 0.15
    }
}

// MARK: - Color Hex Helper
fileprivate extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
