import Foundation
import SwiftUI

// MARK: - Ship Types
public struct ShipModel: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let iconName: String
    public let baseSpeed: CGFloat
    public let baseHealth: CGFloat
    public let baseShield: CGFloat
    public let baseDamage: CGFloat
    public let baseFireRate: TimeInterval
    public let price: Int
    public var isUnlocked: Bool
    public let primaryWeapon: WeaponType
    public let accentColorHex: String
}

public enum WeaponType: String, Codable, CaseIterable {
    case laser = "Laser Blaster"
    case plasma = "Plasma Cannon"
    case tesla = "Tesla Arc"
    case homing = "Homing Swarm"
    case vortex = "Quantum Vortex"
}

// MARK: - Color Themes
public enum ThemePalette: String, Codable, CaseIterable, Identifiable {
    case cyberNeon = "Cyber Neon"
    case synthwave = "Synthwave 80s"
    case voidMatrix = "Void Matrix"
    case solarFlare = "Solar Flare"
    
    public var id: String { rawValue }
    
    public var primaryColor: Color {
        switch self {
        case .cyberNeon: return Color(red: 0.0, green: 0.95, blue: 1.0) // Cyan
        case .synthwave: return Color(red: 0.95, green: 0.2, blue: 0.8) // Neon Pink/Purple
        case .voidMatrix: return Color(red: 0.1, green: 1.0, blue: 0.4) // Neon Green
        case .solarFlare: return Color(red: 1.0, green: 0.35, blue: 0.0) // Neon Orange
        }
    }
    
    public var secondaryColor: Color {
        switch self {
        case .cyberNeon: return Color(red: 1.0, green: 0.08, blue: 0.58) // Hot Pink
        case .synthwave: return Color(red: 0.3, green: 0.6, blue: 1.0) // Sky Blue
        case .voidMatrix: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case .solarFlare: return Color(red: 1.0, green: 0.9, blue: 0.0) // Bright Yellow
        }
    }
    
