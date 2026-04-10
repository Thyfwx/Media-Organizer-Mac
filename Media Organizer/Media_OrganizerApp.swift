//
//  Media_OrganizerApp.swift
//  Media Organizer
//
//  Created by Xavier Scott on 4/10/26.
//

import SwiftUI

@main
struct Media_OrganizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .edgesIgnoringSafeArea(.top)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        Settings {
            MediaOrganizerSettingsView()
        }
        // NEW: Native macOS "About" Screen Menu!
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Media Organizer") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "Media Organizer",
                            NSApplication.AboutPanelOptionKey.version: "Alpha 1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "Created by Xavier Scott\n\nOrganize your messy media and documents using intelligent, on-device Artificial Intelligence.",
                                attributes: [ .font: NSFont.systemFont(ofSize: 12) ]
                            )
                        ]
                    )
                }
            }
        }
    }
}
