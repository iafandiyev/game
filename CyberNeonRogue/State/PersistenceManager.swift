import Foundation

/// Handles persistent local storage of player currency, weapons, heroes, and settings
public final class PersistenceManager {
    public static let shared = PersistenceManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let cash = "zombie_cash_key"
        static let highScore = "high_score_key"
        static let highestWave = "highest_wave_key"
        static let selectedWeapon = "selected_weapon_id_key"
        static let selectedHero = "selected_hero_id_key"
        static let sound = "sound_enabled_key"
        static let haptics = "haptics_enabled_key"
        static let fps120 = "fps120_enabled_key"
        static let weapons = "weapons_json_key"
        static let heroes = "heroes_json_key"
    }
    
    private init() {}
    
    // MARK: - Cash / Crystals
    public func saveCrystals(_ amount: Int) {
        defaults.set(amount, forKey: Keys.cash)
    }
    public func loadCrystals() -> Int {
        defaults.integer(forKey: Keys.cash)
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
    
    // MARK: - Selected Weapon & Hero
    public func saveSelectedWeapon(_ weaponId: String) {
        defaults.set(weaponId, forKey: Keys.selectedWeapon)
    }
    public func loadSelectedWeapon() -> String {
        defaults.string(forKey: Keys.selectedWeapon) ?? "pistol"
    }
    
    public func saveSelectedHero(_ heroId: String) {
        defaults.set(heroId, forKey: Keys.selectedHero)
    }
    public func loadSelectedHero() -> String {
        defaults.string(forKey: Keys.selectedHero) ?? "specops"
    }
    
    // MARK: - Settings
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
    
    // MARK: - Weapons Persistence
    public func saveWeapons(_ weapons: [WeaponModel]) {
        if let encoded = try? JSONEncoder().encode(weapons) {
            defaults.set(encoded, forKey: Keys.weapons)
        }
    }
    public func loadWeapons(fallback: [WeaponModel]) -> [WeaponModel] {
        guard let data = defaults.data(forKey: Keys.weapons),
              let decoded = try? JSONDecoder().decode([WeaponModel].self, from: data) else {
            return fallback
        }
        return decoded
    }
    
    // MARK: - Heroes Persistence
    public func saveHeroes(_ heroes: [HeroModel]) {
        if let encoded = try? JSONEncoder().encode(heroes) {
            defaults.set(encoded, forKey: Keys.heroes)
        }
    }
    public func loadHeroes(fallback: [HeroModel]) -> [HeroModel] {
        guard let data = defaults.data(forKey: Keys.heroes),
              let decoded = try? JSONDecoder().decode([HeroModel].self, from: data) else {
            return fallback
        }
        return decoded
    }
}
