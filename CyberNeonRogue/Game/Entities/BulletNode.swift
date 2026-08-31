import SpriteKit
import UIKit

public enum BulletKind {
    case playerLaser
    case playerPlasma
    case playerTesla
    case playerHoming
    case playerVortex
    case enemyBullet
    case enemyBossLaser
}

public final class BulletNode: SKNode {
    public let kind: BulletKind
    public var damage: CGFloat
    public var isPlayerBullet: Bool
    public var targetEnemy: SKNode?
    public var isFreezing: Bool = false
    public var isCritical: Bool = false
    
    private var shapeNode: SKShapeNode?
    
    public init(kind: BulletKind, damage: CGFloat, isPlayer: Bool = true, isCritical: Bool = false) {
        self.kind = kind
        self.damage = damage
        self.isPlayerBullet = isPlayer
        self.isCritical = isCritical
        super.init()
        
        setupAppearance()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        switch kind {
        case .playerLaser:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -10))
            path.addLine(to: CGPoint(x: 0, y: 10))
            
            let shape = SKShapeNode(path: path)
            shape.strokeColor = isCritical ? .yellow : .cyan
            shape.lineWidth = isCritical ? 4.5 : 3.0
            shape.glowWidth = isCritical ? 6.0 : 4.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .playerPlasma:
            let shape = SKShapeNode(circleOfRadius: 10)
            shape.fillColor = SKColor(red: 0.1, green: 1.0, blue: 0.4, alpha: 0.8)
            shape.strokeColor = .white
            shape.lineWidth = 2.0
            shape.glowWidth = 6.0
            shape.blendMode = .add
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.1),
                SKAction.scale(to: 0.9, duration: 0.1)
            ])
            shape.run(SKAction.repeatForever(pulse))
            addChild(shape)
            self.shapeNode = shape
            
        case .playerTesla:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -14))
            path.addLine(to: CGPoint(x: 4, y: -4))
            path.addLine(to: CGPoint(x: -4, y: 4))
            path.addLine(to: CGPoint(x: 0, y: 14))
            
            let shape = SKShapeNode(path: path)
            shape.strokeColor = SKColor(red: 0.9, green: 0.1, blue: 1.0, alpha: 1.0)
            shape.lineWidth = 3.5
            shape.glowWidth = 5.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .playerHoming:
            let shape = SKShapeNode(rectOf: CGSize(width: 8, height: 16), cornerRadius: 3)
            shape.fillColor = .orange
            shape.strokeColor = .yellow
            shape.lineWidth = 1.5
            shape.glowWidth = 4.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .playerVortex:
            let shape = SKShapeNode(circleOfRadius: 28)
            shape.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 1.0, alpha: 0.9)
            shape.lineWidth = 3.0
            shape.glowWidth = 8.0
            shape.fillColor = SKColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 0.6)
            shape.blendMode = .add
            
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 0.8)
            shape.run(SKAction.repeatForever(rotate))
            addChild(shape)
            self.shapeNode = shape
            
        case .enemyBullet:
            let shape = SKShapeNode(circleOfRadius: 6)
            shape.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.3, alpha: 0.9)
            shape.strokeColor = .white
            shape.lineWidth = 1.5
            shape.glowWidth = 3.5
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .enemyBossLaser:
            let shape = SKShapeNode(rectOf: CGSize(width: 14, height: 32), cornerRadius: 4)
            shape.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.95)
            shape.strokeColor = .yellow
            shape.lineWidth = 2.5
            shape.glowWidth = 7.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
        }
    }
    
    private func setupPhysics() {
        let radius: CGFloat
        switch kind {
        case .playerLaser: radius = 8
        case .playerPlasma: radius = 12
        case .playerTesla: radius = 10
        case .playerHoming: radius = 9
        case .playerVortex: radius = 30
        case .enemyBullet: radius = 6
        case .enemyBossLaser: radius = 12
        }
        
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        
        if isPlayerBullet {
            body.categoryBitMask = PhysicsCategory.playerBullet
            body.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.boss
            body.collisionBitMask = 0
        } else {
            body.categoryBitMask = PhysicsCategory.enemyBullet
            body.contactTestBitMask = PhysicsCategory.player
            body.collisionBitMask = 0
        }
        
        self.physicsBody = body
    }
    
    /// Homing update called every frame for guided missiles
    public func updateHoming(dt: TimeInterval) {
        guard kind == .playerHoming, let target = targetEnemy, target.parent != nil else { return }
        
        let dx = target.position.x - self.position.x
        let dy = target.position.y - self.position.y
        let targetAngle = atan2(dy, dx) - .pi / 2
        
        let currentAngle = self.zRotation
        var diff = targetAngle - currentAngle
        while diff < -.pi { diff += .pi * 2 }
        while diff > .pi { diff -= .pi * 2 }
        
        let turnRate: CGFloat = 7.0
        self.zRotation += diff * turnRate * CGFloat(dt)
        
        let speed: CGFloat = 550.0
        let moveAngle = self.zRotation + .pi / 2
        self.physicsBody?.velocity = CGVector(dx: cos(moveAngle) * speed, dy: sin(moveAngle) * speed)
    }
}

public struct PhysicsCategory {
    public static let none: UInt32 = 0
    public static let player: UInt32 = 0b1 // 1
    public static let enemy: UInt32 = 0b10 // 2
    public static let boss: UInt32 = 0b100 // 4
    public static let playerBullet: UInt32 = 0b1000 // 8
    public static let enemyBullet: UInt32 = 0b10000 // 16
    public static let powerUp: UInt32 = 0b100000 // 32
}
