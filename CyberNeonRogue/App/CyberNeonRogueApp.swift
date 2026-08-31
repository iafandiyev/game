import SwiftUI

@main
struct CyberNeonRogueApp: App {
    var body: some Scene {
        WindowGroup {
            ZombieMainMenuView()
                .preferredColorScheme(.dark)
        }
    }
}
