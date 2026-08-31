import Foundation
import CoreGraphics

public final class ZombieWaveManager {
    public var currentWave: Int = 1
    public var zombiesRemainingInWave: Int = 15
    public var totalZombiesInWave: Int = 15
    public var spawnTimer: TimeInterval = 0
    public var isBossWave: Bool = false
    public var isWaveActive: Bool = false
    
    public init() {}
    
    public func startWave(waveNumber: Int) {
        self.currentWave = waveNumber
        self.isBossWave = (waveNumber % 5 == 0)
        self.totalZombiesInWave = 12 + (waveNumber * 6)
        self.zombiesRemainingInWave = self.totalZombiesInWave
        self.isWaveActive = true
        self.spawnTimer = 0
    }
    
    public func update(dt: TimeInterval, arenaSize: CGSize, onSpawn: (ZombieType, CGPoint) -> Void, onBossSpawn: (CGPoint) -> Void) {
        guard isWaveActive && zombiesRemainingInWave > 0 else { return }
        
        spawnTimer += dt
        let spawnInterval = max(0.35, 1.3 - (Double(currentWave) * 0.07))
        
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            
            // Random perimeter spawn location
            let spawnPoint = getRandomPerimeterPoint(size: arenaSize)
            
            if isBossWave && zombiesRemainingInWave == totalZombiesInWave {
                // First spawn is Boss
                onBossSpawn(spawnPoint)
                zombiesRemainingInWave -= 1
                return
            }
            
            // Pick zombie type based on wave
            let type: ZombieType
            let rand = Double.random(in: 0...1.0)
            
            if currentWave == 1 {
                type = .walker
            } else if currentWave == 2 {
                type = rand < 0.7 ? .walker : .runner
            } else if currentWave == 3 {
                if rand < 0.5 { type = .walker }
                else if rand < 0.8 { type = .runner }
                else { type = .acidSpitter }
            } else {
                if rand < 0.35 { type = .walker }
                else if rand < 0.65 { type = .runner }
                else if rand < 0.85 { type = .acidSpitter }
                else { type = .boomer }
            }
            
            onSpawn(type, spawnPoint)
            zombiesRemainingInWave -= 1
        }
    }
    
    private func getRandomPerimeterPoint(size: CGSize) -> CGPoint {
        let side = Int.random(in: 0...3) // 0: Top, 1: Right, 2: Bottom, 3: Left
        let margin: CGFloat = 60
        
        switch side {
        case 0: // Top
            return CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + margin)
        case 1: // Right
            return CGPoint(x: size.width + margin, y: CGFloat.random(in: 0...size.height))
        case 2: // Bottom
            return CGPoint(x: CGFloat.random(in: 0...size.width), y: -margin)
        default: // Left
            return CGPoint(x: -margin, y: CGFloat.random(in: 0...size.height))
        }
    }
}
