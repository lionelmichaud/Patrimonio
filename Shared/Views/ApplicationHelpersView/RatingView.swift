//
//  RatingView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/01/2022.
//

import SwiftUI

struct RatingView: View {
    let rating    : Int
    var minRating : Int = 0
    let maxRating : Int
    var label     : String?
    var font      : Font = .body
    /// The color of the star that will be displayed when not selected, defaults to gray
    var offColor = Color.gray
    /// The color of the star when selected, defaults to accentColor
    var onColor  : [Color] = [Color.accentColor]
    var offImage = Image(systemName: "square")
    var onImage  = Image(systemName: "square.fill")

    var body: some View {
        HStack (spacing: 0) {
            if let label = self.label {
                Text(label)
                    .font(font)
                    .padding(.trailing, 4)
            }
            ForEach(minRating ..< maxRating + 1) { number in
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
    
    func image(for number: Int) -> Image {
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
                   onColor   : ChartThemes.riskColorsTable.map { Color($0) },
                   offImage  : Image(systemName : "square"),
                   onImage   : Image(systemName : "square.fill"))
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)

        RatingView(rating    : 1,
                   maxRating : 4,
                   font      : .body,
                   onColor   : ChartThemes.riskColorsTable.map { Color($0) })
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)

        RatingView(rating    : 2,
                   maxRating : 4,
                   font      : .body,
                   onColor   : ChartThemes.riskColorsTable.map { Color($0) })
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
    }
}
