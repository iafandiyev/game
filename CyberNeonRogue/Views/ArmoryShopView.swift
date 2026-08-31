import SwiftUI

public struct ArmoryShopView: View {
    @ObservedObject var gameState: ZombieGameState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: Int = 0 // 0: Weapons, 1: Heroes
    @State private var previewWeaponId: String = "pistol"
    
    public var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.09).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // Top Header Bar
                HStack {
                    Button(action: {
                        HapticsManager.shared.playLight()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("GERİ")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Tab Switcher
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            Text("SİLAHXANA")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedTab == 0 ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(selectedTab == 0 ? Color.yellow : Color.clear)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { selectedTab = 1 }) {
                            Text("QƏHRƏMANLAR")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedTab == 1 ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(selectedTab == 1 ? Color.yellow : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Cash Balance
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.green)
                        Text("\(gameState.cash)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                // Content
                if selectedTab == 0 {
                    weaponsView
                } else {
                    heroesView
                }
            }
        }
        .onAppear {
            previewWeaponId = gameState.selectedWeaponId
        }
    }
    
    private var previewWeapon: WeaponModel {
        gameState.weapons.first(where: { $0.id == previewWeaponId }) ?? gameState.weapons[0]
    }
    
    // MARK: - Weapons View (Split Landscape Layout)
    private var weaponsView: some View {
        HStack(spacing: 16) {
            // Left List: Weapon Selector
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(gameState.weapons) { weapon in
                        let isSelected = (weapon.id == previewWeaponId)
                        let isEquipped = (weapon.id == gameState.selectedWeaponId)
                        
                        Button(action: {
                            previewWeaponId = weapon.id
                            HapticsManager.shared.playLight()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: weapon.iconName)
                                    .font(.system(size: 18))
                                    .foregroundColor(isSelected ? .yellow : .white)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(weapon.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(weapon.weaponClass.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                if isEquipped {
                                    Text("SEÇİLDİ")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                } else if !weapon.isUnlocked {
                                    Text("$\(weapon.price)")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(.yellow)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            .frame(width: 280)
            
            // Right Card: Weapon Stats & Actions
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(previewWeapon.name)
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                        Text(previewWeapon.description)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                    Spacer()
                    
                    if previewWeapon.isUnlocked {
                        Text("Təkmilləşdirmə: Lvl \(previewWeapon.upgradeLevel)/6")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(6)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
                
                // Stats Bars
                VStack(spacing: 6) {
                    ArmoryStatBar(name: "Zərbə Gücü", val: "\(Int(previewWeapon.currentDamage))", ratio: previewWeapon.currentDamage / 300, color: .red)
                    ArmoryStatBar(name: "Daraq Tutumu", val: "\(previewWeapon.currentMagSize) Güllə", ratio: CGFloat(previewWeapon.currentMagSize) / 100, color: .yellow)
                    ArmoryStatBar(name: "Doldurma Sürəti", val: String(format: "%.1fs", previewWeapon.currentReloadTime), ratio: CGFloat(3.0 - previewWeapon.currentReloadTime) / 2.5, color: .green)
                    ArmoryStatBar(name: "Atəş Tezliyi", val: String(format: "%.2fs", previewWeapon.fireRate), ratio: CGFloat(1.0 - previewWeapon.fireRate), color: .cyan)
                }
                .padding(10)
                .background(Color.black.opacity(0.4).cornerRadius(10))
                
                Spacer()
                
                // Action Buttons (Equip / Unlock / Upgrade)
                HStack(spacing: 12) {
                    if previewWeapon.isUnlocked {
                        if gameState.selectedWeaponId != previewWeapon.id {
                            Button(action: {
                                gameState.selectedWeaponId = previewWeapon.id
                                HapticsManager.shared.playLight()
                            }) {
                                Text("SİLAHI GÖTÜR")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.yellow)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if previewWeapon.upgradeLevel < 6 {
                            Button(action: {
                                _ = gameState.upgradeWeapon(id: previewWeapon.id)
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("GÜCLƏNDİR ($\(previewWeapon.upgradeCost))")
                                }
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(gameState.cash >= previewWeapon.upgradeCost ? .black : .white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(gameState.cash >= previewWeapon.upgradeCost ? Color.cyan : Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .disabled(gameState.cash < previewWeapon.upgradeCost)
                        }
                    } else {
                        Button(action: {
                            _ = gameState.buyWeapon(id: previewWeapon.id)
                        }) {
                            HStack {
                                Image(systemName: "lock.open.fill")
                                Text("KİLİDİ AÇ ($\(previewWeapon.price))")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(gameState.cash >= previewWeapon.price ? .black : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(gameState.cash >= previewWeapon.price ? Color.green : Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(gameState.cash < previewWeapon.price)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06).cornerRadius(14))
            .padding(.trailing, 24)
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Heroes View
    private var heroesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(gameState.heroes) { hero in
                    let isEquipped = (hero.id == gameState.selectedHeroId)
                    
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Image(systemName: hero.iconName)
                                .font(.system(size: 28))
                                .foregroundColor(.yellow)
                        }
                        
                        Text(hero.name)
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                        
                        Text(hero.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text(hero.description)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(width: 170, height: 32)
                        
                        VStack(spacing: 4) {
                            Text("Sağlamlıq: \(Int(hero.baseHealth)) HP")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                            Text("Sürət: \(Int(hero.baseSpeed))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        
                        Spacer()
                        
                        if hero.isUnlocked {
                            if isEquipped {
                                Text("SEÇİLDİ")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.green)
                                    .padding(.vertical, 8)
                            } else {
                                Button(action: {
                                    gameState.selectedHeroId = hero.id
                                    HapticsManager.shared.playLight()
                                }) {
                                    Text("SEÇ")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.yellow)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Button(action: {
                                _ = gameState.unlockHero(id: hero.id)
                            }) {
                                Text("AÇ ($\(hero.price))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(gameState.cash >= hero.price ? .black : .white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(gameState.cash >= hero.price ? Color.green : Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .disabled(gameState.cash < hero.price)
                        }
                    }
                    .padding(14)
                    .frame(width: 200, height: 260)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isEquipped ? Color.green : Color.white.opacity(0.1), lineWidth: isEquipped ? 2 : 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 14)
        }
    }
}

fileprivate struct ArmoryStatBar: View {
    let name: String
    let val: String
    let ratio: CGFloat
    let color: Color
    
    var body: some View {
        HStack {
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 100, alignment: .leading)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 5)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(4, min(140, 140 * ratio)), height: 5)
            }
            
            Spacer()
            
            Text(val)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
