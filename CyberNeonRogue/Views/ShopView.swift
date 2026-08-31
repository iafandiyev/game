import SwiftUI

public struct ShopView: View {
    @ObservedObject var gameState: GameState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: Int = 0 // 0: Ships, 1: Upgrades
    
    public var body: some View {
        ZStack {
            gameState.selectedTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    Button(action: {
                        HapticsManager.shared.playLight()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("KİBER ANQAR & MAĞAZA")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(gameState.selectedTheme.primaryColor)
                    
                    Spacer()
                    
                    // Crystal Balance
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14))
                        Text("\(gameState.cyberCrystals)")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Segmented Tab Picker
                HStack(spacing: 0) {
                    TabPickerButton(title: "KOSMİK GƏMİLƏR", isSelected: selectedTab == 0, themeColor: gameState.selectedTheme.primaryColor) {
                        selectedTab = 0
                    }
                    
                    TabPickerButton(title: "DAİMİ TƏKMİLLƏŞMƏ", isSelected: selectedTab == 1, themeColor: gameState.selectedTheme.primaryColor) {
                        selectedTab = 1
                    }
                }
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                // Tab Content
                if selectedTab == 0 {
                    ShipsHangarTab(gameState: gameState)
                } else {
                    UpgradesListTab(gameState: gameState)
                }
            }
        }
    }
}

fileprivate struct TabPickerButton: View {
    let title: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.playLight()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .black : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? themeColor : Color.clear)
                .cornerRadius(10)
        }
    }
}

// MARK: - Ships Tab
fileprivate struct ShipsHangarTab: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(gameState.availableShips) { ship in
                    let isSelected = (gameState.selectedShipId == ship.id)
                    
                    VStack(spacing: 14) {
                        HStack(spacing: 16) {
                            // Ship Icon Box
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.black.opacity(0.4))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(hex: ship.accentColorHex) ?? Color.cyan, lineWidth: 2)
                                    )
                                
                                Image(systemName: ship.iconName)
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: ship.accentColorHex) ?? Color.cyan)
                            }
                            
                            // Info
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(ship.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Text("SEÇİLDİ")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(6)
                                    }
                                }
                                
                                Text(ship.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                            }
                        }
                        
                        // Stats Meters
                        HStack(spacing: 12) {
                            StatMeter(name: "HP", value: ship.baseHealth, maxVal: 200, color: .red)
                            StatMeter(name: "Qalxan", value: ship.baseShield, maxVal: 120, color: .cyan)
                            StatMeter(name: "Sürət", value: ship.baseSpeed, maxVal: 400, color: .yellow)
                            StatMeter(name: "Silah", value: ship.baseDamage, maxVal: 60, color: .purple)
                        }
                        
                        // Button Action
                        if ship.isUnlocked {
                            if !isSelected {
                                Button(action: {
                                    gameState.selectedShipId = ship.id
                                    HapticsManager.shared.playLight()
                                    AudioManager.shared.playCoinSound()
                                }) {
                                    Text("GƏMİNİ SEÇ")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.cyan)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        } else {
                            Button(action: {
                                _ = gameState.unlockShip(id: ship.id)
                            }) {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("KİLİDİ AÇ (\(ship.price) 💎)")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(gameState.cyberCrystals >= ship.price ? .black : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(gameState.cyberCrystals >= ship.price ? Color.yellow : Color.white.opacity(0.15))
                                .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(gameState.cyberCrystals < ship.price)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.1).opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSelected ? Color.green : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

fileprivate struct StatMeter: View {
    let name: String
    let value: CGFloat
    let maxVal: CGFloat
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Text(name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: max(4, min(65, (value / maxVal) * 65)), height: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Upgrades Tab
fileprivate struct UpgradesListTab: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ForEach(gameState.permanentUpgrades) { upgrade in
                    let isMax = upgrade.currentLevel >= upgrade.maxLevel
                    let canAfford = gameState.cyberCrystals >= upgrade.cost && !isMax
                    
                    HStack(spacing: 14) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                            Image(systemName: upgrade.icon)
                                .font(.system(size: 20))
                                .foregroundColor(gameState.selectedTheme.primaryColor)
                        }
                        
                        // Texts & Level
                        VStack(alignment: .leading, spacing: 3) {
                            Text(upgrade.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(upgrade.description)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)
                            
                            // Level Progress
                            HStack(spacing: 3) {
                                ForEach(0..<upgrade.maxLevel, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(i < upgrade.currentLevel ? gameState.selectedTheme.primaryColor : Color.white.opacity(0.15))
                                        .frame(width: 14, height: 4)
                                }
                            }
                            .padding(.top, 2)
                        }
                        
                        Spacer()
                        
                        // Upgrade Button
                        if isMax {
                            Text("MAX")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Button(action: {
                                _ = gameState.buyUpgrade(id: upgrade.id)
                            }) {
                                HStack(spacing: 4) {
                                    Text("\(upgrade.cost)")
                                        .font(.system(size: 13, weight: .black, design: .monospaced))
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(canAfford ? .black : .white.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(canAfford ? gameState.selectedTheme.primaryColor : Color.white.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(!canAfford)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(white: 0.1).opacity(0.85))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

fileprivate extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
