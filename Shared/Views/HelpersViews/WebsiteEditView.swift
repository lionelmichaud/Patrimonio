//
//  WebsiteEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 24/02/2022.
//

import SwiftUI

struct WebsiteEditView: View {
    @Binding var website: URL?
    @State private var url: String

    var body: some View {
        HStack {
            if let website = website {
                Link(destination: website) {
                    Image(systemName: "safari")
                }
            } else {
                Image(systemName: "safari").foregroundColor(.secondary)
            }
            TextField("url", text: $url)
                .onChange(of: url) { newUrl in
                    if newUrl == "" {
                        website = nil
                    } else {
                        website = URL(string: newUrl)
                    }
                }
        }
    }

    init(website: Binding<URL?>) {
        _url = State(initialValue: website.wrappedValue?.absoluteString ?? "")
        _website = website
    }
}

struct WebsiteEditView_Previews: PreviewProvider {
    static var previews: some View {
        WebsiteEditView(website: .constant(URL(string: "https://www.google.com")))
    }
}
