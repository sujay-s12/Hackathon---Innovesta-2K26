import SwiftUI
import UIKit
import PhotosUI

// ─────────────────────────────────────
// MARK: - Audio File Picker
// ─────────────────────────────────────
struct AudioPickerView: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .audio, .mp3, .mpeg4Audio
        ])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            onPick(url)
        }
    }
}

// ─────────────────────────────────────
// MARK: - Image Picker (multi-select)
// ─────────────────────────────────────
struct ImagePickerView: View {
    let onPick: ([URL]) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Text("Select Images")
        }
        .onChange(of: selectedItems) { _, items in
            Task {
                var urls: [URL] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let url = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString + ".jpg")
                        try? data.write(to: url)
                        urls.append(url)
                    }
                }
                onPick(urls)
                dismiss()
            }
        }
    }
}
