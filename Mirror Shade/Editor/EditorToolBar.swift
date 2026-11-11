//
//  EditorToolBar.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftUI

struct EditorToolBar: View {
    let tools: [DrawingTool]
    @Binding var selectedToolID: String
    @Binding var selectedColor: Color
    @Binding var lineWidth: Double

    private var supportsWidth: Bool {
        tools.first { $0.id == selectedToolID }.map {
            [.pen, .pencil, .marker].contains($0.kind)
        } ?? false
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Menu {
                    Section("Zeichnen") {
                        ForEach(
                            tools.filter {
                                [.pen, .pencil, .marker].contains($0.kind)
                            }
                        ) { tool in
                            toolButton(tool)
                        }
                    }
                    Section("Bearbeiten") {
                        ForEach(
                            tools.filter {
                                [.eraser, .fill, .lasso].contains($0.kind)
                            }
                        ) { tool in
                            toolButton(tool)
                        }
                    }
                } label: {
                    Label(
                        tools.first { $0.id == selectedToolID }?.localizedName
                            ?? "Stift",
                        systemImage: tools.first { $0.id == selectedToolID }?
                            .symbol ?? "pencil"
                    )
                    .frame(minHeight: 44)
                }
                Spacer()
                ColorPicker("Farbe", selection: $selectedColor)
                    .fixedSize()
            }
            if supportsWidth {
                HStack {
                    Image(systemName: "line.diagonal")
                        .accessibilityHidden(true)
                    Slider(value: $lineWidth, in: 1...60, step: 1) {
                        Text("Strichstärke")
                    }
                    Text("\(Int(lineWidth)) px")
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func toolButton(_ tool: DrawingTool) -> some View {
        Button {
            selectedToolID = tool.id
            lineWidth = Double(tool.width)
        } label: {
            Label(
                tool.localizedName,
                systemImage: selectedToolID == tool.id
                    ? "checkmark" : tool.symbol
            )
        }
    }
}

struct CanvasSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var projectName: String
    @Binding var showGrid: Bool
    @Binding var showTransparency: Bool
    @Binding var backgroundColor: Color
    @Binding var transparent: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Projekt") {
                    TextField("Name", text: $projectName)
                }
                Section("Hintergrund") {
                    Toggle("Transparent", isOn: $transparent)
                    if !transparent {
                        ColorPicker(
                            "Hintergrundfarbe",
                            selection: $backgroundColor,
                            supportsOpacity: false
                        )
                    }
                }
                Section {
                    Toggle("Leinwandraster", isOn: $showGrid)
                    Toggle("Transparenzraster", isOn: $showTransparency)
                } header: {
                    Text("Ansicht")
                } footer: {
                    Text(
                        "Die Raster dienen nur als Zeichenhilfe und werden nicht exportiert."
                    )
                }
            }
            .navigationTitle("Leinwand & Projekt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

struct CanvasGuideGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            for step in 1..<8 {
                let fraction = CGFloat(step) / 8
                path.move(to: CGPoint(x: size.width * fraction, y: 0))
                path.addLine(
                    to: CGPoint(x: size.width * fraction, y: size.height)
                )
                path.move(to: CGPoint(x: 0, y: size.height * fraction))
                path.addLine(
                    to: CGPoint(x: size.width, y: size.height * fraction)
                )
            }
            context.stroke(
                path,
                with: .color(.white.opacity(0.5)),
                lineWidth: 2
            )
            context.stroke(
                path,
                with: .color(.black.opacity(0.35)),
                lineWidth: 0.5
            )
        }
        .accessibilityHidden(true)
    }
}
