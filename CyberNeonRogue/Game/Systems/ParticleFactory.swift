import SpriteKit
import UIKit

/// Factory for generating high-performance neon particles, explosions, trails, and ambient starfields
public final class ParticleFactory {
    
    // MARK: - Procedural Dot Texture
    private static var _sparkTexture: SKTexture?
    public static var sparkTexture: SKTexture {
        if let tex = _sparkTexture { return tex }
        
        let size = CGSize(width: 16, height: 16)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(x: 2, y: 2, width: 12, height: 12)
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: rect)
        }
        let texture = SKTexture(image: image)
        _sparkTexture = texture
        return texture
    }
    
    // MARK: - Explosion Emitter
    public static func createExplosion(at point: CGPoint, color: SKColor, scale: CGFloat = 1.0) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkTexture
        emitter.particlePosition = point
        emitter.particleBirthRate = 250 * scale
        emitter.numParticlesToEmit = Int(40 * scale)
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 160 * scale
        emitter.particleSpeedRange = 80 * scale
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.6 * scale
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.8
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        
        // Auto-remove action
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.removeFromParent()
        ]))
        
        return emitter
    }
    
    // MARK: - Thruster Jet Trail Emitter
    public static func createThrusterTrail(color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkTexture
        emitter.particleBirthRate = 70
        emitter.particleLifetime = 0.25
        emitter.particleLifetimeRange = 0.1
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = -.pi / 2 // Downward
        emitter.emissionAngleRange = .pi / 8
        emitter.particleScale = 0.4
        emitter.particleScaleSpeed = -0.9
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -3.0
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 0.9
        emitter.particleBlendMode = .add
        return emitter
    }
    
    // MARK: - EMP Shockwave Ring
    public static func createShockwaveRing(at point: CGPoint, color: SKColor, maxRadius: CGFloat = 300) -> SKShapeNode {
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.position = point
        ring.strokeColor = color
        ring.lineWidth = 4
        ring.fillColor = .clear
        ring.glowWidth = 8
        ring.blendMode = .add
        
        let expand = SKAction.scale(to: maxRadius / 10, duration: 0.5)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([expand, fade])
        
        ring.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        return ring
    }
    
    // MARK: - Ambient Starfield Background
    public static func createStarfield(sceneSize: CGSize) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkTexture
        emitter.particlePositionRange = CGVector(dx: sceneSize.width * 1.2, dy: 0)
        emitter.particlePosition = CGPoint(x: sceneSize.width / 2, y: sceneSize.height + 20)
        emitter.particleBirthRate = 18
        emitter.particleLifetime = 8.0
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 60
        emitter.emissionAngle = -.pi / 2 // Falling down
        emitter.emissionAngleRange = 0
        emitter.particleScale = 0.25
        emitter.particleScaleRange = 0.15
        emitter.particleAlpha = 0.6
        emitter.particleAlphaRange = 0.4
        emitter.particleColor = SKColor.cyan
        emitter.particleColorBlendFactor = 0.8
        emitter.particleBlendMode = .add
        emitter.advanceSimulationTime(8.0)
        return emitter
    }
}
