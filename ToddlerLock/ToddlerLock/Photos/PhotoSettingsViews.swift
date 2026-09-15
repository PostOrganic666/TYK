import SwiftUI

// Settings components for the Photos section. The Settings screen embeds
// these; the photos workstream implements them. Signatures are fixed.

/// Multi-select album list used for both Chosen Albums (include) and All
/// Except Albums (exclude). Reads albums from PhotoLibraryService.listAlbums()
/// after requesting authorization. Binds to the SettingsStore id list.
struct AlbumMultiSelectView: View {
    let title: String
    let explanation: String
    @Binding var selection: [String]

    var body: some View {
        Text(title)
    }
}

/// A button that opens the system photo picker (PHPickerViewController on
/// macOS 13) so the parent can hand-pick photos. Writes the picked asset
/// identifiers to the binding. The label shows how many are chosen.
struct PhotoPickerButton: View {
    @Binding var selectedIDs: [String]

    var body: some View {
        Text("Choose Photos… (\(selectedIDs.count) chosen)")
    }
}
