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
