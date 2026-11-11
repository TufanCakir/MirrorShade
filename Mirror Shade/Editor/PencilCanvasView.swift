//
//  PencilCanvasView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import PencilKit
import SwiftUI

struct PencilCanvasView: UIViewRepresentable {
    @ObservedObject var document: DrawingDocument

    let tool: DrawingTool
    let color: Color
    let lineWidth: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()

        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator

        canvas.isScrollEnabled = false
        canvas.contentInset = .zero

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.cancelsTouchesInView = false
        canvas.addGestureRecognizer(tap)

        context.coordinator.tap = tap

        return canvas
    }

    func updateUIView(
        _ canvas: PKCanvasView,
        context: Context
    ) {
        context.coordinator.parent = self

        if canvas.drawing != document.drawing {
            context.coordinator.isUpdating = true
            canvas.drawing = document.drawing
            context.coordinator.isUpdating = false
        }

        let uiColor = UIColor(color)

        switch tool.kind {

        // MARK: - Native PencilKit Tools

        case .pen:
            canvas.tool = PKInkingTool(
                .pen,
                color: uiColor,
                width: lineWidth
            )

        case .pencil:
            canvas.tool = PKInkingTool(
                .pencil,
                color: uiColor,
                width: lineWidth
            )

        case .marker:
            canvas.tool = PKInkingTool(
                .marker,
                color: uiColor,
                width: lineWidth
            )

        case .eraser:
            canvas.tool = PKEraserTool(.bitmap)

        case .lasso:
            canvas.tool = PKLassoTool()

        // MARK: - Line Tools (Temporary PencilKit Fallback)

        case .smoothPen, .animePen, .curve, .calligraphy:
            canvas.tool = PKInkingTool(
                .pen,
                color: uiColor,
                width: lineWidth
            )

        // MARK: - Brush Tools (Temporary Fallback)

        case .airbrush, .watercolor, .oilBrush:
            canvas.tool = PKInkingTool(
                .marker,
                color: uiColor,
                width: lineWidth
            )

        case .pixelPen:
            canvas.tool = PKInkingTool(
                .pen,
                color: uiColor,
                width: lineWidth
            )

        // MARK: - Fantasy Tools (Temporary Fallback)

        case .glow, .stars, .lightning:
            canvas.tool = PKInkingTool(
                .marker,
                color: uiColor,
                width: lineWidth
            )

        // MARK: - Fill and Gradient Tools

        case .fill,
            .gradientFill,
            .gradientLinear,
            .gradientRadial,
            .gradientAngular:
            break

        // MARK: - Utility Tools

        case .eyedropper, .clear:
            break
        }

        let isTapTool: Bool

        switch tool.kind {
        case .fill:
            isTapTool = true

        default:
            isTapTool = false
        }

        let isDrawingTool: Bool

        switch tool.kind {
        case .fill,
            .gradientFill,
            .gradientLinear,
            .gradientRadial,
            .gradientAngular,
            .eyedropper,
            .clear:
            isDrawingTool = false

        default:
            isDrawingTool = true
        }

        canvas.drawingGestureRecognizer.isEnabled = isDrawingTool
        context.coordinator.tap?.isEnabled = isTapTool
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasView
        var isUpdating = false
        weak var tap: UITapGestureRecognizer?

        init(_ parent: PencilCanvasView) {
            self.parent = parent
        }

        func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
            guard !isUpdating else { return }
            parent.document.checkpoint()
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdating else { return }
            parent.document.drawing = canvasView.drawing
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard
                gesture.state == .ended,
                let canvas = gesture.view
            else { return }

            let point = gesture.location(in: canvas)

            parent.document.fill(
                at: point,
                color: UIColor(parent.color)
            )
        }
    }
}
