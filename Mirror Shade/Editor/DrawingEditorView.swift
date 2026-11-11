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
    @State private var projectName = "Neue Zeichnung"
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var didLoadProject = false

    private let initialProject: DrawingProject?

    @State private var selectedToolID = "pen"
    @State private var selectedColor: Color = .black
    @State private var lineWidth: Double = 4
    @State private var showBackgroundPicker = false

    @State private var controlsHeight: CGFloat = 240
    @State private var dragStartHeight: CGFloat?
    @State private var showClearConfirmation = false

    @State private var showDrawingTools = true
    @State private var showBrushTools = false
    @State private var showFantasyTools = false
    @State private var showGradientTools = false
    @State private var showOtherTools = false
    @State private var showColorControls = false

    private let minimumControlsHeight: CGFloat = 110
    private let minimumCanvasHeight: CGFloat = 130

    private let tools = DrawingTool.load()

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

    private func controlsHandle(
        availableHeight: CGFloat
    ) -> some View {
        let maximumHeight = max(
            0,
            availableHeight - minimumCanvasHeight - 46
        )

        let minimumHeight = min(
            minimumControlsHeight,
            maximumHeight
        )

        return VStack(spacing: 7) {
            Capsule()
                .fill(.secondary.opacity(0.5))
                .frame(width: 42, height: 5)

            HStack {
                Text("Werkzeuge")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "arrow.up.and.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 46)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.smooth(duration: 0.25)) {
                controlsHeight = controlsHeight > 150 ? 110 : 300
            }
        }
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    let start =
                        dragStartHeight
                        ?? controlsHeight

                    if dragStartHeight == nil {
                        dragStartHeight = controlsHeight
                    }

                    controlsHeight = min(
                        max(
                            start - value.translation.height,
                            minimumHeight
                        ),
                        maximumHeight
                    )
                }
                .onEnded { _ in
                    dragStartHeight = nil

                    withAnimation(.smooth(duration: 0.2)) {
                        controlsHeight = max(
                            minimumHeight,
                            min(controlsHeight, maximumHeight)
                        )
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Werkzeugbereich")
        .accessibilityValue(
            "\(Int(controlsHeight)) Punkte"
        )
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                controlsHeight = min(
                    controlsHeight + 50,
                    maximumHeight
                )

            case .decrement:
                controlsHeight = max(
                    controlsHeight - 50,
                    minimumHeight
                )

            @unknown default:
                break
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height

            let maximumControlsHeight = max(
                0,
                totalHeight - minimumCanvasHeight - 46
            )

            let minimumHeight = min(
                minimumControlsHeight,
                maximumControlsHeight
            )

            let effectiveControlsHeight = min(
                max(controlsHeight, minimumHeight),
                maximumControlsHeight
            )

            VStack(spacing: 0) {
                canvasWorkspace
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .clipped()

                controlsHandle(
                    availableHeight: totalHeight
                )

                editorControls
                    .frame(height: effectiveControlsHeight)
                    .clipped()
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            editorToolbar
        }
        .sheet(isPresented: $showBackgroundPicker) {
            backgroundSettings
                .presentationDetents([.medium])
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
            checkerboard

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

            Button {
                document.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!document.canRedo)

            Button {
                saveProject()
            } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("Projekt speichern")

            Menu {
                Button {
                    showBackgroundPicker = true
                } label: {
                    Label(
                        "Hintergrund",
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

    // MARK: - Native Form Controls

    private var editorControls: some View {
        Form {
            DisclosureGroup(
                "Zeichnen",
                isExpanded: $showDrawingTools
            ) {
                toolGrid([
                    .pen, .pencil, .marker, .eraser,
                    .fill, .smoothPen, .animePen,
                    .curve, .calligraphy,
                ])
            }

            DisclosureGroup(
                "Pinsel",
                isExpanded: $showBrushTools
            ) {
                toolGrid([
                    .airbrush, .watercolor,
                    .oilBrush, .pixelPen,
                ])
            }

            DisclosureGroup(
                "Fantasy & Effekte",
                isExpanded: $showFantasyTools
            ) {
                toolGrid([
                    .glow, .stars, .lightning,
                ])
            }

            DisclosureGroup(
                "Farbverläufe",
                isExpanded: $showGradientTools
            ) {
                toolGrid([
                    .gradientLinear,
                    .gradientRadial,
                    .gradientAngular,
                    .gradientFill,
                ])
            }

            DisclosureGroup(
                "Sonstiges",
                isExpanded: $showOtherTools
            ) {
                toolGrid([
                    .lasso, .eyedropper, .clear,
                ])
            }

            DisclosureGroup(
                "Farbe & Strichstärke",
                isExpanded: $showColorControls
            ) {
                ColorPicker(
                    "Zeichenfarbe",
                    selection: $selectedColor
                )

                HStack(spacing: 12) {
                    Image(systemName: "line.diagonal")

                    Slider(
                        value: $lineWidth,
                        in: 1...60,
                        step: 1
                    )

                    Text("\(Int(lineWidth))")
                        .font(.caption.monospacedDigit())
                        .frame(width: 28)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(
            Color(uiColor: .systemGroupedBackground)
        )
    }

    private func toolGrid(
        _ kinds: [DrawingToolKind]
    ) -> some View {
        let filteredTools = tools.filter {
            kinds.contains($0.kind)
        }

        return LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(minimum: 48, maximum: 70),
                    spacing: 6
                )
            ],
            spacing: 8
        ) {
            ForEach(filteredTools) { tool in
                compactToolButton(tool)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Tool Button

    private func compactToolButton(
        _ tool: DrawingTool
    ) -> some View {
        let isSelected = selectedToolID == tool.id

        return Button {
            if tool.kind == .clear {
                showClearConfirmation = true
            } else {
                selectedToolID = tool.id
                lineWidth = Double(tool.width)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 18))
                    .frame(height: 24)

                Text(tool.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(
                isSelected
                    ? Color.accentColor
                    : Color.primary
            )
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.12)
                            : Color(uiColor: .tertiarySystemGroupedBackground)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor.opacity(0.5)
                            : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.name)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Background Settings

    private var backgroundSettings: some View {
        NavigationStack {
            Form {
                Section("Hintergrundfarbe") {
                    Button("Weiß") {
                        applyBackground(.white)
                    }

                    Button("Schwarz") {
                        applyBackground(.black)
                    }

                    Button("Aktuelle Farbe") {
                        applyBackground(
                            UIColor(selectedColor)
                        )
                    }
                }
            }
            .navigationTitle("Hintergrund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        showBackgroundPicker = false
                    }
                }
            }
        }
    }

    private func applyBackground(_ color: UIColor) {
        document.setBackground(color)
        showBackgroundPicker = false
    }

    // MARK: - Save Project

    private func saveProject() {
        guard let imageData = document.exportImageData() else {
            saveErrorMessage = "Das Bild konnte nicht gespeichert werden."
            showSaveError = true
            return
        }

        let drawingData = document.exportDrawingData()
        let thumbnailData = document.exportThumbnailData()

        do {
            if let project {
                project.name = projectName
                project.imageData = imageData
                project.drawingData = drawingData
                project.thumbnailData = thumbnailData
                project.updatedAt = .now
            } else {
                let newProject = DrawingProject(
                    name: projectName,
                    width: Int(document.size.width),
                    height: Int(document.size.height),
                    imageData: imageData,
                    drawingData: drawingData,
                    thumbnailData: thumbnailData
                )

                modelContext.insert(newProject)
                project = newProject
            }

            try modelContext.save()

        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    // MARK: - Load Project

    private func loadProjectIfNeeded() {
        guard !didLoadProject else { return }
        didLoadProject = true

        guard let initialProject else { return }

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
    }
}
