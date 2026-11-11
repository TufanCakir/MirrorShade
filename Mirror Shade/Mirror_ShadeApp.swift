//
//  Mirror_ShadeApp.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftData
import SwiftUI

@main
struct Mirror_ShadeApp: App {

    @AppStorage("appearance")
    private var appearance = AppAppearance.system.rawValue

    @AppStorage("language")
    private var language = AppLanguage.system.rawValue

    private var selectedAppearance: AppAppearance {
        AppAppearance(rawValue: appearance) ?? .system
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: language) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(
                    selectedAppearance.colorScheme
                )
                .environment(
                    \.locale,
                    selectedLanguage.locale ?? .autoupdatingCurrent
                )
        }
        .modelContainer(for: DrawingProject.self)
    }
}
