//
//  ProjectsView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftData
import SwiftUI

struct ProjectsView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: \DrawingProject.updatedAt,
        order: .reverse
    )
    private var projects: [DrawingProject]

    @State private var projectToDelete: DrawingProject?
    @State private var showDeleteConfirmation = false

    private let columns = [
        GridItem(
            .adaptive(minimum: 145, maximum: 240),
            spacing: 14
        )
    ]

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    projectGrid
                }
            }
            .navigationTitle("Projekte")
            .confirmationDialog(
                "Projekt löschen?",
                isPresented: $showDeleteConfirmation
            ) {
                Button(
                    "Projekt löschen",
                    role: .destructive
                ) {
                    deleteSelectedProject()
                }
            } message: {
                Text(
                    "Dieses Projekt wird dauerhaft gelöscht."
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "Keine Projekte",
            systemImage: "square.stack",
            description: Text(
                "Deine gespeicherten Zeichnungen erscheinen hier."
            )
        )
    }

    // MARK: - Project Grid

    private var projectGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: columns,
                spacing: 14
            ) {
                ForEach(projects) { project in
                    projectCard(project)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Project Card

    private func projectCard(
        _ project: DrawingProject
    ) -> some View {
        NavigationLink {
            DrawingEditorView(
                width: project.width,
                height: project.height,
                project: project
            )
            .id(project.id)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                projectThumbnail(project)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(project.dimensionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        project.updatedAt,
                        format: .dateTime
                            .day()
                            .month()
                            .year()
                    )
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                projectToDelete = project
                showDeleteConfirmation = true
            } label: {
                Label(
                    "Löschen",
                    systemImage: "trash"
                )
            }
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func projectThumbnail(
        _ project: DrawingProject
    ) -> some View {
        if let data = project.thumbnailData,
            let image = UIImage(data: data)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else {
            Image(systemName: "scribble.variable")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Delete

    private func deleteSelectedProject() {
        guard let projectToDelete else { return }

        modelContext.delete(projectToDelete)

        do {
            try modelContext.save()
        } catch {
            print("Projekt konnte nicht gelöscht werden: \(error)")
        }

        self.projectToDelete = nil
    }
}

#Preview {
    ProjectsView()
        .modelContainer(
            for: DrawingProject.self,
            inMemory: true
        )
}
