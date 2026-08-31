import Foundation
import AVFoundation

/// Real-time procedural audio synthesizer for dynamic sound effects and ambient synth music
public final class AudioManager: ObservableObject {
    public static let shared = AudioManager()
    
    private var audioEngine: AVAudioEngine?
    private var isEngineRunning = false
    private let sampleRate: Double = 44100.0
    
    // Volume controls
    public var soundEnabled: Bool = true
    public var sfxVolume: Float = 0.8
    public var musicVolume: Float = 0.6
    
    private init() {
        setupAudioSession()
        setupEngine()
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
    
    private func setupEngine() {
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Audio engine start failed: \(error.localizedDescription)")
        }
    }
    
    private func ensureEngineRunning() {
        guard let engine = audioEngine, !engine.isRunning else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("Audio engine restart failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Procedural SFX Generators
    
    /// Plays a synthesized laser blast sound with descending frequency
    public func playLaserSound(pitch: Double = 880.0) {
        guard soundEnabled else { return }
        playToneSweep(startFreq: pitch, endFreq: 220.0, duration: 0.12, volume: sfxVolume * 0.5, waveType: .sawtooth)
    }
    
    /// Plays a synthesized plasma shot sound (heavy deep frequency sweep)
    public func playPlasmaSound() {
        guard soundEnabled else { return }
        playToneSweep(startFreq: 440.0, endFreq: 90.0, duration: 0.22, volume: sfxVolume * 0.6, waveType: .square)
    }
    
    /// Plays an electric tesla arc crackle sound
    public func playTeslaSound() {
        guard soundEnabled else { return }
        playNoiseBurst(duration: 0.18, volume: sfxVolume * 0.45, isElectric: true)
    }
    
    /// Plays an explosion sound with low noise burst
    public func playExplosionSound(isBig: Bool = false) {
        guard soundEnabled else { return }
        let duration = isBig ? 0.45 : 0.25
        let vol = (isBig ? sfxVolume * 0.9 : sfxVolume * 0.6)
        playNoiseBurst(duration: duration, volume: vol, isElectric: false)
    }
    
    /// Plays a pleasant arpeggio chime for level-up / perk unlock
    public func playLevelUpSound() {
        guard soundEnabled else { return }
        let notes: [Double] = [523.25, 659.25, 783.99, 1046.50] // C5, E5, G5, C6
        for (index, freq) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) { [weak self] in
                guard let self = self else { return }
                self.playToneSweep(startFreq: freq, endFreq: freq * 1.05, duration: 0.15, volume: self.sfxVolume * 0.7, waveType: .sine)
            }
        }
    }
    
    /// Plays a crystal/coin pickup chime
    public func playCoinSound() {
        guard soundEnabled else { return }
        playToneSweep(startFreq: 987.77, endFreq: 1318.51, duration: 0.08, volume: sfxVolume * 0.4, waveType: .sine)
    }
    
    /// Plays a powerup acquired sound
    public func playPowerupSound() {
        guard soundEnabled else { return }
        let notes: [Double] = [440.0, 554.37, 659.25, 880.0]
        for (i, note) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) { [weak self] in
                guard let self = self else { return }
                self.playToneSweep(startFreq: note, endFreq: note, duration: 0.1, volume: self.sfxVolume * 0.6, waveType: .triangle)
            }
        }
    }
    
    /// Plays a boss warning siren alarm
    public func playBossAlarm() {
        guard soundEnabled else { return }
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) { [weak self] in
                guard let self = self else { return }
                self.playToneSweep(startFreq: 400.0, endFreq: 800.0, duration: 0.22, volume: self.sfxVolume * 0.8, waveType: .sawtooth)
            }
        }
    }
    
    /// Plays player damage / shield hit sound
    public func playPlayerHitSound() {
        guard soundEnabled else { return }
        playToneSweep(startFreq: 280.0, endFreq: 70.0, duration: 0.15, volume: sfxVolume * 0.7, waveType: .square)
    }
    
    // MARK: - Low Level Synthesis Implementation
    
    private enum WaveType {
        case sine, square, sawtooth, triangle
    }
    
    private func playToneSweep(startFreq: Double, endFreq: Double, duration: Double, volume: Float, waveType: WaveType) {
        ensureEngineRunning()
        guard let engine = audioEngine else { return }
        
        var currentPhase: Double = 0.0
        let totalSamples = Int(sampleRate * duration)
        var sampleIndex = 0
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = ablPointer.first, let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            for frame in 0..<Int(frameCount) {
                if sampleIndex >= totalSamples {
                    data[frame] = 0.0
                } else {
                    let progress = Double(sampleIndex) / Double(totalSamples)
                    let currentFreq = startFreq + (endFreq - startFreq) * progress
                    let phaseIncrement = (2.0 * .pi * currentFreq) / self.sampleRate
                    
                    var sampleVal: Float = 0.0
                    switch waveType {
                    case .sine:
                        sampleVal = Float(sin(currentPhase))
                    case .square:
                        sampleVal = sin(currentPhase) >= 0 ? 1.0 : -1.0
                    case .sawtooth:
                        sampleVal = Float((currentPhase / .pi).truncatingRemainder(dividingBy: 2.0) - 1.0)
                    case .triangle:
                        let norm = (currentPhase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0)
                        sampleVal = Float(2.0 * abs(2.0 * (norm - floor(norm + 0.5))) - 1.0)
                    }
                    
                    let envelope = Float(1.0 - progress)
                    data[frame] = sampleVal * envelope * volume
                    
                    currentPhase += phaseIncrement
                    if currentPhase >= 2.0 * .pi {
                        currentPhase -= 2.0 * .pi
                    }
                    sampleIndex += 1
                }
            }
            return noErr
        }
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
    }
    
    private func playNoiseBurst(duration: Double, volume: Float, isElectric: Bool) {
        ensureEngineRunning()
        guard let engine = audioEngine else { return }
        
        let totalSamples = Int(sampleRate * duration)
        var sampleIndex = 0
        var lastNoise: Float = 0.0
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = ablPointer.first, let data = buffer.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            
            for frame in 0..<Int(frameCount) {
                if sampleIndex >= totalSamples {
                    data[frame] = 0.0
                } else {
                    let progress = Double(sampleIndex) / Double(totalSamples)
                    let rawNoise = Float.random(in: -1.0...1.0)
                    
                    let filtered: Float
                    if isElectric {
                        filtered = (rawNoise - lastNoise) * 0.7
                    } else {
                        filtered = (lastNoise * 0.85) + (rawNoise * 0.15)
                    }
                    lastNoise = filtered
                    
                    let envelope = Float(1.0 - pow(progress, 0.5))
                    data[frame] = filtered * envelope * volume
                    sampleIndex += 1
                }
            }
            return noErr
        }
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
    }
}
