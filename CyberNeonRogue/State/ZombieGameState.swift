import Foundation
import SwiftUI

public final class ZombieGameState: ObservableObject {
    public static let shared = ZombieGameState()
    
    // Currency & Scores
    @Published public var cash: Int = 0 {
        didSet { PersistenceManager.shared.saveCrystals(cash) }
    }
    @Published public var highScore: Int = 0 {
        didSet { PersistenceManager.shared.saveHighScore(highScore) }
    }
    @Published public var highestWave: Int = 0 {
        didSet { PersistenceManager.shared.saveHighestWave(highestWave) }
    }
    @Published public var totalZombiesKilled: Int = 0
    @Published public var totalBossesKilled: Int = 0
    
    // Weapons
    @Published public var weapons: [WeaponModel] = []
    @Published public var selectedWeaponId: String = "pistol" {
        didSet { PersistenceManager.shared.saveSelectedWeapon(selectedWeaponId) }
    }
    
    // Heroes
    @Published public var heroes: [HeroModel] = []
    @Published public var selectedHeroId: String = "specops" {
        didSet { PersistenceManager.shared.saveSelectedHero(selectedHeroId) }
    }
    
    // Settings
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
    
    // In-Game Active Run State
    @Published public var currentScore: Int = 0
    @Published public var currentWave: Int = 1
    @Published public var runCash: Int = 0
    @Published public var runKills: Int = 0
    @Published public var isPaused: Bool = false
    @Published public var isGameOver: Bool = false
    @Published public var currentMagAmmo: Int = 12
    @Published public var isReloading: Bool = false
    @Published public var reloadProgress: CGFloat = 0.0
    @Published public var grenadeCount: Int = 3
    @Published public var sentryTurretCount: Int = 1
    @Published public var playerHP: CGFloat = 100.0
    @Published public var playerMaxHP: CGFloat = 100.0
    
    public var selectedWeapon: WeaponModel {
        if let found = weapons.first(where: { $0.id == selectedWeaponId }) {
            return found
        }
        return defaultWeapons[0]
    }
    
    public var selectedHero: HeroModel {
        if let found = heroes.first(where: { $0.id == selectedHeroId }) {
            return found
        }
        return defaultHeroes[0]
    }
    
    // Default Weapons
    public let defaultWeapons: [WeaponModel] = [
        WeaponModel(
            id: "pistol",
            name: "Beretta M9 Taktiki",
            weaponClass: .handgun,
            description: "Dəqiq və sürətli baza tapançası. Sonsuz ehtiyat patron.",
            iconName: "circle.circle",
            baseDamage: 30,
            fireRate: 0.22,
            magSize: 15,
            reloadTime: 1.1,
            bulletSpeed: 950,
            spreadAngle: 0.04,
            pelletCount: 1,
            price: 0,
            isUnlocked: true,
            upgradeLevel: 0,
            accentColorHex: "#00E5FF"
        ),
        WeaponModel(
            id: "shotgun",
            name: "Spas-12 Döyüş Qırmağı",
            weaponClass: .shotgun,
            description: "Yaxın məsafədən 6 güllə saçır və zombiləri güclü geri itələyir.",
            iconName: "burst.fill",
            baseDamage: 22, // 22 x 6 = 132 damage per shot
            fireRate: 0.55,
            magSize: 8,
            reloadTime: 1.8,
            bulletSpeed: 800,
            spreadAngle: 0.28,
            pelletCount: 6,
            price: 400,
            isUnlocked: false,
            upgradeLevel: 0,
            accentColorHex: "#FF9100"
        ),
        WeaponModel(
            id: "ak47",
            name: "AK-74M Hücum Avtomatı",
            weaponClass: .rifle,
            description: "Davamlı sürətli atəş və yüksək məhvedici güc.",
            iconName: "flame.fill",
            baseDamage: 38,
            fireRate: 0.11,
            magSize: 30,
            reloadTime: 1.5,
            bulletSpeed: 1050,
            spreadAngle: 0.08,
            pelletCount: 1,
            price: 900,
            isUnlocked: false,
            upgradeLevel: 0,
            accentColorHex: "#FF1744"
        ),
        WeaponModel(
            id: "minigun",
            name: "Vulcan Ağır Pulemyot",
            weaponClass: .heavy,
            description: "Dəqiqədə yüzlərlə güllə yağdıran nəhəng zombi məhvedicisi.",
            iconName: "wind",
            baseDamage: 32,
            fireRate: 0.07,
            magSize: 100,
            reloadTime: 2.8,
            bulletSpeed: 1100,
            spreadAngle: 0.14,
            pelletCount: 1,
            price: 2000,
            isUnlocked: false,
            upgradeLevel: 0,
            accentColorHex: "#D500F9"
        ),
        WeaponModel(
            id: "flamethrower",
            name: "İnferno Alovatan",
            weaponClass: .special,
            description: "Zombi kütləsini yandıran və yavaşladan alov dalğası.",
            iconName: "bonfire.fill",
            baseDamage: 18,
            fireRate: 0.05,
            magSize: 80,
            reloadTime: 2.0,
            bulletSpeed: 500,
            spreadAngle: 0.35,
            pelletCount: 2,
            price: 3200,
            isUnlocked: false,
            upgradeLevel: 0,
            accentColorHex: "#FF5252"
        ),
        WeaponModel(
            id: "rpg",
            name: "RPG-7 Qumbaraatan",
            weaponClass: .special,
            description: "Böyük sahədəki bütün zombiləri havaya uçuran partlayıcı raket.",
            iconName: "bolt.fill",
            baseDamage: 280,
            fireRate: 1.0,
            magSize: 4,
            reloadTime: 2.4,
            bulletSpeed: 600,
            spreadAngle: 0.02,
            pelletCount: 1,
            price: 4500,
            isUnlocked: false,
            upgradeLevel: 0,
            accentColorHex: "#00E676"
        )
    ]
    
