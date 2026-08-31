import SpriteKit
import UIKit

public enum DropItemKind {
    case medkit
    case ammoCrate
    case cashBag(amount: Int)
    case sentryTurret
}

public final class DropItemNode: SKNode {
    public let kind: DropItemKind
    
    public init(kind: DropItemKind) {
        self.kind = kind
        super.init()
        
        setupAppearance()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAppearance() {
        let box = SKShapeNode(rectOf: CGSize(width: 22, height: 22), cornerRadius: 4)
        box.lineWidth = 1.5
        box.strokeColor = .white
        
        let label = SKLabelNode()
        label.fontSize = 12
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        switch kind {
        case .medkit:
            box.fillColor = SKColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 0.9)
            label.text = "+"
            label.fontColor = .white
            label.fontName = "HelveticaNeue-Bold"
            label.fontSize = 16
            
        case .ammoCrate:
            box.fillColor = SKColor(red: 0.9, green: 0.6, blue: 0.0, alpha: 0.9)
            label.text = "AMMO"
            label.fontColor = .black
            label.fontName = "HelveticaNeue-Black"
            label.fontSize = 7
            
        case .cashBag:
            box.fillColor = SKColor(red: 0.1, green: 0.8, blue: 0.3, alpha: 0.9)
            label.text = "$"
            label.fontColor = .white
            label.fontName = "HelveticaNeue-Bold"
            label.fontSize = 14
            
        case .sentryTurret:
            box.fillColor = SKColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.9)
            label.text = "⚙"
            label.fontSize = 14
        }
        
        box.addChild(label)
        addChild(box)
        
        // Floating glow pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.4),
            SKAction.scale(to: 0.95, duration: 0.4)
        ])
        box.run(SKAction.repeatForever(pulse))
    }
    
    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: 18)
        body.isDynamic = true
        body.affectedByGravity = false
        body.categoryBitMask = ZombiePhysicsCategory.dropItem
        body.contactTestBitMask = ZombiePhysicsCategory.player
        body.collisionBitMask = 0
        self.physicsBody = body
    }
}