    public var backgroundGradient: LinearGradient {
        switch self {
        case .cyberNeon:
            return LinearGradient(colors: [Color(red: 0.04, green: 0.04, blue: 0.12), Color(red: 0.01, green: 0.01, blue: 0.04)], startPoint: .top, endPoint: .bottom)
        case .synthwave:
            return LinearGradient(colors: [Color(red: 0.12, green: 0.03, blue: 0.18), Color(red: 0.02, green: 0.01, blue: 0.06)], startPoint: .top, endPoint: .bottom)
        case .voidMatrix:
            return LinearGradient(colors: [Color(red: 0.01, green: 0.08, blue: 0.04), Color(red: 0.0, green: 0.02, blue: 0.01)], startPoint: .top, endPoint: .bottom)
        case .solarFlare:
            return LinearGradient(colors: [Color(red: 0.14, green: 0.03, blue: 0.01), Color(red: 0.04, green: 0.01, blue: 0.0)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Permanent Stats Upgrades
public struct UpgradeItem: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public var currentLevel: Int
    public let maxLevel: Int
    public let basePrice: Int
    public let priceMultiplier: Double
    public let bonusPerLevel: Double
    
    public var cost: Int {
        guard currentLevel < maxLevel else { return 0 }
        return Int(Double(basePrice) * pow(priceMultiplier, Double(currentLevel)))
    }
}

// MARK: - Main GameState
public final class GameState: ObservableObject {
    public static let shared = GameState()
    
    // Currency & Scores
    @Published public var cyberCrystals: Int = 0 {
        didSet { PersistenceManager.shared.saveCrystals(cyberCrystals) }
    }
    @Published public var highScore: Int = 0 {
        didSet { PersistenceManager.shared.saveHighScore(highScore) }
    }
    @Published public var highestWave: Int = 0 {
        didSet { PersistenceManager.shared.saveHighestWave(highestWave) }
    }
    
    // Stats tracking
    @Published public var totalEnemiesDestroyed: Int = 0
    @Published public var totalBossesDefeated: Int = 0
    @Published public var totalRunsPlayed: Int = 0
    
    // Ships
    @Published public var availableShips: [ShipModel] = []
    @Published public var selectedShipId: String = "striker" {
        didSet { PersistenceManager.shared.saveSelectedShip(selectedShipId) }
    }
    
    // Permanent Upgrades
    @Published public var permanentUpgrades: [UpgradeItem] = []
    
    // Settings
    @Published public var selectedTheme: ThemePalette = .cyberNeon {
        didSet { PersistenceManager.shared.saveTheme(selectedTheme) }
    }
    @Published public var soundEnabled: Bool = true {
        didSet {
            AudioManager.shared.soundEnabled = soundEnabled
            PersistenceManager.shared.saveSoundSetting(soundEnabled)
        }
    }
    @Published public var hapticsEnabled: Bool = true {
        didSet {
            HapticsManager.shared.hapticsEnabled = hapticsEnabled
            PersistenceManager.shared.saveHapticsSetting(hapticsEnabled)
        }
    }
    @Published public var is120FpsEnabled: Bool = true {
        didSet { PersistenceManager.shared.save120FpsSetting(is120FpsEnabled) }
    }
    @Published public var joystickSensitivity: Double = 1.0
    
    // Current Active Run Info
    @Published public var currentScore: Int = 0
    @Published public var currentWave: Int = 1
    @Published public var runCrystals: Int = 0
    @Published public var playerLevel: Int = 1
    @Published public var playerXP: CGFloat = 0.0
    @Published public var playerNextLevelXP: CGFloat = 100.0
    @Published public var isPaused: Bool = false
    @Published public var isGameOver: Bool = false
    @Published public var isLevelingUp: Bool = false
    @Published public var runKills: Int = 0
    
    public static let fallbackShip = ShipModel(
        id: "striker",
        name: "Cyber Striker",
        description: "Balanslaşdırılmış sürətli qırıcı. Qoşa Lazer topları ilə təchiz olunub.",
        iconName: "bolt.fill",
        baseSpeed: 320,
        baseHealth: 100,
        baseShield: 50,
        baseDamage: 25,
        baseFireRate: 0.28,
        price: 0,
        isUnlocked: true,
        primaryWeapon: .laser,
        accentColorHex: "#00F0FF"
    )
    
    public var selectedShip: ShipModel {
        if let ship = availableShips.first(where: { $0.id == selectedShipId }) {
            return ship
        }
        if let first = availableShips.first {
            return first
        }
        return GameState.fallbackShip
    }
    
    private init() {
        loadInitialData()
    }
    
    private func loadInitialData() {
        self.cyberCrystals = PersistenceManager.shared.loadCrystals()
        self.highScore = PersistenceManager.shared.loadHighScore()
        self.highestWave = PersistenceManager.shared.loadHighestWave()
        self.selectedTheme = PersistenceManager.shared.loadTheme()
        self.soundEnabled = PersistenceManager.shared.loadSoundSetting()
        self.hapticsEnabled = PersistenceManager.shared.loadHapticsSetting()
        self.is120FpsEnabled = PersistenceManager.shared.load120FpsSetting()
        
        AudioManager.shared.soundEnabled = self.soundEnabled
        HapticsManager.shared.hapticsEnabled = self.hapticsEnabled
        
        // Initialize Default Ships
        let defaultShips: [ShipModel] = [
            ShipModel(
                id: "striker",
                name: "Cyber Striker",
                description: "Balanslaşdırılmış sürətli qırıcı. Qoşa Lazer topları ilə təchiz olunub.",
                iconName: "bolt.fill",
                baseSpeed: 320,
                baseHealth: 100,
                baseShield: 50,
                baseDamage: 25,
                baseFireRate: 0.28,
                price: 0,
                isUnlocked: true,
                primaryWeapon: .laser,
                accentColorHex: "#00F0FF"
            ),
            ShipModel(
                id: "phantom",
                name: "Vortex Phantom",
                description: "Çox cəld və kritik zərbə ehtimalı yüksək gəmi. Tesla İldırımı yayır.",
                iconName: "waveform.path.ecg",
                baseSpeed: 380,
                baseHealth: 75,
                baseShield: 40,
                baseDamage: 35,
                baseFireRate: 0.22,
                price: 500,
                isUnlocked: false,
                primaryWeapon: .tesla,
                accentColorHex: "#FF007F"
            ),
            ShipModel(
                id: "titan",
                name: "Titan Dreadnought",
                description: "Ağır zirehli nəhəng gəmi. Dağıdıcı Plazma Topu atır.",
                iconName: "shield.lefthalf.filled",
                baseSpeed: 240,
                baseHealth: 200,
                baseShield: 120,
                baseDamage: 60,
                baseFireRate: 0.45,
                price: 1200,
                isUnlocked: false,
                primaryWeapon: .plasma,
                accentColorHex: "#00FF66"
            ),
            ShipModel(
                id: "spectre",
                name: "Solar Spectre",
                description: "Avtomatik hədəflənən Homing raketləri və sürətli enerji bərpası.",
                iconName: "sun.max.fill",
                baseSpeed: 340,
                baseHealth: 110,
                baseShield: 70,
                baseDamage: 40,
                baseFireRate: 0.25,
                price: 2500,
                isUnlocked: false,
                primaryWeapon: .homing,
                accentColorHex: "#FFAA00"
            )
        ]
        
        self.availableShips = PersistenceManager.shared.loadShips(fallback: defaultShips)
        self.selectedShipId = PersistenceManager.shared.loadSelectedShip()
        
        // Initialize Default Upgrades
        let defaultUpgrades: [UpgradeItem] = [
            UpgradeItem(id: "hp", title: "Maksimal Korpus (HP)", description: "Gəminin baza dözümlülüyünü artırır", icon: "heart.fill", currentLevel: 0, maxLevel: 10, basePrice: 100, priceMultiplier: 1.5, bonusPerLevel: 15.0),
            UpgradeItem(id: "shield", title: "Kvant Qalxanı", description: "Enerji qalxanının tutumunu və bərpa sürətini artırır", icon: "shield.fill", currentLevel: 0, maxLevel: 10, basePrice: 150, priceMultiplier: 1.5, bonusPerLevel: 10.0),
            UpgradeItem(id: "damage", title: "Lazer Zərbəsi", description: "Bütün silahlardan çıxan ümumi zərəri çoxaldır", icon: "flame.fill", currentLevel: 0, maxLevel: 10, basePrice: 200, priceMultiplier: 1.6, bonusPerLevel: 0.12),
            UpgradeItem(id: "firerate", title: "Atəş Tezliyi", description: "Silahların soyuma müddətini qısaldır", icon: "speedometer", currentLevel: 0, maxLevel: 8, basePrice: 250, priceMultiplier: 1.7, bonusPerLevel: 0.08),
            UpgradeItem(id: "magnet", title: "Kristal Maqniti", description: "Uzaqdakı XP və Kristalları gəmiyə çəkir", icon: "sparkles", currentLevel: 0, maxLevel: 5, basePrice: 120, priceMultiplier: 1.6, bonusPerLevel: 30.0),
            UpgradeItem(id: "crit", title: "Kritik Vuruş Şansı", description: "2 qat güclü kritik zərbə endirmə ehtimalı", icon: "scope", currentLevel: 0, maxLevel: 8, basePrice: 300, priceMultiplier: 1.7, bonusPerLevel: 0.05)
        ]
        
        self.permanentUpgrades = PersistenceManager.shared.loadUpgrades(fallback: defaultUpgrades)
    }
    
    // MARK: - Purchase Logic
    public func buyUpgrade(id: String) -> Bool {
        guard let index = permanentUpgrades.firstIndex(where: { $0.id == id }) else { return false }
        let upgrade = permanentUpgrades[index]
        guard upgrade.currentLevel < upgrade.maxLevel else { return false }
        guard cyberCrystals >= upgrade.cost else {
            HapticsManager.shared.playError()
            return false
        }
        
        cyberCrystals -= upgrade.cost
        permanentUpgrades[index].currentLevel += 1
        PersistenceManager.shared.saveUpgrades(permanentUpgrades)
        AudioManager.shared.playPowerupSound()
        HapticsManager.shared.playSuccess()
        return true
    }
    
    public func unlockShip(id: String) -> Bool {
        guard let index = availableShips.firstIndex(where: { $0.id == id }) else { return false }
        let ship = availableShips[index]
        guard !ship.isUnlocked else { return false }
        guard cyberCrystals >= ship.price else {
            HapticsManager.shared.playError()
            return false
        }
        
        cyberCrystals -= ship.price
        availableShips[index].isUnlocked = true
        selectedShipId = ship.id
        PersistenceManager.shared.saveShips(availableShips)
        AudioManager.shared.playPowerupSound()
        HapticsManager.shared.playSuccess()
        return true
    }
    
    // MARK: - Run Reset
    public func startNewRun() {
        currentScore = 0
        currentWave = 1
        runCrystals = 0
        playerLevel = 1
        playerXP = 0.0
        playerNextLevelXP = 100.0
        isPaused = false
        isGameOver = false
        isLevelingUp = false
        runKills = 0
        totalRunsPlayed += 1
    }
    
    public func endRun() {
        isGameOver = true
        cyberCrystals += runCrystals
        if currentScore > highScore {
            highScore = currentScore
        }
        if currentWave > highestWave {
            highestWave = currentWave
        }
        totalEnemiesDestroyed += runKills
    }
    
    // MARK: - Bonus Calculations
    public func getUpgradeBonus(for id: String) -> Double {
        guard let upgrade = permanentUpgrades.first(where: { $0.id == id }) else { return 0.0 }
        return Double(upgrade.currentLevel) * upgrade.bonusPerLevel
    }
}
