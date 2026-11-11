//
//  DrawingDocument.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import Combine
import PencilKit
import SwiftUI

@MainActor
final class DrawingDocument: ObservableObject {
    struct Snapshot {
        let image: UIImage
        let drawing: PKDrawing
    }

    @Published var image: UIImage
    @Published var drawing = PKDrawing()

    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    let size: CGSize

    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private let historyLimit = 20

    init(width: Int, height: Int) {
        size = CGSize(width: width, height: height)
        image = Self.blank(size: size)
    }

    func clearCanvas() {
        checkpoint()

        image = Self.blank(size: size)
        drawing = PKDrawing()
    }

    // MARK: - Persistence

    func restoreProject(_ project: DrawingProject) {
        if let restoredImage = UIImage(data: project.imageData) {
            image = restoredImage
        }

        if let restoredDrawing = try? PKDrawing(
            data: project.drawingData
        ) {
            drawing = restoredDrawing
        }

        undoStack.removeAll()
        redoStack.removeAll()
        updateHistory()
    }

    func exportImageData() -> Data? {
        image.pngData()
    }

    func exportDrawingData() -> Data {
        drawing.dataRepresentation()
    }

    func exportThumbnailData() -> Data? {
        let preview = flattenedImage()

        let maxSide: CGFloat = 320

        let scale = min(
            1,
            maxSide / max(size.width, size.height)
        )

        let thumbnailSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let thumbnail = UIGraphicsImageRenderer(
            size: thumbnailSize,
            format: format
        ).image { _ in
            preview.draw(
                in: CGRect(
                    origin: .zero,
                    size: thumbnailSize
                )
            )
        }

        return thumbnail.pngData()
    }

    private static func blank(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(
            size: size,
            format: format
        ).image { _ in }
    }

    private func snapshot() -> Snapshot {
        Snapshot(image: image, drawing: drawing)
    }

    func checkpoint() {
        undoStack.append(snapshot())

        if undoStack.count > historyLimit {
            undoStack.removeFirst()
        }

        redoStack.removeAll()
        updateHistory()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }

        redoStack.append(snapshot())
        restore(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }

        undoStack.append(snapshot())
        restore(next)
    }

    private func restore(_ snapshot: Snapshot) {
        image = snapshot.image
        drawing = snapshot.drawing
        updateHistory()
    }

    private func updateHistory() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    func flattenedImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let bounds = CGRect(origin: .zero, size: size)

        return UIGraphicsImageRenderer(
            size: size,
            format: format
        ).image { _ in
            image.draw(in: bounds)

            let strokes = drawing.image(
                from: bounds,
                scale: 1
            )
            strokes.draw(in: bounds)
        }
    }

    func fill(at point: CGPoint, color: UIColor) {
        let merged = flattenedImage()

        guard
            let filled = FloodFill.apply(
                to: merged,
                at: point,
                color: color
            )
        else { return }

        checkpoint()
        image = filled
        drawing = PKDrawing()
    }

    func setBackground(_ color: UIColor?) {
        checkpoint()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let bounds = CGRect(origin: .zero, size: size)

        image = UIGraphicsImageRenderer(
            size: size,
            format: format
        ).image { context in
            if let color {
                color.setFill()
                context.fill(bounds)
            }

            image.draw(in: bounds)
        }
    }
}
