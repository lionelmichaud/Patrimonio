//
//  ProgressViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
//import ActivityIndicatorView // https://github.com/exyte/ActivityIndicatorView.git

// MARK: - Progress bar
struct ProgressBar: View {
    private let value             : Double
    private let minValue          : Double
    private let maxValue          : Double
    private let backgroundEnabled : Bool
    private let externalLabels    : Bool
    private let internalLabels    : Bool
    private let backgroundColor   : Color
    private let foregroundColor   : Color
    private let valuePercent      : Bool
    private let maxValuePercent   : Bool
    private let formater          : NumberFormatter?
    
    init(value             : Double,
         minValue          : Double = 0.0,
         maxValue          : Double,
         backgroundEnabled : Bool  = true,
         externalLabels    : Bool  = false,
         internalLabels    : Bool  = false,
         backgroundColor   : Color = .secondary,
         foregroundColor   : Color = .blue,
         valuePercent      : Bool  = false,
         maxValuePercent   : Bool  = false,
         formater          : NumberFormatter? = nil) {
        precondition(maxValue > minValue)
        self.value             = value.clamp(low: minValue, high: maxValue)
        self.minValue          = minValue
        self.maxValue          = max(minValue+0.01, maxValue)
        self.backgroundEnabled = backgroundEnabled
        self.externalLabels    = externalLabels
        self.internalLabels    = internalLabels
        self.backgroundColor   = backgroundColor
        self.foregroundColor   = foregroundColor
        self.valuePercent      = valuePercent
        self.maxValuePercent   = maxValuePercent
        self.formater          = formater
    }

    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            GeometryReader { geometryReader in
                ZStack(alignment: .leading) {
                    if self.backgroundEnabled {
                        Capsule()
                            .frame(height: 20)
                            .foregroundColor(self.backgroundColor) // 4
                    } else {
                        Capsule()
                            .stroke(self.backgroundColor)
                            .frame(height: 20)
                    }
                    
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .frame(width: progress(value: value,
                                                   width: geometryReader.size.width),
                                   height: 20)
                            .foregroundColor(self.foregroundColor)
                            .animation(.linear)
                        if internalLabels {
                            if valuePercent {
                                Text("\(percentageValue(value: value))%")
                                    .foregroundColor(.white) // 6
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                    .padding(.trailing, 10)
                            } else if let formater = self.formater {
                                Text(formater.string(from: value as NSNumber) ?? "")
                                    .foregroundColor(.white) // 6
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                    .padding(.trailing, 10)
                            } else {
                                Text(value.roundedString)
                                    .foregroundColor(.white) // 6
                                    .font(.system(size: 14))
                                    .fontWeight(.bold)
                                    .padding(.trailing, 10)
                            }
                        }
                    }
                }
            }
            
            if externalLabels {
                HStack {
                    if let formater = self.formater {
                        Text(formater.string(from: minValue as NSNumber) ?? "")
                            .fontWeight(.bold)
                    } else {
                        Text(minValue.roundedString)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    if maxValuePercent {
                        Text("\(percentageMaxValue(value: value) ?? 0)%")
                    } else if let formater = self.formater {
                        Text(formater.string(from: maxValue as NSNumber) ?? "")
                            .fontWeight(.bold)
                    } else {
                        Text(maxValue.roundedString)
                            .fontWeight(.bold)
                    }
                }
                .font(.system(size: 14))
            }
        }
        .frame(height: (externalLabels ? 40 : 20))
        
    }
    
    private func progress(value: Double,
                          width: CGFloat) -> CGFloat {
        let percentage = (value - minValue) / (maxValue - minValue)
        return width *  CGFloat(percentage)
    }
    private func percentageValue(value: Double) -> Int {
        Int(100 * (value - minValue) / (maxValue - minValue))
    }
    private func percentageMaxValue(value: Double) -> Int? {
        guard (value - minValue) != 0 else {
            return nil
        }
        return Int(100.0 * (maxValue - minValue) / (value - minValue))
    }
}

// MARK: - Progress circle
struct ProgressCircle: View {
    enum Stroke {
        case line
        case dotted
        
        func strokeStyle(lineWidth: CGFloat) -> StrokeStyle {
            switch self {
                case .line:
                    return StrokeStyle(lineWidth: lineWidth,
                                       lineCap: .round)
                case .dotted:
                    return StrokeStyle(lineWidth: lineWidth,
                                       lineCap: .round,
                                       dash: [12])
            }
        }
    }
    
