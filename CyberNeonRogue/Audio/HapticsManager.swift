import Foundation
import UIKit

/// Manages iOS Taptic Engine / Haptic feedback for tactile game experience
public final class HapticsManager {
    public static let shared = HapticsManager()
    
    public var hapticsEnabled: Bool = true
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        prepare()
    }
    
    public func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        rigidImpact.prepare()
        notificationGenerator.prepare()
    }
    
    public func playLight() {
        guard hapticsEnabled else { return }
        lightImpact.impactOccurred()
    }
    
    public func playMedium() {
        guard hapticsEnabled else { return }
        mediumImpact.impactOccurred()
    }
    
    public func playHeavy() {
        guard hapticsEnabled else { return }
        heavyImpact.impactOccurred()
    }
    
    public func playRigid() {
        guard hapticsEnabled else { return }
        rigidImpact.impactOccurred()
    }
    
    public func playSuccess() {
        guard hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    public func playWarning() {
        guard hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    public func playError() {
        guard hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
}
