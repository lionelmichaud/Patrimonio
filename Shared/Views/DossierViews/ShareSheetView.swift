//
//  ShareSheetView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/06/2021.
//

import SwiftUI
import Persistence
import HelpersView

struct ActivityViewController: UIViewControllerRepresentable {
    @Binding var activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: nil)
        
        controller.excludedActivityTypes = excludedActivityTypes
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

// MARK: - View Modifiers

struct SharePopoverContextMenuModifer: ViewModifier {
    @State private var showShareSheet: Bool = false
    @State var shareSheetItems: [Any] = []
    var excludedActivityTypes: [UIActivity.ActivityType]?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: {
                    self.showShareSheet.toggle()
                },
                label: {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up.on.square")
                })
            }
            .popover(isPresented : $showShareSheet,
                   content     : {
                    ActivityViewController(activityItems: self.$shareSheetItems,
                                           excludedActivityTypes: excludedActivityTypes)
                   })
    }
}

struct SharePopoverModifer: ViewModifier {
    @Binding var showShareSheet : Bool
    @State var shareSheetItems  : [Any] = []
    var excludedActivityTypes: [UIActivity.ActivityType]?
    
    func body(content: Content) -> some View {
        content
            .popover(isPresented : $showShareSheet,
                   content     : {
                    ActivityViewController(activityItems: self.$shareSheetItems,
                                           excludedActivityTypes: excludedActivityTypes)
                   })
    }
}

// MARK: - View Extensions

extension View {
    func shareContextMenu(items                 : [Any],
                          excludedActivityTypes : [UIActivity.ActivityType]?  = nil) -> some View {
        self.modifier(SharePopoverContextMenuModifer(shareSheetItems: items,
                                                   excludedActivityTypes: excludedActivityTypes))
    }
}

extension View {
    func sharePopover(showShareSheet        : Binding<Bool>,
                      items                 : [Any],
                      excludedActivityTypes : [UIActivity.ActivityType]?  = nil) -> some View {
        self.modifier(SharePopoverModifer(showShareSheet: showShareSheet,
                                        shareSheetItems: items,
                                        excludedActivityTypes: excludedActivityTypes))
    }
}

func share(items      : [Any],
           activities : [UIActivity]?  = nil,
           animated   : Bool           = true,
           fromX      : Double?        = nil,
           fromY      : Double?        = nil) {
    let activityView = UIActivityViewController(activityItems: items,
                                                applicationActivities: activities)
    UIApplication.shared.windows.first?.rootViewController?.present(activityView,
                                                                    animated   : animated,
                                                                    completion : nil)
    
    if UIDevice.current.userInterfaceIdiom == .pad {
        activityView.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
        activityView.popoverPresentationController?.sourceRect = CGRect(
            x: (fromX == nil) ? UIScreen.main.bounds.width / 2.1 : fromX!,
            y: (fromY == nil) ? UIScreen.main.bounds.height / 2.3 : fromY!,
            width: 32,
            height: 32)
    }
}

func collectedURLs(dataStore : Store,
                   fileNames : [String]?  = nil,
                   alertItem : inout AlertItem?) -> [URL] {
    var urls = [URL]()
    do {
        // vérifier l'existence du Folder associé au Dossier
        guard let activeFolder = dataStore.activeDossier!.folder else {
            throw DossierError.failedToFindFolder
        }
        
        // collecte des URL des fichiers contenus dans le dossier
        activeFolder.files.forEach { file in
            if let fileNames = fileNames {
                fileNames.forEach { fileName in
                    if file.name.contains(fileName) {
                        urls.append(file.url)
                    }
                }
            } else {
                urls.append(file.url)
            }
        }
        
    } catch {
        alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                              dismissButton : .default(Text("OK")))
        return [ ]
    }
    
    return urls
}

/// Partager les fichiers contenus dans le dossier actif de `dataStore`
/// et qui contiennent l'une des Strings de `fileNames`
/// ou bien tous les fichiers si `fileNames` = `nil`
/// - Parameters:
///   - dataStore: dataStore de l'application
///   - fileNames: permet d'identifier les fichiers à partager
///   - geometry: gemetry de la View qui appèle la fonction
func shareFiles(dataStore : Store,
                fileNames : [String]? = nil,
                alertItem : inout AlertItem?,
                geometry  : GeometryProxy) {
    let urls = collectedURLs(dataStore: dataStore,
                             fileNames: fileNames,
                             alertItem: &alertItem)
    
    // partage des fichiers collectés
    if urls.isNotEmpty {
        share(items: urls,
              fromX: Double(geometry.frame(in: .global).maxX-32),
              fromY: 24.0)
    }
}
