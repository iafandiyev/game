import Foundation
import AVFoundation
import UIKit

/// High-reliability procedural audio synthesizer for Zombie Survival guns, reloads, screams and explosions
public final class AudioManager: ObservableObject {
    public static let shared = AudioManager()
    
    public var soundEnabled: Bool = true
    public var sfxVolume: Float = 0.85
    public var musicVolume: Float = 0.6
    
    private var activePlayers: [AVAudioPlayer] = []
    private var cachedSounds: [String: Data] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    private func playSound(key: String, volume: Float = 0.7, generator: () -> Data) {
        guard soundEnabled else { return }
        
        let data: Data
        if let cached = cachedSounds[key] {
            data = cached
        } else {
            data = generator()
            cachedSounds[key] = data
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                let player = try AVAudioPlayer(data: data)
                player.volume = min(1.0, max(0.0, volume * self.sfxVolume))
                player.prepareToPlay()
                player.play()
                
                self.activePlayers.append(player)
                if self.activePlayers.count > 25 {
                    self.activePlayers.removeAll(where: { !$0.isPlaying })
                }
            } catch {
                print("Playback error: \(error)")
            }
        }
    }
    
    // MARK: - Weapon Sound Effects
    
    public func playPistolShot() {
        playSound(key: "gun_pistol", volume: 0.7) {
            generateGunshotWav(pitch: 700, decay: 0.12)
        }
    }
    
    public func playShotgunShot() {
        playSound(key: "gun_shotgun", volume: 0.95) {
            generateHeavyGunshotWav(duration: 0.28)
        }
    }
    
    public func playRifleShot() {
        playSound(key: "gun_rifle", volume: 0.75) {
            generateGunshotWav(pitch: 550, decay: 0.09)
        }
    }
    
    public func playMinigunShot() {
        playSound(key: "gun_minigun", volume: 0.65) {
            generateGunshotWav(pitch: 620, decay: 0.06)
        }
    }
    
    public func playFlamethrower() {
        playSound(key: "flamethrower", volume: 0.5) {
            generateNoiseWav(duration: 0.2, isFire: true)
        }
    }
    
    public func playTeslaShot() {
        playSound(key: "gun_tesla", volume: 0.65) {
            generateNoiseWav(duration: 0.15, isFire: false)
        }
    }
    
    public func playReloadSound() {
        playSound(key: "reload_click", volume: 0.65) {
            generateReloadWav()
        }
    }
    
    public func playEmptyGunClick() {
        playSound(key: "empty_click", volume: 0.5) {
            generateToneWav(freq: 900, duration: 0.04)
        }
    }
    
    // MARK: - Zombie & Game Audio
    
    public func playZombieGrowl() {
        playSound(key: "zombie_growl", volume: 0.55) {
            generateZombieGrowlWav(pitch: 140, duration: 0.4)
        }
    }
    
    public func playZombieDeath() {
        playSound(key: "zombie_death", volume: 0.6) {
            generateZombieSplatWav()
        }
    }
    
    public func playZombieBite() {
        playSound(key: "zombie_bite", volume: 0.8) {
            generateToneSweepWav(startFreq: 280, endFreq: 90, duration: 0.18)
        }
    }
    
    public func playBossRoar() {
        playSound(key: "boss_roar", volume: 1.0) {
            generateZombieGrowlWav(pitch: 70, duration: 0.9)
        }
    }
    
    public func playExplosionSound() {
        playSound(key: "explosion_boom", volume: 0.95) {
            generateHeavyExplosionWav(duration: 0.45)
        }
    }
    
    public func playMedkitPick() {
        playSound(key: "pick_medkit", volume: 0.7) {
            generateArpeggioWav(notes: [440, 554, 659, 880], duration: 0.06)
        }
    }
    
    public func playAmmoPick() {
        playSound(key: "pick_ammo", volume: 0.65) {
            generateArpeggioWav(notes: [600, 800, 1000], duration: 0.05)
        }
    }
    
    // MARK: - In-Memory Sound Synthesizers
    
    private func generateGunshotWav(pitch: Double, decay: Double) -> Data {
        return buildWav(duration: decay, sampleRate: 22050) { t in
            let progress = t / decay
            let noise = Float.random(in: -1.0...1.0)
            let tone = Float(sin(2.0 * Double.pi * pitch * (1.0 - progress) * t))
            let mix = (noise * 0.7) + (tone * 0.3)
            let env = Float(pow(1.0 - progress, 2.5))
            return mix * env
        }
    }
    
    private func generateHeavyGunshotWav(duration: Double) -> Data {
        var lastVal: Float = 0.0
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let raw = Float.random(in: -1.0...1.0)
            let filtered = (lastVal * 0.7) + (raw * 0.3)
            lastVal = filtered
            let sub = Float(sin(2.0 * Double.pi * 90.0 * t))
            let mix = (filtered * 0.7) + (sub * 0.4)
            let env = Float(pow(1.0 - progress, 2.0))
            return mix * env
        }
    }
    
    private func generateHeavyExplosionWav(duration: Double) -> Data {
        var lastVal: Float = 0.0
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let raw = Float.random(in: -1.0...1.0)
            let filtered = (lastVal * 0.88) + (raw * 0.12)
            lastVal = filtered
            let env = Float(pow(1.0 - progress, 1.4))
            return filtered * env
        }
    }
    
    private func generateZombieGrowlWav(pitch: Double, duration: Double) -> Data {
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let f = pitch + sin(t * 25.0) * 20.0
            let saw = Float((t * f).truncatingRemainder(dividingBy: 1.0) * 2.0 - 1.0)
            let noise = Float.random(in: -0.3...0.3)
            let env = Float(sin(progress * Double.pi))
            return (saw * 0.7 + noise) * env
        }
    }
    
    private func generateZombieSplatWav() -> Data {
        return buildWav(duration: 0.22, sampleRate: 22050) { t in
            let progress = t / 0.22
            let noise = Float.random(in: -1.0...1.0)
            let squish = Float(sin(2.0 * Double.pi * (180.0 - progress * 90.0) * t))
            let env = Float(pow(1.0 - progress, 2.0))
            return (noise * 0.5 + squish * 0.5) * env
        }
    }
    
    private func generateReloadWav() -> Data {
        return buildWav(duration: 0.35, sampleRate: 22050) { t in
            var sample: Float = 0.0
            if (t > 0.04 && t < 0.12) || (t > 0.22 && t < 0.30) {
                sample = Float.random(in: -0.9...0.9)
            }
            return sample
        }
    }
    
    private func generateToneWav(freq: Double, duration: Double) -> Data {
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            return Float(sin(2.0 * Double.pi * freq * t)) * Float(1.0 - progress)
        }
    }
    
    private func generateToneSweepWav(startFreq: Double, endFreq: Double, duration: Double) -> Data {
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let f = startFreq + (endFreq - startFreq) * progress
            return Float(sin(2.0 * Double.pi * f * t)) * Float(1.0 - progress)
        }
    }
    
    private func generateNoiseWav(duration: Double, isFire: Bool) -> Data {
        var lastVal: Float = 0.0
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let raw = Float.random(in: -1.0...1.0)
            let filtered = isFire ? ((lastVal * 0.8) + (raw * 0.2)) : ((raw - lastVal) * 0.6)
            lastVal = filtered
            return filtered * Float(1.0 - progress * 0.7)
        }
    }
    
    private func generateArpeggioWav(notes: [Double], duration: Double) -> Data {
        let total = Double(notes.count) * duration
        return buildWav(duration: total, sampleRate: 22050) { t in
            let idx = min(notes.count - 1, Int(t / duration))
            let noteTime = t - Double(idx) * duration
            let f = notes[idx]
            let env = Float(1.0 - (noteTime / duration))
            return Float(sin(2.0 * Double.pi * f * noteTime)) * env
        }
    }
    
    private func buildWav(duration: Double, sampleRate: Int, generator: (Double) -> Float) -> Data {
        let numSamples = Int(Double(sampleRate) * duration)
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(numSamples * 2)
        let chunkSize = 36 + dataSize
        
        var data = Data()
        data.reserveCapacity(44 + Int(dataSize))
        
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        let subchunk1Size: Int32 = 16
        let audioFormat: Int16 = 1
        data.append(contentsOf: withUnsafeBytes(of: subchunk1Size.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        let sr = Int32(sampleRate)
        data.append(contentsOf: withUnsafeBytes(of: sr.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })
        data.append(contentsOf: "data".utf8)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })
        
        for i in 0..<numSamples {
            let t = Double(i) / Double(sampleRate)
            let sampleVal = max(-1.0, min(1.0, generator(t)))
            let sampleInt = Int16(sampleVal * 32767.0)
            data.append(contentsOf: withUnsafeBytes(of: sampleInt.littleEndian) { Array($0) })
        }
        return data
    }
}
