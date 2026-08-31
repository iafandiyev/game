import SpriteKit
import UIKit

/// High-performance procedural visual effects for zombie combat: blood splatters, muzzle flash, explosions
public final class BloodDecalFactory {
    
    // MARK: - Safe Procedural Circle Texture
    private static var _circleTexture: SKTexture?
    public static var circleTexture: SKTexture {
        if let tex = _circleTexture { return tex }
        let size = CGSize(width: 14, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 12, height: 12))
        }
        let tex = SKTexture(image: img)
        _circleTexture = tex
        return tex
    }
    
    // MARK: - Blood Splatter on Floor
    public static func createBloodDecal(at point: CGPoint, isGreenAcid: Bool = false) -> SKShapeNode {
        let count = Int.random(in: 3...6)
        let path = CGMutablePath()
        
        for _ in 0..<count {
            let rx = CGFloat.random(in: -14...14)
            let ry = CGFloat.random(in: -14...14)
            let r = CGFloat.random(in: 4...10)
            path.addEllipse(in: CGRect(x: rx - r/2, y: ry - r/2, width: r, height: r))
        }
        
        let blood = SKShapeNode(path: path)
        blood.position = point
        blood.fillColor = isGreenAcid ? SKColor(red: 0.1, green: 0.9, blue: 0.1, alpha: 0.8) : SKColor(red: 0.75, green: 0.05, blue: 0.05, alpha: 0.8)
        blood.strokeColor = .clear
        blood.zPosition = 1 // Above floor, below entities
        
        // Slowly fade after 20 seconds
        blood.run(SKAction.sequence([
            SKAction.wait(forDuration: 15.0),
            SKAction.fadeOut(withDuration: 5.0),
            SKAction.removeFromParent()
        ]))
        
        return blood
    }
    
    // MARK: - Blood Spray Particles
    public static func createBloodSpray(at point: CGPoint, angle: CGFloat, isAcid: Bool = false) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = circleTexture
        emitter.particlePosition = point
        emitter.particleBirthRate = 220
        emitter.numParticlesToEmit = 18
        emitter.particleLifetime = 0.35
        emitter.particleSpeed = 160
        emitter.particleSpeedRange = 80
        emitter.emissionAngle = angle
        emitter.emissionAngleRange = .pi / 4
        emitter.particleScale = 0.4
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.8
        emitter.particleColor = isAcid ? SKColor.green : SKColor(red: 0.8, green: 0.05, blue: 0.05, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.zPosition = 5
        
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        return emitter
    }
    
    // MARK: - Muzzle Flash Flare
    public static func createMuzzleFlash(at point: CGPoint, angle: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 20, y: -6))
        path.addLine(to: CGPoint(x: 28, y: 0))
        path.addLine(to: CGPoint(x: 20, y: 6))
        path.closeSubpath()
        
        let flash = SKShapeNode(path: path)
        flash.position = point
        flash.zRotation = angle
        flash.fillColor = .yellow
        flash.strokeColor = .orange
        flash.glowWidth = 6.0
        flash.blendMode = .add
        flash.zPosition = 15
        
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.removeFromParent()
        ]))
        return flash
    }
    
    // MARK: - Grenade / Rocket Explosion
    public static func createExplosion(at point: CGPoint, radius: CGFloat = 120) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = circleTexture
        emitter.particlePosition = point
        emitter.particleBirthRate = 350
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 0.5
        emitter.particleSpeed = 220
        emitter.particleSpeedRange = 100
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.7
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -1.2
        emitter.particleColor = .orange
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
