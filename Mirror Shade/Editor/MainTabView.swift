//
//  MainTabView.swift
//  Mirror Shade
//
//  Created by Tufan Cakir on 11.11.26.
//

import SwiftUI

struct MainTabView: View {

    var body: some View {
        TabView {
            Tab("Erstellen", systemImage: "plus.square") {
                CanvasCreationView()
            }

            Tab("Projekte", systemImage: "square.grid.2x2") {
                ProjectsView()
            }

            Tab("Einstellungen", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
