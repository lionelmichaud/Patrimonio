//
//  AppVersionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import Files

struct AppVersionView: View {
    var body: some View {
        VStack {
            Text(AppVersion.shared.name ?? "Patrimonio")
                .font(.title)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
            Text("Version: \(AppVersion.shared.theVersion ?? "?")")
            if let date = AppVersion.shared.date {
                Text(date, style: Text.DateStyle.date)
            }
            Text(AppVersion.shared.comment ?? "")
                .multilineTextAlignment(.center)
        }
        Form {
            Text("resourcePath: \n" + Bundle.main.resourcePath!)
            Text("Application: \n" + Folder.application!.path)
            Text("Home: \n" +        Folder.home.path)
            Text("Tempates: \n" +  (Dossier.templates?.folder?.path ?? "introuvable"))
            Text("Documents: \n" + (Folder.documents?.path ?? "introuvable"))
            Text("Library: \n" +   (Folder.library?.path ?? "introuvable"))
            Text("temporary: \n" + Folder.temporary.path)
        }
    }
}

struct AppVersionView_Previews: PreviewProvider {
    static var previews: some View {
        AppVersionView()
    }
}
