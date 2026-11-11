//
//  DrawingProject.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import Foundation
import SwiftData

@Model
final class DrawingProject {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var width: Int
    var height: Int

    var createdAt: Date
    var updatedAt: Date

    @Attribute(.externalStorage)
    var imageData: Data

    @Attribute(.externalStorage)
    var drawingData: Data

    @Attribute(.externalStorage)
    var thumbnailData: Data?

    // Optional for compatibility with projects saved before backgrounds were separate.
    var backgroundColorData: Data? = nil

    init(
        name: String,
        width: Int,
        height: Int,
        imageData: Data,
        drawingData: Data,
        thumbnailData: Data? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.width = width
        self.height = height
        self.createdAt = .now
        self.updatedAt = .now
        self.imageData = imageData
        self.drawingData = drawingData
        self.thumbnailData = thumbnailData
    }

    var dimensionText: String {
        "\(width) × \(height) px"
    }
}
