import SwiftUI

/// Creative and world apps: Paint, Music, Stickers, Weather, Clock, Maps,
/// Photos, Messages, FaceTime. Ported from the iOS toy apps, adapted for
/// mouse and keyboard. Views live in ToyAppViews.swift, ToyAppWorld.swift,
/// ToyAppMessages.swift, and ToyAppFaceTime.swift.
enum ToyApps {
    static let all: [ComputerApp] = [
        ComputerApp(id: "paint", name: "Paint", symbol: "paintbrush.fill",
                    colors: [.pink, .purple],
                    defaultSize: CGSize(width: 900, height: 620)) {
            PaintToyApp()
        },
        ComputerApp(id: "music", name: "Music", symbol: "music.note",
                    colors: [.red, .pink],
                    defaultSize: CGSize(width: 820, height: 520)) {
            MusicToyApp()
        },
        ComputerApp(id: "stickers", name: "Stickers", symbol: "star.fill",
                    colors: [.yellow, .orange],
                    defaultSize: CGSize(width: 820, height: 600)) {
            StickersToyApp()
        },
        ComputerApp(id: "weather", name: "Weather", symbol: "cloud.sun.fill",
                    colors: [.cyan, .blue],
                    defaultSize: CGSize(width: 760, height: 600)) {
            WeatherToyApp()
        },
        ComputerApp(id: "clock", name: "Clock", symbol: "clock.fill",
                    colors: [Color(white: 0.2), Color(white: 0.05)],
                    defaultSize: CGSize(width: 700, height: 640)) {
            ClockToyApp()
        },
        ComputerApp(id: "maps", name: "Maps", symbol: "map.fill",
                    colors: [.green, .teal],
                    defaultSize: CGSize(width: 900, height: 620)) {
            MapsToyApp()
        },
        ComputerApp(id: "photos", name: "Photos", symbol: "photo.on.rectangle",
                    colors: [.white.opacity(0.9), .orange],
                    defaultSize: CGSize(width: 820, height: 620)) {
            PhotosToyApp()
        },
        ComputerApp(id: "messages", name: "Messages", symbol: "message.fill",
                    colors: [.green, .teal],
                    defaultSize: CGSize(width: 900, height: 620)) {
            MessagesToyApp()
        },
        ComputerApp(id: "facetime", name: "FaceTime", symbol: "video.fill",
                    colors: [.green, .mint],
                    defaultSize: CGSize(width: 820, height: 600)) {
            FaceTimeToyApp()
        },
    ]
}
