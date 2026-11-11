//
//  SettingsView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Preferences

    @AppStorage("appearance")
    private var appearance = AppAppearance.system.rawValue

    @AppStorage("language")
    private var language = AppLanguage.system.rawValue

    @AppStorage("showCanvasGrid")
    private var showCanvasGrid = false

    @AppStorage("showTransparencyGrid")
    private var showTransparencyGrid = true

    @AppStorage("hapticFeedback")
    private var hapticFeedback = true

    // MARK: - Disclosure States

    @State private var showFeatures = false
    @State private var showFormats = false
    @State private var showTechnicalInfo = false

    // MARK: - Bundle Information

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "–"
    }

    private var buildNumber: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "–"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "–"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                canvasSection
                appInformationSection
                technicalSection
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Darstellung") {
            Picker(
                "Erscheinungsbild",
                selection: $appearance
            ) {
                ForEach(AppAppearance.allCases) { option in
                    Label(
                        option.title,
                        systemImage: option.symbol
                    )
                    .tag(option.rawValue)
                }
            }

            Picker(
                "Sprache",
                selection: $language
            ) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.title)
                        .tag(option.rawValue)
                }
            }
        }
    }

    // MARK: - Canvas Preferences

    private var canvasSection: some View {
        Section {
            Toggle(
                "Leinwandraster",
                systemImage: "square.grid.3x3",
                isOn: $showCanvasGrid
            )

            Toggle(
                "Transparenzraster",
                systemImage: "checkerboard.rectangle",
                isOn: $showTransparencyGrid
            )

            Toggle(
                "Haptisches Feedback",
                systemImage: "hand.tap",
                isOn: $hapticFeedback
            )
        } header: {
            Text("Zeichnen")
        } footer: {
            Text(
                "Passe die Darstellung deiner Leinwand und die Bedienung an."
            )
        }
    }

    // MARK: - App Information

    private var appInformationSection: some View {
        Section("Über Mirror Shade") {

            LabeledContent {
                Text("Mirror Shade")
            } label: {
                Label(
                    "App",
                    systemImage: "app"
                )
            }

            DisclosureGroup(
                isExpanded: $showFeatures
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    featureRow(
                        "Zeichnen",
                        symbol: "pencil.tip",
                        description:
                            "Erstelle eigene Zeichnungen mit Stiften, Markern und Radierwerkzeugen."
                    )

                    featureRow(
                        "Game Art",
                        symbol: "square.grid.3x3",
                        description:
                            "Nutze Leinwandvorlagen für Sprites, Tilesets und Tilemaps."
                    )

                    featureRow(
                        "Animation",
                        symbol: "film.stack",
                        description:
                            "Bereite Zeichnungen mit passenden Spritesheet-Größen vor."
                    )

                    featureRow(
                        "Farben",
                        symbol: "paintpalette",
                        description:
                            "Wähle Zeichenfarben und passe die Strichstärke an."
                    )

                    featureRow(
                        "Projekte",
                        symbol: "square.stack",
                        description:
                            "Speichere deine Zeichnungen lokal und bearbeite sie später weiter."
                    )

                    featureRow(
                        "Export",
                        symbol: "square.and.arrow.up",
                        description:
                            "Teile deine fertigen Zeichnungen als Bild."
                    )
                }
                .padding(.vertical, 8)
            } label: {
                Label(
                    "Was kann Mirror Shade?",
                    systemImage: "sparkles"
                )
            }

            DisclosureGroup(
                isExpanded: $showFormats
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    formatRow(
                        "App Design",
                        description: "App-Icons und Screenshots"
                    )

                    formatRow(
                        "Game Art",
                        description: "Sprites, Tilemaps und Tilesets"
                    )

                    formatRow(
                        "Illustration",
                        description: "Porträts, Poster und Fantasy-Art"
                    )

                    formatRow(
                        "Animation",
                        description: "Spritesheet-Leinwandvorlagen"
                    )

                    formatRow(
                        "Social Media",
                        description: "Stories, Banner und Thumbnails"
                    )
                }
                .padding(.vertical, 8)
            } label: {
                Label(
                    "Leinwandvorlagen",
                    systemImage: "rectangle.on.rectangle"
                )
            }
        }
    }

    // MARK: - Technical Information

    private var technicalSection: some View {
        Section("App-Informationen") {
            LabeledContent(
                "Version",
                value: appVersion
            )

            LabeledContent(
                "Build",
                value: buildNumber
            )

            DisclosureGroup(
                isExpanded: $showTechnicalInfo
            ) {
                LabeledContent(
                    "Bundle Identifier",
                    value: bundleIdentifier
                )

                LabeledContent(
                    "Oberfläche",
                    value: "SwiftUI"
                )

                LabeledContent(
                    "Zeichnen",
                    value: "PencilKit"
                )

                LabeledContent(
                    "Datenspeicherung",
                    value: "SwiftData"
                )
            } label: {
                Label(
                    "Technische Details",
                    systemImage: "info.circle"
                )
            }
        }
    }

    // MARK: - Components

    private func featureRow(
        _ title: String,
        symbol: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatRow(
        _ title: String,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.medium))

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Appearance Enum

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }

    var symbol: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Language Enum

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .german: "Deutsch"
        case .english: "English"
        }
    }

    var locale: Locale? {
        switch self {
        case .system: nil
        case .german: Locale(identifier: "de")
        case .english: Locale(identifier: "en")
        }
    }
}

#Preview {
    SettingsView()
}
