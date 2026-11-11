//
//  CanvasTemplateCategory.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import Foundation

enum CanvasTemplateCategory: String, Codable, CaseIterable, Identifiable {
    case standard = "Standard"
    case appDesign = "App Design"
    case appStore = "App Store"
    case gameArt = "Game Art"
    case animation = "Animation"
    case illustration = "Illustration"
    case socialMedia = "Social Media"

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .standard: "Standard"
        case .appDesign: "App Design"
        case .appStore: "App Store"
        case .gameArt: "Game Art"
        case .animation: "Animation"
        case .illustration: "Illustration"
        case .socialMedia: "Social Media"
        }
    }

    var symbol: String {
        switch self {
        case .standard:
            "aspectratio"

        case .appDesign:
            "app"

        case .appStore:
            "apps.iphone"

        case .gameArt:
            "square.grid.3x3"

        case .animation:
            "film.stack"

        case .illustration:
            "paintbrush.pointed"

        case .socialMedia:
            "photo"
        }
    }

    var sortOrder: Int {
        switch self {
        case .standard: 0
        case .appDesign: 1
        case .gameArt: 2
        case .animation: 3
        case .illustration: 4
        case .appStore: 5
        case .socialMedia: 6
        }
    }
}
