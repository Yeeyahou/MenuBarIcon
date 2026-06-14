//
//  MenuBarIconApp.swift
//  MenuBarIcon
//
//  Created by jungwon on 6/11/26.
//

import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

@main
struct MenuBarIconApp: App {
    @StateObject private var iconStore = MenuBarIconStore()

    var body: some Scene {
        MenuBarExtra {
            Button("PNG 선택...") {
                iconStore.choosePNG()
            }

            if iconStore.hasCustomIcon {
                Button("기본 아이콘으로 되돌리기") {
                    iconStore.resetIcon()
                }
            }

            Divider()

            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            if let image = iconStore.menuBarImage {
                Image(nsImage: image)
            } else {
                Image(systemName: "star.fill")
            }
        }
    }
}

@MainActor
final class MenuBarIconStore: ObservableObject {
    @Published private(set) var menuBarImage: NSImage?
    @Published private(set) var hasCustomIcon = false

    private let storedIconURL: URL

    init() {
        let supportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("MenuBarIcon", isDirectory: true)

        storedIconURL = supportURL.appendingPathComponent("MenuBarIcon.png")
        loadStoredIcon()
    }

    func choosePNG() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: storedIconURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            if FileManager.default.fileExists(atPath: storedIconURL.path) {
                try FileManager.default.removeItem(at: storedIconURL)
            }

            try FileManager.default.copyItem(at: selectedURL, to: storedIconURL)
            loadStoredIcon()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func resetIcon() {
        do {
            if FileManager.default.fileExists(atPath: storedIconURL.path) {
                try FileManager.default.removeItem(at: storedIconURL)
            }
        } catch {
            NSAlert(error: error).runModal()
        }

        menuBarImage = nil
        hasCustomIcon = false
    }

    private func loadStoredIcon() {
        guard let image = NSImage(contentsOf: storedIconURL) else {
            menuBarImage = nil
            hasCustomIcon = false
            return
        }

        image.isTemplate = false
        image.size = scaledMenuBarSize(for: image.size)
        menuBarImage = image
        hasCustomIcon = true
    }

    private func scaledMenuBarSize(for size: NSSize) -> NSSize {
        guard size.width > 0, size.height > 0 else {
            return NSSize(width: 18, height: 18)
        }

        let maxLength: CGFloat = 18
        let scale = min(maxLength / size.width, maxLength / size.height)

        return NSSize(
            width: size.width * scale,
            height: size.height * scale
        )
    }
}
