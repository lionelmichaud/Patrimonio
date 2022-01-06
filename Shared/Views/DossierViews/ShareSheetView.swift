//
//  ShareSheetView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/06/2021.
//

import SwiftUI

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
                    Image(systemName: "square.and.arrow.up")
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
            x: (fromX == nil) ? UIScreen.main.bounds.width / 2.1 : CGFloat(fromX!),
            y: (fromY == nil) ? UIScreen.main.bounds.height / 2.3 : CGFloat(fromY!),
            width: 32,
            height: 32)
    }
}
