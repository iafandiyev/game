import SpriteKit
import UIKit

public enum PowerUpKind {
    case expGem(amount: CGFloat, color: SKColor)
    case cyberCrystal(value: Int)
    case nukeEMP
    case timeDilation
    case superShield
    case quadDamage
}

public final class PowerUpNode: SKNode {
    public let kind: PowerUpKind
    private var shapeNode: SKShapeNode?
    
    public init(kind: PowerUpKind) {
        self.kind = kind
        super.init()
        
        setupAppearance()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        switch kind {
        case .expGem(let amount, let color):
            let size: CGFloat = amount > 25 ? 14 : (amount > 10 ? 10 : 7)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: size * 0.7, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -size))
            path.addLine(to: CGPoint(x: -size * 0.7, y: 0))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = color.withAlphaComponent(0.8)
            shape.strokeColor = .white
            shape.lineWidth = 1.2
            shape.glowWidth = 4.0
            shape.blendMode = .add
            
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
            shape.run(SKAction.repeatForever(spin))
            addChild(shape)
            self.shapeNode = shape
            
        case .cyberCrystal(let value):
            let path = CGMutablePath()
            let s: CGFloat = value > 5 ? 16 : 11
            path.move(to: CGPoint(x: 0, y: s))
            path.addLine(to: CGPoint(x: s, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -s))
            path.addLine(to: CGPoint(x: -s, y: 0))
            path.closeSubpath()
            
            let shape = SKShapeNode(path: path)
            shape.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.85) // Gold
            shape.strokeColor = .white
            shape.lineWidth = 2.0
            shape.glowWidth = 6.0
            shape.blendMode = .add
            
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            shape.run(SKAction.repeatForever(pulse))
            addChild(shape)
            self.shapeNode = shape
            
        case .nukeEMP:
            let shape = SKShapeNode(circleOfRadius: 18)
            shape.fillColor = SKColor(red: 1.0, green: 0.1, blue: 0.1, alpha: 0.8)
            shape.strokeColor = .white
            shape.lineWidth = 2.0
            shape.glowWidth = 8.0
            shape.blendMode = .add
            
            let icon = SKLabelNode(text: "☢")
            icon.fontSize = 18
            icon.fontColor = .white
            icon.verticalAlignmentMode = .center
            shape.addChild(icon)
            
            addChild(shape)
            self.shapeNode = shape
            
        case .timeDilation:
            let shape = SKShapeNode(circleOfRadius: 18)
            shape.fillColor = SKColor(red: 0.1, green: 0.6, blue: 1.0, alpha: 0.8)
            shape.strokeColor = .cyan
            shape.lineWidth = 2.0
            shape.glowWidth = 8.0
            shape.blendMode = .add
            
            let icon = SKLabelNode(text: "⌛")
            icon.fontSize = 16
            icon.fontColor = .white
            icon.verticalAlignmentMode = .center
            shape.addChild(icon)
            
            addChild(shape)
            self.shapeNode = shape
            
        case .superShield:
            let shape = SKShapeNode(circleOfRadius: 18)
            shape.fillColor = SKColor(red: 0.1, green: 1.0, blue: 0.7, alpha: 0.8)
            shape.strokeColor = .white
            shape.lineWidth = 2.0
            shape.glowWidth = 8.0
            shape.blendMode = .add
            
            let icon = SKLabelNode(text: "🛡")
            icon.fontSize = 16
            icon.fontColor = .white
            icon.verticalAlignmentMode = .center
            shape.addChild(icon)
            
            addChild(shape)
            self.shapeNode = shape
            
        case .quadDamage:
            let shape = SKShapeNode(circleOfRadius: 18)
            shape.fillColor = SKColor(red: 1.0, green: 0.2, blue: 0.8, alpha: 0.8)
            shape.strokeColor = .white
            shape.lineWidth = 2.0
            shape.glowWidth = 8.0
            shape.blendMode = .add
            
            let icon = SKLabelNode(text: "⚡")
            icon.fontSize = 18
            icon.fontColor = .white
            icon.verticalAlignmentMode = .center
            shape.addChild(icon)
            
            addChild(shape)
            self.shapeNode = shape
        }
    }
    
    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = PhysicsCategory.powerUp
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        self.physicsBody = body
    }
    
    public func magnetizeTowards(target: CGPoint, speed: CGFloat, dt: TimeInterval) {
        let dx = target.x - self.position.x
        let dy = target.y - self.position.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 5 else { return }
        
        let moveX = (dx / distance) * speed * CGFloat(dt)
        let moveY = (dy / distance) * speed * CGFloat(dt)
        self.position.x += moveX
        self.position.y += moveY
    }
}
