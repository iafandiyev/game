import Foundation
import SwiftUI

public enum WeaponClass: String, Codable, CaseIterable {
    case handgun = "Tapança"
    case shotgun = "Qırmaq"
    case rifle = "Avtomat"
    case heavy = "Ağır Pulemyot"
    case special = "Xüsusi Silah"
}

public struct WeaponModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let weaponClass: WeaponClass
    public let description: String
    public let iconName: String
    public let baseDamage: CGFloat
    public let fireRate: TimeInterval
    public let magSize: Int
    public let reloadTime: TimeInterval
    public let bulletSpeed: CGFloat
    public let spreadAngle: CGFloat
    public let pelletCount: Int
    public let price: Int
    public var isUnlocked: Bool
    public var upgradeLevel: Int = 0
    public let accentColorHex: String
    
    public var currentDamage: CGFloat {
        baseDamage * (1.0 + CGFloat(upgradeLevel) * 0.15)
    }
    
    public var currentMagSize: Int {
        magSize + (upgradeLevel * 2)
    }
    
    public var currentReloadTime: TimeInterval {
        max(0.6, reloadTime * (1.0 - Double(upgradeLevel) * 0.05))
    }
    
    public var upgradeCost: Int {
        Int(Double(price > 0 ? price : 200) * 0.5 * pow(1.5, Double(upgradeLevel)))
    }
}

public struct HeroModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let title: String
    public let description: String
    public let iconName: String
    public let baseHealth: CGFloat
    public let baseSpeed: CGFloat
    public let armorReduction: CGFloat
    public let startingWeaponId: String
    public let price: Int
    public var isUnlocked: Bool
    public let accentColorHex: String
}
