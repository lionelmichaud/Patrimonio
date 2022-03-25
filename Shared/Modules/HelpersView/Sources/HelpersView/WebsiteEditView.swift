//
//  WebsiteEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 24/02/2022.
//

import SwiftUI

public struct WebsiteEditView: View {
    @Binding
    private var website: URL?
    @State
    private var url: String

    public var body: some View {
        HStack {
            if let website = website {
                Link(destination: website) {
                    Image(systemName: "link.circle.fill")
                        .font(.title)
                }
            } else {
                Image(systemName: "link.circle.fill")
                    .font(.title)
                    .foregroundColor(.secondary)
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

    public init(website: Binding<URL?>) {
        _url = State(initialValue: website.wrappedValue?.absoluteString ?? "")
        _website = website
    }
}

struct WebsiteEditView_Previews: PreviewProvider {
    static var previews: some View {
        WebsiteEditView(website: .constant(URL(string: "https://www.google.com")))
    }
}
