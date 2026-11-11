//
//  DrawingTool.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import Foundation

enum DrawingToolKind: String, Codable {
    // PencilKit
    case pen
    case pencil
    case marker
    case eraser
    case lasso

    // Fill
    case fill
    case gradientFill

    // Lines
    case smoothPen
    case animePen
    case curve
    case calligraphy

    // Brushes
    case airbrush
    case watercolor
    case oilBrush
    case pixelPen

    // Fantasy
    case glow
    case stars
    case lightning

    // Gradients
    case gradientLinear
    case gradientRadial
    case gradientAngular

    // Utilities
    case eyedropper
    case clear
}

struct DrawingTool: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let kind: DrawingToolKind
    let width: CGFloat

    // Literal resources let Xcode extract names while JSON IDs stay language-independent.
    var localizedName: LocalizedStringResource {
        switch id {
        case "pen": "Stift"
        case "pencil": "Bleistift"
        case "marker": "Marker"
        case "eraser": "Radierer"
        case "fill": "Farbeimer"
        case "smooth_pen": "Smooth Pen"
        case "anime_pen": "Anime G-Pen"
        case "curve": "Kurven"
        case "calligraphy": "Kalligrafie"
        case "airbrush": "Airbrush"
        case "watercolor": "Aquarell"
        case "oil_brush": "Ölpinsel"
        case "pixel_pen": "Pixel Pen"
        case "glow": "Glow"
        case "stars": "Sterne"
        case "lightning": "Blitze"
        case "gradient_linear": "Linearer Verlauf"
        case "gradient_radial": "Radialer Verlauf"
        case "gradient_angular": "Winkelverlauf"
        case "gradient_fill": "Verlauf-Farbeimer"
        case "lasso": "Lasso"
        case "eyedropper": "Pipette"
        case "clear": "Alles löschen"
        default: LocalizedStringResource(String.LocalizationValue(name))
        }
    }

    static func load() -> [DrawingTool] {
        guard
            let url = Bundle.main.url(
                forResource: "drawing_tools",
                withExtension: "json"
            ),
            let data = try? Data(contentsOf: url),
            let tools = try? JSONDecoder().decode(
                [DrawingTool].self,
                from: data
            )
        else {
            return []
        }

        return tools
    }
}
