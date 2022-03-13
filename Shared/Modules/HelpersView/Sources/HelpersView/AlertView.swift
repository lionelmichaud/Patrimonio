//
//  AlertView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

/// Une alerte à 1 ou 2 boutons
///
/// Usage:
///   ```
///   var body: some View {
///       VStack {
///           /// button 1
///           Button(action: {
///               self.alertItem =
///                   AlertItem(title         : Text("I'm an alert"),
///                              message       : Text("Are you sure about this?"),
///                              primaryButton : .default(Text("Yes"),
///                                                       action: {
///                                                           /// insert alert 1 action here
///                                                       }),
///                              secondaryButton: .cancel())
///           }, label: {
///               Text("SHOW ALERT 1")
///           })
///
///           /// button 2
///           Button(action: {
///               self.alertItem =
///                   AlertItem(title         : Text("I'm another alert"),
///                              dismissButton : .default(Text("OK")))
///           }, label: {
///               Text("SHOW ALERT 2")
///           })
///
///       }.alert(item: $alertItem, content: newAlert)
///   }
///   ```
/// - Note: [reference](https://medium.com/better-programming/alerts-in-swiftui-a714a19a547e)
///
/// - Important: If you have child views that also present alerts, you can pass the AlertItem as binding
/// and be confident that the behavior should be no different.
///
/// - Important: Presenting an Alert Within an Alert:
/// The solution is to update the value of the AlertItem asynchronously. Once the action of the first alert has finished, the UI will be updated.

public struct AlertItem: Identifiable {
    public var id    = UUID()
    public var title = Text("")
    public var message         : Text?
    public var dismissButton   : Alert.Button?
    public var primaryButton   : Alert.Button?
    public var secondaryButton : Alert.Button?

    public init(id              : UUID           = UUID(),
                title           : Text           = Text(""),
                message         : Text?          = nil,
                dismissButton   : Alert.Button?  = nil,
                primaryButton   : Alert.Button?  = nil,
                secondaryButton : Alert.Button?  = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.dismissButton = dismissButton
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

/// Créer une Alerte à partir d'un AlertItem
public func newAlert(alertItem: AlertItem) -> Alert {
    if let primaryButton = alertItem.primaryButton,
        let secondaryButton = alertItem.secondaryButton {
        return Alert(title           : alertItem.title,
                     message         : alertItem.message,
                     primaryButton   : primaryButton,
                     secondaryButton : secondaryButton)
    } else {
        return Alert(title         : alertItem.title,
                     message       : alertItem.message,
                     dismissButton : alertItem.dismissButton)
    }
}

// MARK: - Exemples

/// Usage
/// https://medium.com/better-programming/alerts-in-swiftui-a714a19a547e
/// - Note: If you have child views that also present alerts, you can pass the AlertItem as binding
/// and be confident that the behavior should be no different.
struct ContentWithAlertView: View {
    
    @State var alertItem : AlertItem?
    
    var body: some View {
        VStack {
            /// button 1
            Button(action: {
                self.alertItem =
                    AlertItem(title         : Text("I'm an alert"),
                              message       : Text("Are you sure about this?"),
                              primaryButton : .default(Text("Yes"),
                                                       action: {
                                                        /// insert alert 1 action here
                                                       }),
                              secondaryButton: .cancel())
            }, label: {
                Text("SHOW ALERT WITH 2 BUTTONS")
            }).padding(.bottom)
            
            /// button 2
            Button(action: {
                self.alertItem =
                    AlertItem(title         : Text("I'm another alert"),
                              dismissButton : .default(Text("OK")))
            }, label: {
                Text("SHOW ALERT WITH 1 BUTTON")
            })
            
        }.alert(item: $alertItem, content: newAlert)
    }
}

/// Usage
/// https://medium.com/better-programming/alerts-in-swiftui-a714a19a547e
/// - Note: Presenting an Alert Within an Alert:
/// The solution is to update the value of the AlertItem asynchronously. Once the action of the first alert has finished, the UI will be updated.
struct ContentWithNestedAlertView: View {

    @State var alertItem : AlertItem?
    
    var body: some View {
        /// button
        Button(action: {
            self.alertItem =
                AlertItem(title: Text("I'm an alert"),
                          message: Text("Are you sure about this?"),
                          primaryButton: .default(Text("Yes"),
                                                  action: {
                                                    /// trigger second alert
                                                    DispatchQueue.main.async {
                                                        self.alertItem = AlertItem(title: Text("Error"),
                                                                                   message: Text("An unexpected error occurred"),
                                                                                   dismissButton: .default(Text("OK")))
                                                    }
                                                    
                                                  }), secondaryButton: .cancel())
        }, label: {
            Text("SHOW NESTED ALERTS")
        }).alert(item: $alertItem, content: newAlert)
    }
}

struct ContentWithAlertView_Previews: PreviewProvider {
    static var previews: some View {
        ContentWithAlertView()
            .previewDisplayName("ContentWithAlertView")
        ContentWithNestedAlertView()
            .previewDisplayName("ContentWithNestedAlertView")
    }
}
