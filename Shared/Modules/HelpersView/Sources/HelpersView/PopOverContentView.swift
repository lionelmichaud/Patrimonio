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
    var description : String
    
    public var body: some View {
        VStack(spacing: 10) {
            if let title = title {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            Text(description)
        }
        .padding()
    }

    public init(title       : String?  = nil,
                description : String) {
        self.title = title
        self.description = description
    }
}

struct PopOverContentView_Previews: PreviewProvider {
    static var previews: some View {
        PopOverContentView(title: "Titre",
                           description: "contenu du popvoer")
            .previewLayout(.sizeThatFits)
    }
}
