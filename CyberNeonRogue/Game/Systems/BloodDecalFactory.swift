import SpriteKit
import UIKit

/// High-performance visual effects engine for AAA-feel 2D combat: gore splatters, flying gibs, shell casings, floating damage numbers
public final class BloodDecalFactory {
    
    // MARK: - Safe Procedural Textures
    private static var _circleTex: SKTexture?
    public static var circleTexture: SKTexture {
        if let tex = _circleTex { return tex }
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 14, height: 14))
        }
        let tex = SKTexture(image: img)
        _circleTex = tex
        return tex
    }
    
    private static var _casingTex: SKTexture?
    public static var casingTexture: SKTexture {
        if let tex = _casingTex { return tex }
        let size = CGSize(width: 6, height: 3)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor(red: 0.95, green: 0.8, blue: 0.2, alpha: 1.0).setFill()
            ctx.cgContext.fill(CGRect(origin: .zero, size: size))
        }
        let tex = SKTexture(image: img)
        _casingTex = tex
        return tex
    }
    
    // MARK: - High-Detail Floor Blood Stain
    public static func createBloodDecal(at point: CGPoint, isGreenAcid: Bool = false) -> SKNode {
        let container = SKNode()
        container.position = point
        container.zPosition = 1
        
        let path = CGMutablePath()
        let blobCount = Int.random(in: 4...8)
        let primaryColor = isGreenAcid ? SKColor(red: 0.1, green: 0.85, blue: 0.1, alpha: 0.75) : SKColor(red: 0.65, green: 0.05, blue: 0.05, alpha: 0.8)
        
        // Central puddle
        let mainRadius = CGFloat.random(in: 12...22)
        path.addEllipse(in: CGRect(x: -mainRadius/2, y: -mainRadius/2, width: mainRadius, height: mainRadius))
        
        // Splattered droplets
        for _ in 0..<blobCount {
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 8...28)
            let r = CGFloat.random(in: 3...7)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            path.addEllipse(in: CGRect(x: dx - r/2, y: dy - r/2, width: r, height: r))
        }
        
        let shape = SKShapeNode(path: path)
        shape.fillColor = primaryColor
        shape.strokeColor = .clear
        container.addChild(shape)
        
        // Fade out and remove after 25s
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 20.0),
            SKAction.fadeOut(withDuration: 5.0),
            SKAction.removeFromParent()
        ]))
        
        return container
    }
    
    // MARK: - Ejected Bullet Shell Casing
    public static func createShellCasing(at point: CGPoint, angle: CGFloat) -> SKSpriteNode {
        let casing = SKSpriteNode(texture: casingTexture, size: CGSize(width: 5, height: 2.5))
        casing.position = point
        casing.zRotation = angle + CGFloat.random(in: -0.4...0.4)
        casing.zPosition = 2
        
        // Eject physics impulse
        let ejectAngle = angle - (CGFloat.pi / 2) + CGFloat.random(in: -0.3...0.3)
        let speed = CGFloat.random(in: 70...120)
        let dx = cos(ejectAngle) * speed * 0.2
        let dy = sin(ejectAngle) * speed * 0.2
        
        let fly = SKAction.moveBy(x: dx, y: dy, duration: 0.2)
        fly.timingMode = .easeOut
        let spin = SKAction.rotate(byAngle: CGFloat.random(in: 2...8), duration: 0.2)
        
        casing.run(SKAction.group([fly, spin]))
        casing.run(SKAction.sequence([
            SKAction.wait(forDuration: 8.0),
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))
        return casing
    }
    
    // MARK: - Blood Spray / Flesh Particle Emitter
    public static func createBloodSpray(at point: CGPoint, angle: CGFloat, isAcid: Bool = false) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = circleTexture
        emitter.particlePosition = point
        emitter.particleBirthRate = 280
        emitter.numParticlesToEmit = 22
        emitter.particleLifetime = 0.3
        emitter.particleSpeed = 190
        emitter.particleSpeedRange = 90
        emitter.emissionAngle = angle
        emitter.emissionAngleRange = .pi / 3
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.7
        emitter.particleColor = isAcid ? SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0) : SKColor(red: 0.85, green: 0.05, blue: 0.05, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 6
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.removeFromParent()
        ]))
        return emitter
    }
    
    // MARK: - Flying Zombie Gibs / Flesh Chunks on Explosions & Critical Kills
    public static func createZombieGibs(at point: CGPoint, isAcid: Bool = false) -> [SKShapeNode] {
        var gibs: [SKShapeNode] = []
        let count = Int.random(in: 4...7)
        let color = isAcid ? SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0) : SKColor(red: 0.45, green: 0.1, blue: 0.1, alpha: 1.0)
        
        for _ in 0..<count {
            let gib = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8)), cornerRadius: 2)
            gib.fillColor = color
            gib.strokeColor = .black
            gib.lineWidth = 0.5
            gib.position = point
            gib.zPosition = 4
            
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 30...90)
            let fly = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.35)
            fly.timingMode = .easeOut
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -6...6), duration: 0.35)
            
            gib.run(SKAction.group([fly, spin]))
            gib.run(SKAction.sequence([
                SKAction.wait(forDuration: 12.0),
                SKAction.fadeOut(withDuration: 3.0),
                SKAction.removeFromParent()
            ]))
            gibs.append(gib)
        }
        return gibs
    }
    
    // MARK: - Stylized Floating Damage Numbers
    public static func createDamagePopup(at point: CGPoint, damage: Int, isCrit: Bool = false) -> SKLabelNode {
        let label = SKLabelNode()
        label.text = isCrit ? "CRIT -\(damage)!" : "-\(damage)"
        label.fontName = "HelveticaNeue-Black"
        label.fontSize = isCrit ? 16 : 12
        label.fontColor = isCrit ? SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0) : (damage > 50 ? .orange : .white)
        label.position = CGPoint(x: point.x + CGFloat.random(in: -10...10), y: point.y + 15)
        label.zPosition = 25
        
        let rise = SKAction.moveBy(x: CGFloat.random(in: -12...12), y: 35, duration: 0.5)
        rise.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.sequence([
            SKAction.scale(to: isCrit ? 1.4 : 1.15, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        
        label.run(SKAction.group([rise, scale]))
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            fade,
            SKAction.removeFromParent()
        ]))
        return label
    }
    
    // MARK: - Muzzle Flash Flare
    public static func createMuzzleFlash(at point: CGPoint, angle: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 22, y: -7))
        path.addLine(to: CGPoint(x: 32, y: 0))
        path.addLine(to: CGPoint(x: 22, y: 7))
        path.closeSubpath()
        
        let flash = SKShapeNode(path: path)
        flash.position = point
        flash.zRotation = angle
        flash.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        flash.strokeColor = .orange
        flash.lineWidth = 1.0
        flash.glowWidth = 8.0
        flash.blendMode = .add
        flash.zPosition = 15
        
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.04),
            SKAction.removeFromParent()
        ]))
        return flash
    }
    
    // MARK: - Heavy Shockwave Explosion
    public static func createExplosion(at point: CGPoint, radius: CGFloat = 140) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = circleTexture
        emitter.particlePosition = point
        emitter.particleBirthRate = 450
        emitter.numParticlesToEmit = 60
        emitter.particleLifetime = 0.55
        emitter.particleSpeed = 260
        emitter.particleSpeedRange = 120
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.8
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -1.2
        emitter.particleColor = SKColor(red: 1.0, green: 0.4, blue: 0.05, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        emitter.zPosition = 20
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.removeFromParent()
        ]))
        return emitter
    }
}
