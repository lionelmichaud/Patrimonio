//
//  ButtonStyles.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Syle de bouton Rectangle à coins arrondis
public struct RoundedRectButtonStyle: ButtonStyle {
    public var color     : Color     = .accentColor
    public var width     : CGFloat?
    public var height    : CGFloat?
    public var alignment : Alignment = .center

    struct MyButton: View {
        let configuration : RoundedRectButtonStyle.Configuration
        var color         : Color     = .accentColor
        var width         : CGFloat?
        var height        : CGFloat?
        var alignment     : Alignment = .center

        var body: some View {
            configuration.label
                .frame(width: width, height: height, alignment: alignment)
                .foregroundColor(.white)
                .padding(15)
                .background(RoundedRectangle(cornerRadius: 5).fill(color))
                .compositingGroup()
                .shadow(color: .black, radius: 3)
                .opacity(configuration.isPressed ? 0.5 : 1.0)
        }
    }

    public func makeBody(configuration: RoundedRectButtonStyle.Configuration) -> some View {
        MyButton(configuration : configuration,
                 color         : color,
                 width         : width,
                 height        : height,
                 alignment     : alignment)
    }
}

public extension Button {
    func roundedRectButtonStyle(color     : Color     = .accentColor,
                                width     : CGFloat?,
                                height    : CGFloat?  = nil,
                                alignment : Alignment = .center) -> some View {
        self.buttonStyle(RoundedRectButtonStyle(color     : color,
                                                width     : width,
                                                height    : height,
                                                alignment : alignment))
    }
}

// MARK: - Syle de bouton Capsule - façon iOS 14
public struct CapsuleButtonStyle: ButtonStyle {
    public var color     : Color     = Color("buttonBackgroundColor")
    public var width     : CGFloat?
    public var height    : CGFloat?
    public var alignment : Alignment = .center
    public var withShadow: Bool      = false
    
    struct MyButton: View {
        let configuration : CapsuleButtonStyle.Configuration
        var color         : Color     = Color("buttonBackgroundColor")
        var width         : CGFloat?
        var height        : CGFloat?
        var alignment     : Alignment = .center
        var withShadow    : Bool      = false

        var body: some View {
            configuration.label
                .frame(width: width, height: height, alignment: alignment)
                .foregroundColor(.accentColor)
                .padding(.vertical, 5.0)
                .padding(.horizontal, 10.0)
                .background(Capsule(style: .continuous).fill(color))
            //.compositingGroup()
            //.shadow(color: .black, radius: 3)
                .opacity(configuration.isPressed ? 0.4 : 1.0)
        }
    }

    public func makeBody(configuration: CapsuleButtonStyle.Configuration) -> some View {
        MyButton(configuration : configuration,
                 color         : color,
                 width         : width,
                 height        : height,
                 alignment     : alignment)
    }
    
}

public extension Button {
    func capsuleButtonStyle(color     : Color     = Color("buttonBackgroundColor"),
                            width     : CGFloat?  = nil,
                            height    : CGFloat?  = nil,
                            alignment : Alignment = .center) -> some View {
        self.buttonStyle(CapsuleButtonStyle(color: color,
                                            width: width,
                                            height: height,
                                            alignment: alignment))
    }
}

// Button(iconName: "play.fill") {
public extension Button where Label == Image {
    init(iconName: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Image(systemName: iconName)
        }
    }
}

// MARK: - Previews

struct ButtonsViews_Previews: PreviewProvider {
    struct RoundedRectButtonStyleView: View {
        var body: some View {
            VStack {
                Button("Tap Me!") {
                    print("button pressed!")
                }.roundedRectButtonStyle(color: .blue, width: 200)
            }
        }
    }
    
    struct CapsuleButtonStyleView: View {
        var body: some View {
            VStack {
                Button("Tap Me!") {
                    print("button pressed!")
                }.capsuleButtonStyle(color: Color("buttonBackgroundColor"))
            }
        }
    }
    
    static let itemSelection = [(label: "item 1", selected: true),
                                (label: "item 2", selected: true)]
    
    static var previews: some View {
        Group {
            Group {
                RoundedRectButtonStyleView()
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("RoundedRectButtonStyleView")
                CapsuleButtonStyleView()
                    .preferredColorScheme(.dark)
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("CapsuleButtonStyleView")
                CapsuleButtonStyleView()
                    .preferredColorScheme(.light)
                    .previewLayout(PreviewLayout.sizeThatFits)
                    .padding()
                    .previewDisplayName("CapsuleButtonStyleView")
            }
        }
    }
}

// MARK: - Library Modifiers

// swiftlint:disable type_name
struct ButtonModifiers_Library: LibraryContentProvider {
    @LibraryContentBuilder
    func modifiers(base: Button<EmptyView>) -> [LibraryItem] {
        LibraryItem(base.roundedRectButtonStyle(color : .blue, width : 200),
                    title                             : "Rounded Rect Button",
                    category                          : .control,
                    matchingSignature                 : "roundrectbutton")
        LibraryItem(base.capsuleButtonStyle(color : Color("buttonBackgroundColor")),
                    title                         : "Capsule Rect Button",
                    category                      : .control,
                    matchingSignature             : "capsulebutton")
    }
}