    private let value             : Double
    private let minValue          : Double
    private let maxValue          : Double
    private let style             : Stroke
    private let backgroundEnabled : Bool
    private let labelsEnabled     : Bool
    private let backgroundColor   : Color
    private let foregroundColor   : Color
    private let lineWidth         : CGFloat
    
    init(value             : Double,
         minValue          : Double,
         maxValue          : Double,
         style             : Stroke  = .line,
         backgroundEnabled : Bool    = true,
         labelsEnabled     : Bool    = true,
         backgroundColor   : Color   = .secondary,
         foregroundColor   : Color   = .blue,
         lineWidth         : CGFloat = 10) {
        self.value             = value.clamp(low: minValue, high: maxValue)
        self.minValue          = minValue
        self.maxValue          = max(minValue+0.01, maxValue)
        self.style             = style
        self.backgroundEnabled = backgroundEnabled
        self.labelsEnabled     = labelsEnabled
        self.backgroundColor   = backgroundColor
        self.foregroundColor   = foregroundColor
        self.lineWidth         = lineWidth
    }
    
    var body: some View {
        ZStack {
            if backgroundEnabled {
                Circle()
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(backgroundColor)
            }
            
            Circle()
                .trim(from: 0, to: CGFloat((value - minValue) / (maxValue - minValue)))
                .stroke(style: style.strokeStyle(lineWidth: lineWidth))
                .foregroundColor(foregroundColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeIn)
            Text("\(percentage(value: value))%")
                .font(.system(size: 14))
                .fontWeight(.bold)
        }
    }
    
    private func percentage(value: Double) -> Int {
        Int(100 * (value - minValue) / (maxValue - minValue))
    }
}

// MARK: - Activity Indicator
struct ActivityIndicator: UIViewRepresentable {
    @Binding var shouldAnimate: Bool
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView,
                      context: Context) {
        if self.shouldAnimate {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

// MARK: - Tests & Previews

struct ProgressViews_Previews: PreviewProvider {
    static let itemSelection = [(label: "item 1", selected: true),
                                (label: "item 2", selected: true)]
    
    static var previews: some View {
        Group {
            Group {
                ProgressBar(value             : 40000,
                            minValue          : 0,
                            maxValue          : 100000,
                            backgroundEnabled : true,
                            externalLabels    : true,
                            internalLabels    : true,
                            backgroundColor   : .secondary,
                            foregroundColor   : .blue,
                            formater          : valueKilo€Formatter)
                    .previewLayout(PreviewLayout.fixed(width: 400, height: 100))
                    .padding()
                    .previewDisplayName("ProgressBar")
                
                ProgressBar(value             : 40000,
                            minValue          : 0,
                            maxValue          : 100000,
                            backgroundEnabled : true,
                            externalLabels    : true,
                            internalLabels    : true,
                            backgroundColor   : .secondary,
                            foregroundColor   : .blue,
                            valuePercent      : true,
                            formater          : valueKilo€Formatter)
                    .previewLayout(PreviewLayout.fixed(width: 400, height: 100))
                    .padding()
                    .previewDisplayName("ProgressBar")
                
                ProgressBar(value             : 40000,
                            minValue          : 0,
                            maxValue          : 100000,
                            backgroundEnabled : true,
                            externalLabels    : true,
                            internalLabels    : true,
                            backgroundColor   : .secondary,
                            foregroundColor   : .blue,
                            valuePercent      : false,
                            maxValuePercent   : true,
                            formater          : valueKilo€Formatter)
                    .previewLayout(PreviewLayout.fixed(width: 400, height: 100))
                    .padding()
                    .previewDisplayName("ProgressBar")
                
                ProgressCircle(value             : 85.0,
                               minValue          : 50.0,
                               maxValue          : 100.0,
                               backgroundEnabled : false,
                               backgroundColor   : .gray,
                               foregroundColor   : .blue,
                               lineWidth         : 10)
                    .previewLayout(PreviewLayout.fixed(width: 100, height: 100))
                    .padding()
                    .previewDisplayName("ProgressCircle")
                
                ActivityIndicator(shouldAnimate: .constant(true))
                    .previewLayout(PreviewLayout.fixed(width: 100, height: 100))
                    .padding()
                    .previewDisplayName("ActivityIndicator")
            }
        }
    }
}
