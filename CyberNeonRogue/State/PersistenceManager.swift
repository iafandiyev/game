import Foundation

/// Handles persistent local storage of player currency, upgrades, high scores, and settings
public final class PersistenceManager {
    public static let shared = PersistenceManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let crystals = "cyber_crystals_key"
        static let highScore = "high_score_key"
        static let highestWave = "highest_wave_key"
        static let selectedShip = "selected_ship_id_key"
        static let theme = "selected_theme_key"
        static let sound = "sound_enabled_key"
        static let haptics = "haptics_enabled_key"
        static let fps120 = "fps120_enabled_key"
        static let upgrades = "permanent_upgrades_json_key"
        static let ships = "available_ships_json_key"
    }
    
    private init() {}
    
    // MARK: - Crystals
    public func saveCrystals(_ amount: Int) {
        defaults.set(amount, forKey: Keys.crystals)
    }
    public func loadCrystals() -> Int {
        defaults.integer(forKey: Keys.crystals)
    }
    
    // MARK: - High Scores
    public func saveHighScore(_ score: Int) {
        defaults.set(score, forKey: Keys.highScore)
    }
    public func loadHighScore() -> Int {
        defaults.integer(forKey: Keys.highScore)
    }
    
    public func saveHighestWave(_ wave: Int) {
        defaults.set(wave, forKey: Keys.highestWave)
    }
    public func loadHighestWave() -> Int {
        let wave = defaults.integer(forKey: Keys.highestWave)
        return wave > 0 ? wave : 1
    }
    
    // MARK: - Selected Ship
    public func saveSelectedShip(_ shipId: String) {
        defaults.set(shipId, forKey: Keys.selectedShip)
    }
    public func loadSelectedShip() -> String {
        defaults.string(forKey: Keys.selectedShip) ?? "striker"
    }
    
    // MARK: - Theme & Settings
    public func saveTheme(_ theme: ThemePalette) {
        defaults.set(theme.rawValue, forKey: Keys.theme)
    }
    public func loadTheme() -> ThemePalette {
        if let raw = defaults.string(forKey: Keys.theme), let theme = ThemePalette(rawValue: raw) {
            return theme
        }
        return .cyberNeon
    }
    
    public func saveSoundSetting(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.sound)
    }
    public func loadSoundSetting() -> Bool {
        if defaults.object(forKey: Keys.sound) == nil { return true }
        return defaults.bool(forKey: Keys.sound)
    }
    
    public func saveHapticsSetting(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.haptics)
    }
    public func loadHapticsSetting() -> Bool {
        if defaults.object(forKey: Keys.haptics) == nil { return true }
        return defaults.bool(forKey: Keys.haptics)
    }
    
    public func save120FpsSetting(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.fps120)
    }
    public func load120FpsSetting() -> Bool {
        if defaults.object(forKey: Keys.fps120) == nil { return true }
        return defaults.bool(forKey: Keys.fps120)
    }
    
    // MARK: - Ships Persistence
    public func saveShips(_ ships: [ShipModel]) {
        if let encoded = try? JSONEncoder().encode(ships) {
            defaults.set(encoded, forKey: Keys.ships)
        }
    }
    public func loadShips(fallback: [ShipModel]) -> [ShipModel] {
        guard let data = defaults.data(forKey: Keys.ships),
              let decoded = try? JSONDecoder().decode([ShipModel].self, from: data) else {
            return fallback
        }
        return decoded
    }
    
    // MARK: - Upgrades Persistence
    public func saveUpgrades(_ upgrades: [UpgradeItem]) {
        if let encoded = try? JSONEncoder().encode(upgrades) {
            defaults.set(encoded, forKey: Keys.upgrades)
        }
    }
    public func loadUpgrades(fallback: [UpgradeItem]) -> [UpgradeItem] {
        guard let data = defaults.data(forKey: Keys.upgrades),
              let decoded = try? JSONDecoder().decode([UpgradeItem].self, from: data) else {
            return fallback
        }
        return decoded
    }
}
