import SpriteKit
import UIKit

public enum EnemyType {
    case swarmer
    case scout
    case cruiser
    case stealth
    case boss(name: String, maxHp: CGFloat)
}

public final class EnemyNode: SKNode {
    public let enemyType: EnemyType
    public var maxHealth: CGFloat
    public var currentHealth: CGFloat
    public var moveSpeed: CGFloat
    public var scoreValue: Int
    public var crystalDropChance: Double
    public var expAmount: CGFloat
    
    // Status effects
    public var freezeTimer: TimeInterval = 0
    public var isBoss: Bool = false
    
    // Nodes
    private var shapeNode: SKShapeNode?
    private var healthBarBg: SKShapeNode?
    private var healthBarFg: SKShapeNode?
    
    // Timers
    public var shootTimer: TimeInterval = 0
    public var specialAttackTimer: TimeInterval = 0
    private var moveDirection: CGFloat = 1.0
    private var zigzagAngle: CGFloat = 0.0
    
    public init(type: EnemyType, wave: Int) {
        self.enemyType = type
        let waveFactor = 1.0 + (Double(wave - 1) * 0.18)
        
        switch type {
        case .swarmer:
            self.maxHealth = 25 * CGFloat(waveFactor)
            self.moveSpeed = 190 + CGFloat(wave * 4)
            self.scoreValue = 50
            self.crystalDropChance = 0.25
            self.expAmount = 8.0
            self.isBoss = false
            
        case .scout:
            self.maxHealth = 55 * CGFloat(waveFactor)
            self.moveSpeed = 140 + CGFloat(wave * 2)
            self.scoreValue = 100
            self.crystalDropChance = 0.4
            self.expAmount = 16.0
            self.isBoss = false
            
        case .cruiser:
            self.maxHealth = 160 * CGFloat(waveFactor)
            self.moveSpeed = 80
            self.scoreValue = 250
            self.crystalDropChance = 0.75
            self.expAmount = 40.0
            self.isBoss = false
            
        case .stealth:
            self.maxHealth = 70 * CGFloat(waveFactor)
            self.moveSpeed = 160
            self.scoreValue = 180
            self.crystalDropChance = 0.5
            self.expAmount = 25.0
            self.isBoss = false
            
        case .boss(_, let baseHp):
            self.maxHealth = baseHp * CGFloat(waveFactor)
            self.moveSpeed = 50
            self.scoreValue = 2000
            self.crystalDropChance = 1.0
            self.expAmount = 250.0
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
        let path = CGMutablePath()
        
        switch enemyType {
        case .swarmer:
            path.move(to: CGPoint(x: 0, y: -16))
            path.addLine(to: CGPoint(x: 12, y: 12))
            path.addLine(to: CGPoint(x: 0, y: 6))
            path.addLine(to: CGPoint(x: -12, y: 12))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.8)
            shape.strokeColor = .white
            shape.lineWidth = 1.5
            shape.glowWidth = 3.5
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .scout:
            path.move(to: CGPoint(x: 0, y: -20))
            path.addLine(to: CGPoint(x: 18, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 18))
            path.addLine(to: CGPoint(x: -18, y: 10))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.8)
            shape.strokeColor = .yellow
            shape.lineWidth = 2.0
            shape.glowWidth = 4.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .cruiser:
            path.move(to: CGPoint(x: 0, y: -28))
            path.addLine(to: CGPoint(x: 26, y: -8))
            path.addLine(to: CGPoint(x: 22, y: 24))
            path.addLine(to: CGPoint(x: -22, y: 24))
            path.addLine(to: CGPoint(x: -26, y: -8))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 0.6, green: 0.0, blue: 0.8, alpha: 0.85)
            shape.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 1.0)
            shape.lineWidth = 2.5
            shape.glowWidth = 5.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .stealth:
            path.move(to: CGPoint(x: 0, y: -18))
            path.addLine(to: CGPoint(x: 15, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 18))
            path.addLine(to: CGPoint(x: -15, y: 0))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 0.1, green: 0.8, blue: 0.9, alpha: 0.7)
            shape.strokeColor = .white
            shape.lineWidth = 1.5
            shape.glowWidth = 4.0
            shape.blendMode = .add
            
            // Cloaking animation
            let cloak = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: 1.2),
                SKAction.wait(forDuration: 1.0),
                SKAction.fadeAlpha(to: 0.9, duration: 0.6)
            ])
            shape.run(SKAction.repeatForever(cloak))
            addChild(shape)
            self.shapeNode = shape
            
        case .boss:
            // Massive Titan Boss
            path.move(to: CGPoint(x: 0, y: -50))
            path.addLine(to: CGPoint(x: 45, y: -20))
            path.addLine(to: CGPoint(x: 60, y: 30))
            path.addLine(to: CGPoint(x: 20, y: 45))
            path.addLine(to: CGPoint(x: -20, y: 45))
            path.addLine(to: CGPoint(x: -60, y: 30))
            path.addLine(to: CGPoint(x: -45, y: -20))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 0.8, green: 0.05, blue: 0.1, alpha: 0.9)
            shape.strokeColor = SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
            shape.lineWidth = 3.5
            shape.glowWidth = 8.0
            shape.blendMode = .add
            
            // Pulsing core
            let core = SKShapeNode(circleOfRadius: 18)
            core.fillColor = .yellow
            core.strokeColor = .white
            core.glowWidth = 6.0
            core.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.4),
                SKAction.scale(to: 0.9, duration: 0.4)
            ])))
            shape.addChild(core)
            
            addChild(shape)
            self.shapeNode = shape
        }
    }
    
    private func setupPhysics() {
        let radius: CGFloat = isBoss ? 55 : 18
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = isBoss ? PhysicsCategory.boss : PhysicsCategory.enemy
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerBullet
        body.collisionBitMask = 0
        self.physicsBody = body
    }
    
    private func setupHealthBar() {
        guard isBoss || maxHealth > 60 else { return }
        
        let width: CGFloat = isBoss ? 90 : 36
        let height: CGFloat = isBoss ? 7 : 4
        let yOffset: CGFloat = isBoss ? 65 : 24
        
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        bg.fillColor = SKColor.black.withAlphaComponent(0.6)
        bg.strokeColor = SKColor.gray
        bg.lineWidth = 0.5
        bg.position = CGPoint(x: 0, y: yOffset)
        addChild(bg)
        self.healthBarBg = bg
        
        let fg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 2)
        fg.fillColor = isBoss ? SKColor.red : SKColor.green
        fg.strokeColor = .clear
        fg.position = CGPoint(x: 0, y: yOffset)
        addChild(fg)
        self.healthBarFg = fg
    }
    
    public func updateHealthBar() {
        guard let fg = healthBarFg else { return }
        let width: CGFloat = isBoss ? 90 : 36
        let height: CGFloat = isBoss ? 7 : 4
        let ratio = max(0.0, min(1.0, currentHealth / maxHealth))
        
        let newWidth = width * ratio
        fg.path = CGPath(roundedRect: CGRect(x: -width / 2, y: -height / 2, width: newWidth, height: height), cornerWidth: 2, cornerHeight: 2, transform: nil)
    }
    
    public func takeDamage(_ amount: CGFloat) -> Bool {
        currentHealth -= amount
        updateHealthBar()
        
        // Flash white hit reaction
        shapeNode?.strokeColor = .white
        shapeNode?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.06),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.resetStrokeColor()
            }
        ]))
        
        return currentHealth <= 0
    }
    
    private func resetStrokeColor() {
        switch enemyType {
        case .swarmer: shapeNode?.strokeColor = .white
        case .scout: shapeNode?.strokeColor = .yellow
        case .cruiser: shapeNode?.strokeColor = SKColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 1.0)
        case .stealth: shapeNode?.strokeColor = .white
        case .boss: shapeNode?.strokeColor = SKColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
        }
    }
    
    public func applyFreeze(duration: TimeInterval) {
        self.freezeTimer = duration
        self.shapeNode?.fillColor = SKColor(red: 0.2, green: 0.7, blue: 1.0, alpha: 0.85)
    }
    
    public func updateAI(playerPosition: CGPoint, timeDilationFactor: CGFloat, dt: TimeInterval) {
        var currentSpeed = moveSpeed * timeDilationFactor
        
        if freezeTimer > 0 {
            freezeTimer -= dt
            currentSpeed *= 0.5
            if freezeTimer <= 0 {
                // Reset original color
                resetStrokeColor()
            }
        }
        
        zigzagAngle += CGFloat(dt) * 3.0
        
        switch enemyType {
        case .swarmer:
            // Direct rush towards player
            let dx = playerPosition.x - self.position.x
            let dy = playerPosition.y - self.position.y
            let dist = sqrt(dx * dx + dy * dy)
            if dist > 5 {
                self.position.x += (dx / dist) * currentSpeed * CGFloat(dt)
                self.position.y += (dy / dist) * currentSpeed * CGFloat(dt)
            }
            
        case .scout:
            // Move downwards with horizontal zigzag
            self.position.y -= currentSpeed * CGFloat(dt)
            self.position.x += sin(zigzagAngle) * 90 * CGFloat(dt)
            
        case .cruiser:
            // Move down steadily to mid-screen then hover
            if self.position.y > 450 {
                self.position.y -= currentSpeed * CGFloat(dt)
            } else {
                self.position.x += moveDirection * currentSpeed * 0.8 * CGFloat(dt)
                if self.position.x > 320 { moveDirection = -1.0 }
                if self.position.x < 70 { moveDirection = 1.0 }
            }
            
        case .stealth:
            // Move diagonally fast
            self.position.y -= currentSpeed * CGFloat(dt) * 0.7
            self.position.x += cos(zigzagAngle * 1.5) * currentSpeed * CGFloat(dt)
            
        case .boss:
            // Boss stays at top section, sweeps side to side
            if self.position.y > 620 {
                self.position.y -= currentSpeed * 1.5 * CGFloat(dt)
            } else {
                self.position.x += moveDirection * currentSpeed * 1.2 * CGFloat(dt)
                if self.position.x > 320 { moveDirection = -1.0 }
                if self.position.x < 70 { moveDirection = 1.0 }
            }
        }
    }
}
