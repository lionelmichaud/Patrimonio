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

struct ShareSheetContextMenuModifer: ViewModifier {
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

struct ShareSheetModifer: ViewModifier {
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
        self.modifier(ShareSheetContextMenuModifer(shareSheetItems: items,
                                                   excludedActivityTypes: excludedActivityTypes))
    }
}

extension View {
    func shareSheet(showShareSheet        : Binding<Bool>,
                    items                 : [Any],
                    excludedActivityTypes : [UIActivity.ActivityType]?  = nil) -> some View {
        self.modifier(ShareSheetModifer(showShareSheet: showShareSheet,
                                        shareSheetItems: items,
                                        excludedActivityTypes: excludedActivityTypes))
    }
}
