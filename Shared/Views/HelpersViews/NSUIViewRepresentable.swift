//
//  File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 28/04/2021.
//

import Foundation
import SwiftUI

#if os(iOS) || os(tvOS)
typealias NSUIViewRepresentable = UIViewRepresentable
#else
typealias NSUIViewRepresentable = NSViewRepresentable
#endif
