import Foundation
import SwiftUI

public enum PerkRarity: String, Codable {
    case common = "Adil"
    case rare = "Nadir"
    case epic = "Epik"
    case legendary = "Əfsanəvi"
    
    public var color: Color {
        switch self {
        case .common: return Color.cyan
        case .rare: return Color.blue
        case .epic: return Color.purple
        case .legendary: return Color.orange
        }
    }
}

public struct InGamePerk: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let rarity: PerkRarity
    public var level: Int = 1
    public let maxLevel: Int
    
    public static func == (lhs: InGamePerk, rhs: InGamePerk) -> Bool {
        lhs.id == rhs.id
    }
}

public final class UpgradeSystem {
    public static let shared = UpgradeSystem()
    
    public let allPerks: [InGamePerk] = [
        InGamePerk(
            id: "multishot",
            name: "Çoxqatlı Lazer (Multi-Shot)",
            description: "+1 əlavə güllə və daha geniş atəş bucağı",
            icon: "arrow.triangle.branch",
            rarity: .rare,
            maxLevel: 4
        ),
        InGamePerk(
            id: "plasma_charge",
            name: "Plazma Şarjı",
            description: "+30% baza güllə zərəri və daha böyük zərbə sahəsi",
            icon: "burst.fill",
            rarity: .common,
            maxLevel: 5
        ),
        InGamePerk(
            id: "hyper_drive",
            name: "Hiper Atəş Sürəti",
            description: "Atəş tezliyini +25% artırır",
            icon: "gauge.with.needle.fill",
            rarity: .common,
            maxLevel: 5
        ),
        InGamePerk(
            id: "cryo_freeze",
            name: "Krio Dondurma",
            description: "Güllələr düşmənləri 2 saniyə 40% yavaşladır",
            icon: "snowflake",
            rarity: .rare,
            maxLevel: 3
        ),
        InGamePerk(
            id: "tesla_chain",
            name: "Tesla Zəncirvari İldırımı",
            description: "Hər vuruş yaxınlıqdakı 3 düşmənə zəncirvari ildırım vurur",
            icon: "bolt.horizontal.fill",
            rarity: .epic,
            maxLevel: 4
        ),
        InGamePerk(
            id: "orbital_drone",
            name: "Müdafiə Dronu",
            description: "Gəmi ətrafında fırlanaraq düşmənləri vuran avtomatik dron",
            icon: "circle.dotted.circle.fill",
            rarity: .epic,
            maxLevel: 3
        ),
        InGamePerk(
            id: "vortex_bomb",
            name: "Kvant Qara Dəliyi",
            description: "Hər 8 saniyədən bir düşmənləri içinə çəkən qara dəlik yaradır",
            icon: "circle.hexagongrid.fill",
            rarity: .legendary,
            maxLevel: 3
        ),
        InGamePerk(
            id: "shield_overcharge",
            name: "Qalxan Regenerasiyası",
            description: "Qalxan bərpa sürətini 2 qat artırır və tutumu +50 edir",
            icon: "shield.checkered",
            rarity: .rare,
            maxLevel: 4
        ),
        InGamePerk(
            id: "quantum_magnet",
            name: "Kvant Maqniti",
            description: "Bütün xəritədəki XP və kristalları dərhal özünə çəkir",
            icon: "waveform.badge.magnifyingglass",
            rarity: .common,
            maxLevel: 3
        ),
        InGamePerk(
            id: "berserk_drive",
            name: "Kritik Partlayış",
            description: "Kritik zərbə şansını +20% və kritik zərəri +100% edir",
            icon: "flame.circle.fill",
            rarity: .legendary,
            maxLevel: 3
        )
    ]
    
    /// Generates 3 random perk cards for the level up screen
    public func getRandomPerks(activePerks: [String: Int]) -> [InGamePerk] {
        let available = allPerks.filter { perk in
            let currentLvl = activePerks[perk.id] ?? 0
            return currentLvl < perk.maxLevel
        }
        
        let shuffled = available.shuffled()
        let count = min(3, shuffled.count)
        
        var selected: [InGamePerk] = []
        for i in 0..<count {
            var p = shuffled[i]
            p.level = (activePerks[p.id] ?? 0) + 1
            selected.append(p)
        }
        return selected
    }
}
