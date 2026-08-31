import SpriteKit
import UIKit

public enum ProjectileKind {
    case bullet
    case shotgunPellet
    case rocket
    case flamethrower
    case teslaArc
    case acidSpit
    case grenade
}

public struct ZombiePhysicsCategory {
    public static let none: UInt32 = 0
    public static let player: UInt32 = 0b1
    public static let zombie: UInt32 = 0b10
    public static let boss: UInt32 = 0b100
    public static let playerBullet: UInt32 = 0b1000
    public static let zombieProjectile: UInt32 = 0b10000
    public static let dropItem: UInt32 = 0b100000
    public static let obstacle: UInt32 = 0b1000000
}

public final class ProjectileNode: SKNode {
    public let kind: ProjectileKind
    public var damage: CGFloat
    public var isPlayerOrigin: Bool
    public var pierceCount: Int = 1
    public var explosionRadius: CGFloat = 0
    
    private var shapeNode: SKShapeNode?
    
    public init(kind: ProjectileKind, damage: CGFloat, angle: CGFloat, isPlayer: Bool = true) {
        self.kind = kind
        self.damage = damage
        self.isPlayerOrigin = isPlayer
        super.init()
        
        self.zRotation = angle
        setupAppearance()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        switch kind {
        case .bullet:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -6, y: 0))
            path.addLine(to: CGPoint(x: 6, y: 0))
            let shape = SKShapeNode(path: path)
            shape.strokeColor = .yellow
            shape.lineWidth = 2.5
            shape.glowWidth = 3.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .shotgunPellet:
            let shape = SKShapeNode(circleOfRadius: 3)
            shape.fillColor = .orange
            shape.strokeColor = .yellow
            shape.lineWidth = 1.0
            shape.glowWidth = 2.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .rocket:
            self.explosionRadius = 140
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 10, y: 0))
            path.addLine(to: CGPoint(x: -8, y: -4))
            path.addLine(to: CGPoint(x: -8, y: 4))
            path.closeSubpath()
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
            shape.strokeColor = .white
            shape.lineWidth = 1.5
            shape.glowWidth = 4.0
            addChild(shape)
            self.shapeNode = shape
            
        case .flamethrower:
            self.pierceCount = 5
            let shape = SKShapeNode(circleOfRadius: 10)
            shape.fillColor = SKColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.8)
            shape.strokeColor = .yellow
            shape.lineWidth = 1.5
            shape.glowWidth = 5.0
            shape.blendMode = .add
            
            let scaleUp = SKAction.scale(to: 2.2, duration: 0.4)
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            shape.run(SKAction.group([scaleUp, fadeOut]))
            addChild(shape)
            self.shapeNode = shape
            
        case .teslaArc:
            self.pierceCount = 3
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -12, y: 0))
            path.addLine(to: CGPoint(x: -4, y: 5))
            path.addLine(to: CGPoint(x: 4, y: -5))
            path.addLine(to: CGPoint(x: 12, y: 0))
            let shape = SKShapeNode(path: path)
            shape.strokeColor = .cyan
            shape.lineWidth = 2.5
            shape.glowWidth = 6.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .acidSpit:
            let shape = SKShapeNode(circleOfRadius: 7)
            shape.fillColor = SKColor(red: 0.1, green: 1.0, blue: 0.1, alpha: 0.9)
            shape.strokeColor = .white
            shape.lineWidth = 1.5
            shape.glowWidth = 4.0
            shape.blendMode = .add
            addChild(shape)
            self.shapeNode = shape
            
        case .grenade:
            self.explosionRadius = 180
            let shape = SKShapeNode(circleOfRadius: 6)
            shape.fillColor = SKColor(red: 0.3, green: 0.4, blue: 0.2, alpha: 1.0)
            shape.strokeColor = .black
            shape.lineWidth = 1.5
            addChild(shape)
            self.shapeNode = shape
        }
    }
    
    private func setupPhysics() {
        let radius: CGFloat = (kind == .rocket || kind == .acidSpit) ? 8 : 4
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        
        if isPlayerOrigin {
            body.categoryBitMask = ZombiePhysicsCategory.playerBullet
            body.contactTestBitMask = ZombiePhysicsCategory.zombie | ZombiePhysicsCategory.boss
            body.collisionBitMask = 0
        } else {
            body.categoryBitMask = ZombiePhysicsCategory.zombieProjectile
            body.contactTestBitMask = ZombiePhysicsCategory.player
            body.collisionBitMask = 0
        }
        
        self.physicsBody = body
    }
}
