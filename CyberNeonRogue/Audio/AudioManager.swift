import Foundation
import AVFoundation
import UIKit

/// High-reliability procedural audio synthesizer using AVAudioPlayer and in-memory PCM buffers
public final class AudioManager: ObservableObject {
    public static let shared = AudioManager()
    
    // Volume controls
    public var soundEnabled: Bool = true
    public var sfxVolume: Float = 0.8
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
            print("Audio session setup failed: \(error.localizedDescription)")
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
                if self.activePlayers.count > 20 {
                    self.activePlayers.removeAll(where: { !$0.isPlaying })
                }
            } catch {
                print("Sound playback error: \(error)")
            }
        }
    }
    
    // MARK: - SFX Triggers
    
    public func playLaserSound(pitch: Double = 880.0) {
        let key = "laser_\(Int(pitch))"
        playSound(key: key, volume: 0.6) {
            generateSweepWav(startFreq: pitch, endFreq: 220.0, duration: 0.12, isSawtooth: true)
        }
    }
    
    public func playPlasmaSound() {
        playSound(key: "plasma", volume: 0.75) {
            generateSweepWav(startFreq: 440.0, endFreq: 90.0, duration: 0.22, isSawtooth: false)
        }
    }
    
    public func playTeslaSound() {
        playSound(key: "tesla", volume: 0.6) {
            generateNoiseWav(duration: 0.18, isElectric: true)
        }
    }
    
    public func playExplosionSound(isBig: Bool = false) {
        let key = isBig ? "explosion_big" : "explosion_small"
        playSound(key: key, volume: isBig ? 0.9 : 0.6) {
            generateNoiseWav(duration: isBig ? 0.45 : 0.25, isElectric: false)
        }
    }
    
    public func playCoinSound() {
        playSound(key: "coin", volume: 0.5) {
            generateSweepWav(startFreq: 987.77, endFreq: 1318.51, duration: 0.08, isSawtooth: false)
        }
    }
    
    public func playPowerupSound() {
        playSound(key: "powerup", volume: 0.7) {
            generateArpeggioWav(notes: [440.0, 554.37, 659.25, 880.0], noteDuration: 0.06)
        }
    }
    
    public func playLevelUpSound() {
        playSound(key: "levelup", volume: 0.8) {
            generateArpeggioWav(notes: [523.25, 659.25, 783.99, 1046.50], noteDuration: 0.09)
        }
    }
    
    public func playBossAlarm() {
        playSound(key: "boss_alarm", volume: 0.85) {
            generateSweepWav(startFreq: 400.0, endFreq: 800.0, duration: 0.35, isSawtooth: true)
        }
    }
    
    public func playPlayerHitSound() {
        playSound(key: "player_hit", volume: 0.75) {
            generateSweepWav(startFreq: 260.0, endFreq: 80.0, duration: 0.16, isSawtooth: false)
        }
    }
    
    // MARK: - In-Memory WAV Synthesizer
    
    private func generateSweepWav(startFreq: Double, endFreq: Double, duration: Double, isSawtooth: Bool) -> Data {
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress
            let phase = 2.0 * Double.pi * freq * t
            let sample: Float = isSawtooth ? Float((phase / Double.pi).truncatingRemainder(dividingBy: 2.0) - 1.0) : Float(sin(phase))
            let envelope = Float(1.0 - progress)
            return sample * envelope
        }
    }
    
    private func generateNoiseWav(duration: Double, isElectric: Bool) -> Data {
        var lastVal: Float = 0.0
        return buildWav(duration: duration, sampleRate: 22050) { t in
            let progress = t / duration
            let raw = Float.random(in: -1.0...1.0)
            let filtered: Float = isElectric ? (raw - lastVal) * 0.7 : (lastVal * 0.85 + raw * 0.15)
            lastVal = filtered
            let envelope = Float(1.0 - sqrt(progress))
            return filtered * envelope
        }
    }
    
    private func generateArpeggioWav(notes: [Double], noteDuration: Double) -> Data {
        let totalDuration = Double(notes.count) * noteDuration
        return buildWav(duration: totalDuration, sampleRate: 22050) { t in
            let noteIndex = min(notes.count - 1, Int(t / noteDuration))
            let noteTime = t - (Double(noteIndex) * noteDuration)
            let freq = notes[noteIndex]
            let phase = 2.0 * Double.pi * freq * noteTime
            let sample = Float(sin(phase))
            let noteProgress = noteTime / noteDuration
            let envelope = Float(1.0 - noteProgress)
            return sample * envelope
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
        
        // RIFF Header
        data.append(contentsOf: "RIFF".utf8)
        data.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
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
        
        // data chunk
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
