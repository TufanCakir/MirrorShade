//
//  DrawingEditorView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import PencilKit
import SwiftData
import SwiftUI

struct DrawingEditorView: View {
    @StateObject private var document: DrawingDocument

    @Environment(\.modelContext) private var modelContext

    @State private var project: DrawingProject?
    @State private var projectName = ""
    @Environment(\.locale) private var locale
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var didLoadProject = false

    private let initialProject: DrawingProject?

    @State private var selectedToolID = "pen"
    @State private var selectedColor: Color = .black
    @State private var lineWidth: Double = 4
    @State private var showCanvasSettings = false
    @State private var showClearConfirmation = false
    @AppStorage("showCanvasGrid") private var showCanvasGrid = false
    @AppStorage("showTransparencyGrid") private var showTransparencyGrid = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    // Only expose tools whose behavior is implemented.
    private let tools = DrawingTool.load().filter {
        [.pen, .pencil, .marker, .eraser, .fill, .lasso].contains($0.kind)
    }

    init(
        width: Int,
        height: Int,
        project: DrawingProject? = nil
    ) {
        self.initialProject = project

        _document = StateObject(
            wrappedValue: DrawingDocument(
                width: project?.width ?? width,
                height: project?.height ?? height
            )
        )
    }

    private var selectedTool: DrawingTool {
        tools.first { $0.id == selectedToolID }
            ?? DrawingTool(
                id: "pen",
                name: "Stift",
                symbol: "pencil",
                kind: .pen,
                width: 4
            )
    }

