import SwiftUI

/// Game and gag apps: Games, Pets, Space, Garden, Mail, Treats,
/// Calculator, Taxes, Laundry.
enum MoreToyApps {
    static let all: [ComputerApp] = [
        ComputerApp(id: "games", name: "Games", symbol: "gamecontroller.fill",
                    colors: [Color(red: 0.35, green: 0.78, blue: 0.4), Color(red: 0.15, green: 0.5, blue: 0.22)],
                    defaultSize: CGSize(width: 720, height: 620)) {
            GamesMiniApp()
        },
        ComputerApp(id: "pets", name: "Pets", symbol: "pawprint.fill",
                    colors: [Color(red: 0.95, green: 0.65, blue: 0.25), Color(red: 0.75, green: 0.4, blue: 0.12)],
                    defaultSize: CGSize(width: 640, height: 600)) {
            PetsMiniApp()
        },
        ComputerApp(id: "space", name: "Space", symbol: "moon.stars.fill",
                    colors: [Color(red: 0.25, green: 0.22, blue: 0.55), Color(red: 0.08, green: 0.07, blue: 0.25)],
                    defaultSize: CGSize(width: 700, height: 600)) {
            SpaceMiniApp()
        },
        ComputerApp(id: "garden", name: "Garden", symbol: "leaf.fill",
                    colors: [Color(red: 0.55, green: 0.82, blue: 0.3), Color(red: 0.25, green: 0.55, blue: 0.2)],
                    defaultSize: CGSize(width: 760, height: 580)) {
            GardenMiniApp()
        },
        ComputerApp(id: "mail", name: "Mail", symbol: "envelope.fill",
                    colors: [Color(red: 0.35, green: 0.65, blue: 0.98), Color(red: 0.1, green: 0.35, blue: 0.85)],
                    defaultSize: CGSize(width: 820, height: 560),
                    badge: "999+") {
            MailMiniApp()
        },
        ComputerApp(id: "treats", name: "Treats", symbol: "birthday.cake.fill",
                    colors: [Color(red: 0.98, green: 0.55, blue: 0.7), Color(red: 0.62, green: 0.3, blue: 0.75)],
                    defaultSize: CGSize(width: 700, height: 600)) {
            TreatsMiniApp()
        },
        ComputerApp(id: "calculator", name: "Calculator", symbol: "plus.forwardslash.minus",
                    colors: [Color(red: 0.25, green: 0.25, blue: 0.27), Color(red: 0.05, green: 0.05, blue: 0.07)],
                    defaultSize: CGSize(width: 380, height: 560)) {
            CalculatorMiniApp()
        },
        ComputerApp(id: "taxes", name: "Taxes", symbol: "briefcase.fill",
                    colors: [Color(red: 0.3, green: 0.38, blue: 0.5), Color(red: 0.12, green: 0.16, blue: 0.24)],
                    defaultSize: CGSize(width: 480, height: 620),
                    badge: "!") {
            TaxesMiniApp()
        },
        ComputerApp(id: "laundry", name: "Laundry", symbol: "basket.fill",
                    colors: [Color(red: 0.35, green: 0.8, blue: 0.85), Color(red: 0.15, green: 0.45, blue: 0.7)],
                    defaultSize: CGSize(width: 640, height: 560),
                    badge: "∞") {
            LaundryMiniApp()
        },
    ]
}
