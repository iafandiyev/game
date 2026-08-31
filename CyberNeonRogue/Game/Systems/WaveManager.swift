import Foundation
import CoreGraphics

public final class WaveManager {
    public var currentWave: Int = 1
    public var waveTimer: TimeInterval = 0
    public var waveDuration: TimeInterval = 35.0 // Seconds per normal wave
    public var spawnTimer: TimeInterval = 0
    public var isBossWave: Bool = false
    public var bossSpawned: Bool = false
    public var isWaveTransitioning: Bool = false
    
    public init() {}
    
    public func reset() {
        currentWave = 1
        waveTimer = 0
        spawnTimer = 0
        isBossWave = false
        bossSpawned = false
        isWaveTransitioning = false
    }
    
    public func update(dt: TimeInterval, onSpawnEnemy: (EnemyType, CGPoint) -> Void, onBossSpawn: () -> Void, onWaveComplete: (Int) -> Void) {
        guard !isWaveTransitioning else { return }
        
        isBossWave = (currentWave % 5 == 0)
        
        if isBossWave {
            if !bossSpawned {
                bossSpawned = true
                onBossSpawn()
            }
            return
        }
        
        waveTimer += dt
        spawnTimer += dt
        
        // Spawn rate scales with wave
        let spawnInterval = max(0.45, 1.4 - (Double(currentWave) * 0.08))
        if spawnTimer >= spawnInterval {
            spawnTimer = 0
            
            // Random enemy type based on wave
            let type: EnemyType
            let rand = Double.random(in: 0...1.0)
            
            if currentWave < 3 {
                type = rand < 0.75 ? .swarmer : .scout
            } else if currentWave < 6 {
                if rand < 0.5 { type = .swarmer }
                else if rand < 0.85 { type = .scout }
                else { type = .stealth }
            } else {
                if rand < 0.35 { type = .swarmer }
                else if rand < 0.65 { type = .scout }
                else if rand < 0.85 { type = .cruiser }
                else { type = .stealth }
            }
            
            // Spawn point along top screen
            let spawnX = CGFloat.random(in: 40...350)
            let spawnY = CGFloat(860)
            onSpawnEnemy(type, CGPoint(x: spawnX, y: spawnY))
        }
        
        // Check wave completion
        if waveTimer >= waveDuration {
            waveTimer = 0
            currentWave += 1
            bossSpawned = false
            onWaveComplete(currentWave)
        }
    }
    
    public func forceNextWave(onWaveComplete: (Int) -> Void) {
        currentWave += 1
        waveTimer = 0
        bossSpawned = false
        onWaveComplete(currentWave)
    }
}
