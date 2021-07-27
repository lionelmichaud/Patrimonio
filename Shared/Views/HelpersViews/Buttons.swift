//
//  Buttons.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/07/2021.
//

import SwiftUI

struct SaveToDiskButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "externaldrive.fill")
                        .imageScale(.large)
                    Text("Enregistrer")
                }
            })
            .capsuleButtonStyle()
    }
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
}

struct SaveToFolderButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "folder.fill")
                        .imageScale(.large)
                    Text("Sauver")
                }
            })
            .capsuleButtonStyle()
    }
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
}

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {
        SaveToDiskButton(action: { print("saved") })
    }
}