    // Default Heroes
    public let defaultHeroes: [HeroModel] = [
        HeroModel(
            id: "specops",
            name: "Kapitan Miller",
            title: "Xüsusi Təyinatlı",
            description: "Balanslı döyüşçü. Sürətli atəş və standart zireh.",
            iconName: "person.fill.viewfinder",
            baseHealth: 120,
            baseSpeed: 210,
            armorReduction: 0.1,
            startingWeaponId: "pistol",
            price: 0,
            isUnlocked: true,
            accentColorHex: "#00E5FF"
        ),
        HeroModel(
            id: "medic",
            name: "Leytenant Sara",
            title: "Hərbi Həkim",
            description: "Zamanla sağlamlığı bərpa edir və daha sürətli qaçır.",
            iconName: "cross.case.fill",
            baseHealth: 100,
            baseSpeed: 240,
            armorReduction: 0.05,
            startingWeaponId: "shotgun",
            price: 1200,
            isUnlocked: false,
            accentColorHex: "#00E676"
        ),
        HeroModel(
            id: "juggernaut",
            name: "Serjant Qrom",
            title: "Ağır Zirehli Juggernaut",
            description: "Nəhəng can tutumu və 30% zərər azaldan ağır polad zireh.",
            iconName: "shield.fill",
            baseHealth: 220,
            baseSpeed: 170,
            armorReduction: 0.30,
            startingWeaponId: "ak47",
            price: 2500,
            isUnlocked: false,
            accentColorHex: "#FFD600"
        )
    ]
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        self.cash = PersistenceManager.shared.loadCrystals()
        self.highScore = PersistenceManager.shared.loadHighScore()
        self.highestWave = PersistenceManager.shared.loadHighestWave()
        self.soundEnabled = PersistenceManager.shared.loadSoundSetting()
        self.hapticsEnabled = PersistenceManager.shared.loadHapticsSetting()
        self.is120FpsEnabled = PersistenceManager.shared.load120FpsSetting()
        
        AudioManager.shared.soundEnabled = self.soundEnabled
        HapticsManager.shared.hapticsEnabled = self.hapticsEnabled
        
        self.weapons = PersistenceManager.shared.loadWeapons(fallback: defaultWeapons)
        self.selectedWeaponId = PersistenceManager.shared.loadSelectedWeapon()
        
        self.heroes = PersistenceManager.shared.loadHeroes(fallback: defaultHeroes)
        self.selectedHeroId = PersistenceManager.shared.loadSelectedHero()
        
        self.currentMagAmmo = selectedWeapon.currentMagSize
        self.playerHP = selectedHero.baseHealth
        self.playerMaxHP = selectedHero.baseHealth
    }
    
    // MARK: - Store Operations
    
    public func buyWeapon(id: String) -> Bool {
        guard let index = weapons.firstIndex(where: { $0.id == id }) else { return false }
        let weapon = weapons[index]
        guard !weapon.isUnlocked else { return false }
        guard cash >= weapon.price else {
            HapticsManager.shared.playError()
            return false
        }
        
        cash -= weapon.price
        weapons[index].isUnlocked = true
        selectedWeaponId = weapon.id
        PersistenceManager.shared.saveWeapons(weapons)
        AudioManager.shared.playMedkitPick()
        HapticsManager.shared.playSuccess()
        return true
    }
    
    public func upgradeWeapon(id: String) -> Bool {
        guard let index = weapons.firstIndex(where: { $0.id == id }) else { return false }
        let weapon = weapons[index]
        guard weapon.upgradeLevel < 6 else { return false }
        let cost = weapon.upgradeCost
        guard cash >= cost else {
            HapticsManager.shared.playError()
            return false
        }
        
        cash -= cost
        weapons[index].upgradeLevel += 1
        PersistenceManager.shared.saveWeapons(weapons)
        AudioManager.shared.playMedkitPick()
        HapticsManager.shared.playSuccess()
        return true
    }
    
    public func unlockHero(id: String) -> Bool {
        guard let index = heroes.firstIndex(where: { $0.id == id }) else { return false }
        let hero = heroes[index]
        guard !hero.isUnlocked else { return false }
        guard cash >= hero.price else {
            HapticsManager.shared.playError()
            return false
        }
        
        cash -= hero.price
        heroes[index].isUnlocked = true
        selectedHeroId = hero.id
        PersistenceManager.shared.saveHeroes(heroes)
        AudioManager.shared.playMedkitPick()
        HapticsManager.shared.playSuccess()
        return true
    }
    
    public func startNewRun() {
        currentScore = 0
        currentWave = 1
        runCash = 0
        runKills = 0
        isPaused = false
        isGameOver = false
        isReloading = false
        reloadProgress = 0.0
        grenadeCount = 3
        sentryTurretCount = 1
        playerHP = selectedHero.baseHealth
        playerMaxHP = selectedHero.baseHealth
        currentMagAmmo = selectedWeapon.currentMagSize
    }
    
    public func endRun() {
        isGameOver = true
        cash += runCash
        if currentScore > highScore {
            highScore = currentScore
        }
        if currentWave > highestWave {
            highestWave = currentWave
        }
        totalZombiesKilled += runKills
    }
}
