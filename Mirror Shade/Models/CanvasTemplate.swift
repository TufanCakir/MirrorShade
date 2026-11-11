//
//  CanvasTemplate.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import Foundation

struct CanvasTemplate: Identifiable, Codable, Hashable {

    let id: String
    let name: String
    let category: CanvasTemplateCategory
    let width: Int
    let height: Int

    // MARK: - Dimensions

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    var pixelCount: Int {
        width * height
    }

    var dimensionText: String {
        "\(width) × \(height) px"
    }

    var isPortrait: Bool {
        height > width
    }

    var isLandscape: Bool {
        width > height
    }

    var isSquare: Bool {
        width == height
    }

    // MARK: - Validation

    var isValid: Bool {
        width > 0 && height > 0 && width <= 4096 && height <= 4096
            && pixelCount <= 8_388_608
    }

    // MARK: - Loading

    static func load() -> [CanvasTemplate] {
        guard
            let url = Bundle.main.url(
                forResource: "canvas_templates",
                withExtension: "json"
            )
        else {
            return fallbackTemplates
        }

        do {
            let data = try Data(contentsOf: url)

            let templates = try JSONDecoder().decode(
                [CanvasTemplate].self,
                from: data
            )

            return templates.sorted {
                if $0.category.sortOrder != $1.category.sortOrder {
                    return $0.category.sortOrder < $1.category.sortOrder
                }

                return $0.name.localizedStandardCompare($1.name)
                    == .orderedAscending
            }

        } catch {
            #if DEBUG
                print("CanvasTemplate loading failed: \(error)")
            #endif

            return fallbackTemplates
        }
    }

    // MARK: - Fallback

    private static let fallbackTemplates: [CanvasTemplate] = [
        CanvasTemplate(
            id: "app_icon",
            name: "App Icon",
            category: .appDesign,
            width: 1024,
            height: 1024
        ),
        CanvasTemplate(
            id: "square",
            name: "Quadratisch",
            category: .standard,
            width: 2048,
            height: 2048
        ),
        CanvasTemplate(
            id: "game_sprite",
            name: "Sprite 64 px",
            category: .gameArt,
            width: 64,
            height: 64
        ),
    ]
}
