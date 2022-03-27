//
//  Buttons.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/07/2021.
//

import SwiftUI

struct DiskButton: View {
    let action    : () -> Void
    let butonText : String?
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "externaldrive")
                        .imageScale(.large)
                    if let theText = butonText {
                        Text(theText)
                    }
                }
            })
            .capsuleButtonStyle()
    }
    
    init(text   : String? = "Enregistrer",
         action : @escaping () -> Void) {
        self.action    = action
        self.butonText = text
    }
}

struct TemplateButton: View {
    let action    : () -> Void
    let butonText : String?
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .imageScale(.large)
                    if let theText = butonText {
                        Text(theText)
                    }
                }
            })
        .buttonStyle(.bordered)
            //.capsuleButtonStyle()
    }
    
    init(text   : String? = "Enregistrer",
         action : @escaping () -> Void) {
        self.action    = action
        self.butonText = text
    }
}

struct FolderButton: View {
    let action    : () -> Void
    let butonText : String
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "folder.fill")
                        .imageScale(.large)
                    Text(butonText)
                }
            })
            .capsuleButtonStyle()
    }
    
    init(text   : String = "Appliquer",
         action : @escaping () -> Void) {
        self.action    = action
        self.butonText = text
    }
}

struct DuplicateButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(
            action : action,
            label  : {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .imageScale(.medium)
                    //Text("Dupliquer")
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
        Group {
            DiskButton(action: { print("saved") })
                .previewLayout(.fixed(width: 200, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
            TemplateButton(action: { print("modified") })
                .previewLayout(.fixed(width: 200, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
            FolderButton(action: { print("modified") })
                .previewLayout(.fixed(width: 200, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
            DuplicateButton(action: { print("duplicated") })
                .previewLayout(.fixed(width: 200, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
        }
    }
}
