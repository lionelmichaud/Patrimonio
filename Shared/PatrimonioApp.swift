//
//  PatrimonioApp.swift
//  Shared
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import SwiftUI

@main
struct PatrimonioApp: App {

    // MARK: - Properties

    /// data model object that you want to use throughout your app and that will be shared among the scenes
    // initializer family avant les autres car il injecte sa propre @
    // dans une propriété statique des autres Classes pendant son initialisation
    @StateObject private var family     = Family()
    @StateObject private var patrimoine = Patrimoin()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
