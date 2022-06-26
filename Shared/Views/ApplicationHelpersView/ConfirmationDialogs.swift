//
//  ConfirmationDialogs.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2022.
//

import SwiftUI

struct ButtonConfirmImportFiles: View {
    @State private var isShowingDialog = false
    var title: String
    var body: some View {
        Button("Empty Trash") {
            isShowingDialog = true
        }
        .confirmationDialog(
            title,
            isPresented: $isShowingDialog
        ) {
            Button("Empty Trash", role: .destructive) {
                // Handle empty trash action.
            }
            Button("Cancel", role: .cancel) {
                isShowingDialog = false
            }
        } message: {
            Text("You cannot undo this action.")
        }
    }
}

struct ConfirmEraseItems: View {
    @State private var isShowingDialog = false
    var title: String
    var body: some View {
        Button("Empty Trash") {
            isShowingDialog = true
        }
        .confirmationDialog(
            title,
            isPresented: $isShowingDialog
        ) {
            Button("Empty Trash", role: .destructive) {
                // Handle empty trash action.
            }
            Button("Cancel", role: .cancel) {
                isShowingDialog = false
            }
        } message: {
            Text("You cannot undo this action.")
        }
    }
}
