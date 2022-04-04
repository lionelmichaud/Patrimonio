//
//  RatingView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/01/2022.
//

import SwiftUI

public struct RatingView: View {
    private let rating    : Int
    private let minRating : Int
    private let maxRating : Int
    private var label     : String?
    private var font      : Font = .body
    /// The color of the star that will be displayed when not selected, defaults to gray
    private var offColor = Color.gray
    /// The color of the star when selected, defaults to accentColor
    private var onColor  : [Color] = [Color.accentColor]
    private var offImage = Image(systemName: "square")
    private var onImage  = Image(systemName: "square.fill")

    public var body: some View {
        HStack (spacing: 0) {
            if let label = self.label {
                Text(label)
                    .font(font)
                    .padding(.trailing, 4)
            }
            ForEach(minRating ..< maxRating + 1, id: \.self) { number in
                if onColor.count == 1 {
                    self.image(for: number)
                        .font(font)
                        .foregroundColor(number > self.rating ? self.offColor : self.onColor[0])
                } else if onColor.count == (maxRating - minRating + 1) {
                    self.image(for: number)
                        .font(font)
                        .foregroundColor(number > self.rating ? self.offColor : self.onColor[rating - minRating])
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    public init(rating    : Int,
                minRating : Int      = 0,
                maxRating : Int,
                label     : String?  = nil,
                font      : Font     = .body,
                offColor  : Color    = Color.gray,
                onColor   : [Color]  = [Color.accentColor],
                offImage  : Image    = Image(systemName : "star"),
                onImage   : Image    = Image(systemName : "star.fill")) {
        self.rating    = rating
        self.minRating = minRating
        self.maxRating = maxRating
        self.label     = label
        self.font      = font
        self.offColor  = offColor
        self.onColor   = onColor
        self.offImage  = offImage
        self.onImage   = onImage
    }
    
    private func image(for number: Int) -> Image {
        if number > rating {
            return offImage
        } else {
            return onImage
        }
    }
}

struct RatingView_Previews: PreviewProvider {
    static var previews: some View {
        RatingView(rating    : 2,
                   minRating : 0,
                   maxRating : 4,
                   label     : "Note",
                   offColor  : Color.gray,
                   onColor   : [Color.accentColor],
                   offImage  : Image(systemName : "star"),
                   onImage   : Image(systemName : "star.fill"))
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)

        RatingView(rating    : 0,
                   minRating : 0,
                   maxRating : 4,
                   font      : .body,
                   offColor  : Color.gray,
                   onColor   : [Color.blue],
                   offImage  : Image(systemName : "circle"),
                   onImage   : Image(systemName : "circle.fill"))
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)

        RatingView(rating    : 1,
                   maxRating : 4,
                   font      : .body,
                   onColor   : [Color.green])
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)

        RatingView(rating    : 2,
                   maxRating : 4,
                   font      : .body,
                   onColor   : [Color.pink])
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