    var body: some View {
        canvasWorkspace
            .safeAreaInset(edge: .bottom, spacing: 0) {
                EditorToolBar(
                    tools: tools,
                    selectedToolID: $selectedToolID,
                    selectedColor: $selectedColor,
                    lineWidth: $lineWidth
                )
            }
            .sensoryFeedback(.selection, trigger: selectedToolID) { _, _ in
                hapticFeedback
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationTitle(projectName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                editorToolbar
            }
            .sheet(isPresented: $showCanvasSettings) {
                CanvasSettingsSheet(
                    projectName: $projectName,
                    showGrid: $showCanvasGrid,
                    showTransparency: $showTransparencyGrid,
                    backgroundColor: Binding(
                        get: {
                            Color(uiColor: document.backgroundColor ?? .white)
                        },
                        set: { document.setBackground(UIColor($0)) }
                    ),
                    transparent: Binding(
                        get: { document.backgroundColor == nil },
                        set: { document.setBackground($0 ? nil : .white) }
                    )
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Gesamte Zeichnung löschen?",
                isPresented: $showClearConfirmation
            ) {
                Button("Alles löschen", role: .destructive) {
                    document.clearCanvas()
                }

                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Du kannst diese Aktion anschließend rückgängig machen.")
            }

            .task {
                loadProjectIfNeeded()
            }
            .alert(
                "Speichern fehlgeschlagen",
                isPresented: $showSaveError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage)
            }
    }

    // MARK: - Canvas Workspace

    private var canvasWorkspace: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 24

            let availableWidth = max(
                1,
                geometry.size.width - padding * 2
            )

            let availableHeight = max(
                1,
                geometry.size.height - padding * 2 - 24
            )

            let scale = min(
                availableWidth / document.size.width,
                availableHeight / document.size.height
            )

            let displayWidth = document.size.width * scale
            let displayHeight = document.size.height * scale

            VStack(spacing: 8) {
                Spacer(minLength: 0)

                canvasContent(
                    width: displayWidth,
                    height: displayHeight,
                    scale: scale
                )

                Spacer(minLength: 0)

                Text(
                    "\(Int(document.size.width)) × \(Int(document.size.height)) px"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Canvas

    private func canvasContent(
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if showTransparencyGrid {
                checkerboard
            } else {
                Color.white
            }
            if let backgroundColor = document.backgroundColor {
                Color(uiColor: backgroundColor)
            }

            Image(uiImage: document.image)
                .resizable()
                .interpolation(.none)
                .frame(width: width, height: height)
                .allowsHitTesting(false)

            PencilCanvasView(
                document: document,
                tool: selectedTool,
                color: selectedColor,
                lineWidth: lineWidth
            )
            .frame(
                width: document.size.width,
                height: document.size.height
            )
            .scaleEffect(
                scale,
                anchor: .topLeading
            )
            .frame(
                width: width,
                height: height,
                alignment: .topLeading
            )
        }
        .frame(width: width, height: height)
        .overlay {
            if showCanvasGrid {
                CanvasGuideGrid()
                    .allowsHitTesting(false)
            }
        }
        .clipped()
        .overlay {
            Rectangle()
                .strokeBorder(
                    .secondary.opacity(0.3),
                    lineWidth: 1
                )
        }
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            y: 3
        )
    }

    // MARK: - Transparency Grid

    private var checkerboard: some View {
        Canvas { context, size in
            let tile: CGFloat = 12

            let rows = Int(ceil(size.height / tile))
            let columns = Int(ceil(size.width / tile))

            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * tile,
                        y: CGFloat(row) * tile,
                        width: tile,
                        height: tile
                    )

                    let color: Color =
                        (row + column).isMultiple(of: 2)
                        ? .white
                        : Color(white: 0.83)

                    context.fill(
                        Path(rect),
                        with: .color(color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Native Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                document.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!document.canUndo)
            .accessibilityLabel("Rückgängig")

            Button {
                document.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!document.canRedo)
            .accessibilityLabel("Wiederholen")

            Button {
                saveProject()
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("Projekt speichern")

            Menu {
                Button {
                    showCanvasSettings = true
                } label: {
                    Label(
                        "Leinwand & Projekt",
                        systemImage: "square.on.square"
                    )
                }

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label(
                        "Alles löschen",
                        systemImage: "trash"
                    )
                }

                ShareLink(
                    item: Image(
                        uiImage: document.flattenedImage()
                    ),
                    preview: SharePreview("Zeichnung")
                ) {
                    Label(
                        "Exportieren",
                        systemImage: "square.and.arrow.up"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Save Project

    private func saveProject() {
        guard let imageData = document.exportImageData() else {
            saveErrorMessage = String(localized: "Das Bild konnte nicht gespeichert werden.", locale: locale)
            showSaveError = true
            return
        }

        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedName = trimmedName.isEmpty
            ? String(localized: "Neue Zeichnung", locale: locale)
            : trimmedName
        let drawingData = document.exportDrawingData()
        let thumbnailData = document.exportThumbnailData()

        do {
            if let project {
                project.name = savedName
                project.backgroundColorData = document.backgroundColorData()
                project.imageData = imageData
                project.drawingData = drawingData
                project.thumbnailData = thumbnailData
                project.updatedAt = .now
            } else {
                let newProject = DrawingProject(
                    name: savedName,
                    width: Int(document.size.width),
                    height: Int(document.size.height),
                    imageData: imageData,
                    drawingData: drawingData,
                    thumbnailData: thumbnailData
                )

                newProject.backgroundColorData = document.backgroundColorData()
                modelContext.insert(newProject)
                project = newProject
            }

            try modelContext.save()
            projectName = savedName

        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    // MARK: - Load Project

    private func loadProjectIfNeeded() {
        guard !didLoadProject else { return }
        didLoadProject = true

        guard let initialProject else {
            projectName = String(localized: "Neue Zeichnung", locale: locale)
            return
        }

        project = initialProject
        projectName = initialProject.name

        document.restoreProject(initialProject)
    }

}

#Preview {
    NavigationStack {
        DrawingEditorView(
            width: 200,
            height: 300
        )
        .modelContainer(for: DrawingProject.self, inMemory: true)
    }
}
