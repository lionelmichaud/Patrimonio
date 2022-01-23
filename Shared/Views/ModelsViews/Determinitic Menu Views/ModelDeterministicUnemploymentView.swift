//
//  ModelDeterministicUnemploymentView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI

struct ModelDeterministicUnemploymentView: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Chômage").font(.headline)) {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

//struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelDeterministicUnemploymentView()
//    }
//}
