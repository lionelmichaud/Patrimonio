//
//  ShareSheetView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/06/2021.
//

import SwiftUI

class UIActivityViewControllerHost: UIViewController {
    var message = ""
    var items = [Any]()
    var completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler?
    
    override func viewDidAppear(_ animated: Bool) {
        share()
    }
    
    func share() {
        // set up activity view controller
        let textToShare = [ message ]
        let activityViewController = UIActivityViewController(activityItems: textToShare,
                                                              applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = completionWithItemsHandler
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }
}

struct ShareActivityViewController: UIViewControllerRepresentable {
    @State var text: String
    @Binding var showing: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewControllerHost {
        // Create the host and setup the conditions for destroying it
        let result = UIActivityViewControllerHost()
        
        result.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            // To indicate to the hosting view this should be "dismissed"
            self.showing = false
        }
        
        return result
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewControllerHost, context: Context) {
        // Update the text in the hosting controller
        uiViewController.message = text
    }
}

struct ShareSheetModifer: ViewModifier {
    @State private var showShareSheet: Bool = false
    @State var shareSheetItems: [Any] = []
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button(action: {
                    self.showShareSheet.toggle()
                }) {
                    Text("Share")
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showShareSheet, content: {
                ActivityViewController(activityItems: self.$shareSheetItems, excludedActivityTypes: excludedActivityTypes)
            })
    }
}


struct ActivityViewController: UIViewControllerRepresentable {
    @Binding var activityItems: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: nil)
        
        controller.excludedActivityTypes = excludedActivityTypes
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}


extension View {
    func shareSheet(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) -> some View {
        self.modifier(ShareSheetModifer(shareSheetItems: items, excludedActivityTypes: excludedActivityTypes))
    }
}
