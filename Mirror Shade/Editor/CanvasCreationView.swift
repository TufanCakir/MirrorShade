//
//  CanvasCreationView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftUI

struct CanvasCreationView: View {

    @State private var templates = CanvasTemplate.load()

    @State private var width = 1024
    @State private var height = 1024
    @State private var selectedTemplateID = "app_icon"

    @State private var editorSize: CGSize?
    @State private var openEditor = false

    @FocusState private var focusedField: SizeField?

    private enum SizeField: Hashable {
        case width
        case height
    }

    private let maximumDimension = 4096
    private let maximumPixels = 8_388_608

    private var validSize: Bool {
        (1...maximumDimension).contains(width)
            && (1...maximumDimension).contains(height)
            && width * height <= maximumPixels
    }

    private var selectedTemplate: CanvasTemplate? {
        templates.first { $0.id == selectedTemplateID }
    }

    private var aspectRatio: CGFloat {
        guard width > 0, height > 0 else { return 1 }
        return CGFloat(width) / CGFloat(height)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vorschau") {
                    canvasPreview
                }

                Section {
                    CanvasTemplatePicker(
                        templates: templates,
                        selectedID: $selectedTemplateID,
                        onSelect: selectTemplate
                    )
                } header: {
                    Text("Vorlagen")
                } footer: {
                    Text(
                        "Wähle eine Vorlage oder verwende eine eigene Leinwandgröße."
                    )
                }

                Section("Eigene Größe") {
                    sizeControls
                }

                if !validSize {
                    Section {
                        Label(
                            "Maximal 4096 px pro Seite und 8.388.608 Pixel insgesamt.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Neue Zeichnung")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                createButton
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Fertig") {
                        focusedField = nil
                    }
                }
            }
            .navigationDestination(isPresented: $openEditor) {
                if let editorSize {
                    DrawingEditorView(
                        width: Int(editorSize.width),
                        height: Int(editorSize.height)
                    )
                }
            }
            .onChange(of: width) { _, _ in
                updateSelection()
            }
            .onChange(of: height) { _, _ in
                updateSelection()
            }
        }
    }

    // MARK: - Preview

    private var canvasPreview: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let safeWidth = max(CGFloat(width), 1)
                let safeHeight = max(CGFloat(height), 1)

                let availableWidth = max(
                    geometry.size.width - 32,
                    1
                )

                let availableHeight = max(
                    geometry.size.height - 16,
                    1
                )

                let scale = min(
                    availableWidth / safeWidth,
                    availableHeight / safeHeight
                )

                let previewWidth = safeWidth * scale
                let previewHeight = safeHeight * scale

                Rectangle()
                    .fill(.white)
                    .frame(
                        width: previewWidth,
                        height: previewHeight
                    )
                    .overlay {
                        Rectangle()
                            .strokeBorder(
                                .gray.opacity(0.25),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: .black.opacity(0.12),
                        radius: 8,
                        y: 3
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
            .frame(height: 150)

            VStack(spacing: 4) {
                Text("\(width) × \(height) px")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)

                Text(
                    selectedTemplate?.localizedName ?? "Eigene Größe"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Size Controls

    private var sizeControls: some View {
        Group {
            LabeledContent("Breite") {
                TextField(
                    "Breite",
                    value: $width,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .width)
            }

            LabeledContent("Höhe") {
                TextField(
                    "Höhe",
                    value: $height,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: .height)
            }

            LabeledContent {
                Text(aspectRatioText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } label: {
                Label(
                    "Seitenverhältnis",
                    systemImage: "aspectratio"
                )
            }

            LabeledContent {
                Text(pixelCountText)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            } label: {
                Label(
                    "Pixel",
                    systemImage: "square.grid.3x3"
                )
            }
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            guard validSize else { return }

            focusedField = nil

            editorSize = CGSize(
                width: width,
                height: height
            )

            openEditor = true
        } label: {
            Label(
                "Leinwand erstellen",
                systemImage: "plus"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!validSize)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Computed Values

    private var pixelCountText: String {
        let (count, overflow) = max(width, 0).multipliedReportingOverflow(
            by: max(height, 0)
        )
        return overflow ? "–" : count.formatted()
    }

    private var aspectRatioText: String {
        guard width > 0, height > 0 else {
            return "–"
        }

        let divisor = gcd(width, height)

        return "\(width / divisor):\(height / divisor)"
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)

        while y != 0 {
            let remainder = x % y
            x = y
            y = remainder
        }

        return max(x, 1)
    }

    // MARK: - Selection

    private func selectTemplate(_ template: CanvasTemplate) {
        focusedField = nil

        width = template.width
        height = template.height

        selectedTemplateID = template.id
    }

    private func updateSelection() {
        guard let template = selectedTemplate else {
            return
        }

        if template.width != width || template.height != height {
            selectedTemplateID = ""
        }
    }
}

// MARK: - Canvas Template Picker

struct CanvasTemplatePicker: View {

    let templates: [CanvasTemplate]
    @Binding var selectedID: String
    let onSelect: (CanvasTemplate) -> Void

    @State private var selectedCategory: CanvasTemplateCategory = .standard

    private var categories: [CanvasTemplateCategory] {
        CanvasTemplateCategory.allCases
            .filter { category in
                templates.contains {
                    $0.category == category
                }
            }
            .sorted {
                $0.sortOrder < $1.sortOrder
            }
    }

    private let columns = [
        GridItem(
            .adaptive(minimum: 110, maximum: 180),
            spacing: 10
        )
    ]

    var body: some View {
        VStack(spacing: 12) {
            Picker("Kategorie", selection: $selectedCategory) {
                ForEach(categories) { category in
                    Label(category.title, systemImage: category.symbol)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(templates.filter { $0.category == selectedCategory }) {
                    template in
                    templateButton(template)
                }
            }
        }
        .onAppear {
            if let selected = templates.first(where: { $0.id == selectedID }) {
                selectedCategory = selected.category
            }
        }
    }

    // MARK: - Template Button

    private func templateButton(
        _ template: CanvasTemplate
    ) -> some View {
        let isSelected = selectedID == template.id

        return Button {
            onSelect(template)
        } label: {
            VStack(spacing: 7) {
                templateShape(template)
                    .frame(height: 34)

                Text(template.localizedName)
                    .font(.caption.weight(.medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(template.dimensionText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 94)
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.12)
                            : Color(uiColor: .tertiarySystemGroupedBackground)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected
                            ? Color.accentColor
                            : Color.clear,
                        lineWidth: 1.5
                    )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!template.isValid)
        .accessibilityLabel(Text(template.localizedName))
        .accessibilityValue(template.dimensionText)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Aspect Ratio Shape

    private func templateShape(
        _ template: CanvasTemplate
    ) -> some View {
        let ratio = max(
            template.aspectRatio,
            0.01
        )

        let maxWidth: CGFloat = 44
        let maxHeight: CGFloat = 32

        let shapeWidth = min(
            maxWidth,
            maxHeight * ratio
        )

        let shapeHeight = min(
            maxHeight,
            maxWidth / ratio
        )

        return RoundedRectangle(cornerRadius: 3)
            .fill(Color.accentColor.opacity(0.12))
            .frame(
                width: shapeWidth,
                height: shapeHeight
            )
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        Color.accentColor.opacity(0.65),
                        lineWidth: 1
                    )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: 34
            )
    }

}

#Preview {
    CanvasCreationView()
}
