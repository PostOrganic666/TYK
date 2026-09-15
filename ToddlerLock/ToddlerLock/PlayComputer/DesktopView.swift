import SwiftUI

/// The pretend Mac: menu bar, wallpaper, desktop icons, dock, and fake
/// windows. (Filled in by the desktop shell work.)
struct DesktopView: View {
    @ObservedObject private var input = ComputerInput.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.2, green: 0.45, blue: 0.85), Color(red: 0.55, green: 0.3, blue: 0.7)],
                           startPoint: .top, endPoint: .bottom)
            Text("Play Computer")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}
