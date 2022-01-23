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
            Text("A faire")
        }
    }
}

//struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelDeterministicUnemploymentView()
//    }
//}
