//
//  YikeApp.swift
//  Yike
//
//  Created by 冯元宙 on 2025/3/3.
//

import SwiftUI

@main
struct YikeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
