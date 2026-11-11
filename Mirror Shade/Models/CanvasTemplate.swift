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

    // Literal resources let Xcode extract names while JSON IDs stay language-independent.
    var localizedName: LocalizedStringResource {
        switch id {
        case "app_icon": "App Icon"
        case "square": "Quadratisch"
        case "portrait": "Hochformat 9:16"
        case "landscape": "Querformat 16:9"
        case "poster": "Poster"
        case "anime_portrait": "Anime Porträt"
        case "fantasy_art": "Fantasy Illustration"
        case "wallpaper_phone": "Smartphone Wallpaper"
        case "sprite_16": "Sprite 16 px"
        case "sprite_32": "Sprite 32 px"
        case "game_sprite": "Sprite 64 px"
        case "sprite_128": "Sprite 128 px"
        case "tilemap_small": "Tilemap Klein"
        case "tilemap_medium": "Tilemap Mittel"
        case "tilemap_large": "Tilemap Groß"
        case "tileset_16": "Tileset 16 px"
        case "tileset_32": "Tileset 32 px"
        case "tileset_64": "Tileset 64 px"
        case "spritesheet_4": "Spritesheet 4 Frames"
        case "spritesheet_8": "Spritesheet 8 Frames"
        case "spritesheet_16": "Spritesheet 16 Frames"
        case "spritesheet_64": "Spritesheet 64 Frames"
        case "iphone_portrait": "iPhone Screenshot Hochformat"
        case "iphone_landscape": "iPhone Screenshot Querformat"
        case "ipad_portrait": "iPad Screenshot Hochformat"
        case "ipad_landscape": "iPad Screenshot Querformat"
        case "app_event": "In-App Event"
        case "instagram_square": "Social Square"
        case "instagram_portrait": "Social Portrait 4:5"
        case "story": "Story 9:16"
        case "youtube_thumbnail": "YouTube Thumbnail"
        case "banner": "Banner 16:9"
        default: LocalizedStringResource(String.LocalizationValue(name))
        }
    }

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
