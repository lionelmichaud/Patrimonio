//
//  PopOverContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

public struct PopOverContentView: View {
    var title       : String?
    var description : String?
    var imageName   : String?
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 10) {
                if let title {
                    Text(title)
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                if let description {
                    Text(description)
                }
                if let imageName {
                    Image(imageName)
                        .scaledToFit()
                }
            }
        }
        .padding()
    }

    public init(title       : String?  = nil,
                description : String?  = nil,
                imageName   : String?  = nil) {
        self.title       = title
        self.description = description
        self.imageName   = imageName
    }
}

struct PopOverContentView_Previews: PreviewProvider {
    static var previews: some View {
        PopOverContentView(title: "Titre",
                           description: "contenu du popvoer")
            .previewLayout(.sizeThatFits)
    }
}
