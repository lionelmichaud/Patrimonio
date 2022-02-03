//
//  VersionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/01/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Text View describing a Version

struct VersionText : View {
    var version: Version

    var body: some View {
        HStack {
            Text("v\(version.version ?? "")")
                .foregroundColor(.secondary)
            Text("du \(version.date.stringShortDate)")
                .foregroundColor(.secondary)
        }
    }
}

@ViewBuilder func headerWithVersion(label: String, version: Version) -> some View {
    HStack {
        Text(label)
        Spacer()
        Text("v\(version.version ?? "")")
            .foregroundColor(.secondary).textCase(.lowercase)
        Text("du \(version.date.stringShortDate)")
            .foregroundColor(.secondary).textCase(.lowercase)
    }.font(.headline)
}

// MARK: - Display & Edit the Version

struct VersionView: View {
    @Binding var version: Version
    @State private var showingEditSheet = false

    var body: some View {
        VersionDetailView(version: version)
            .onTapGesture(count   : 2,
                          perform : { showingEditSheet = true })
            .sheet(isPresented: $showingEditSheet) {
                VersionEditView(version: $version)
            }
    }
}

// MARK: - Display the Version

struct VersionDetailView: View {
    var version: Version

    var body: some View {
        Section(header: Text("Version").font(.headline)) {
            if let name = version.name {
                Text(name)
            }
            if let version = version.version {
                Text("v" + version)
            }
            if let date = version.date {
                Text(date.stringShortDate)
            }
            if let comment = version.comment {
                Text("Note: " + comment)
            }
        }
    }
}

// MARK: - Edit the Version

struct VersionEditView : View {
    @Binding private var version: Version
    @Environment(\.presentationMode) var presentationMode
    @State var name    : String
    @State var comment : String
    @State var major   : Int
    @State var minor   : Int
    @State var patch   : Int

    init(version: Binding<Version>) {
        _version = version
        _name    = State(initialValue : version.wrappedValue.name ?? "")
        _major   = State(initialValue : version.wrappedValue.major ?? 0)
        _minor   = State(initialValue : version.wrappedValue.minor ?? 0)
        _patch   = State(initialValue : version.wrappedValue.patch ?? 0)
        _comment = State(initialValue : version.wrappedValue.comment ?? "")
    }

    private var toolBar: some View {
        HStack {
            Button(action : { self.presentationMode.wrappedValue.dismiss() },
                   label  : { Text("Annuler") })
                .capsuleButtonStyle()
            Spacer()
            Text("Version").font(.title).fontWeight(.bold)
            Spacer()
            Button(action : updateVersion,
                   label  : { Text("OK") })
                .capsuleButtonStyle()
                .disabled(!formIsValid())
        }
        .padding(.horizontal)
        .padding(.top)
    }

    var body: some View {
        VStack {
            /// Barre de titre et boutons
            toolBar
            /// Formulaire
            Form {
                VStack {
                    HStack {
                        Stepper(value: $major, in: 0 ... 100) {
                            HStack {
                                Text("Majeur")
                                Spacer()
                                Text("\(major)").foregroundColor(.secondary)
                            }
                        }.padding(.trailing)
                        Stepper(value: $minor, in: 0 ... 100) {
                            HStack {
                                Text("Mineur")
                                Spacer()
                                Text("\(minor)").foregroundColor(.secondary)
                            }
                        }.padding(.trailing)
                        Stepper(value: $patch, in: 0 ... 100) {
                            HStack {
                                Text("Patch")
                                Spacer()
                                Text("\(patch)").foregroundColor(.secondary)
                            }
                        }
                    }
                    TextField("nom", text: $name)
                    TextField("commentaire", text: $comment)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        return true
    }

    private func updateVersion() {
        version = Version().dated(CalendarCst.now)
        version = version.versioned(major: major, minor: minor, patch: patch)
        if name != "" {
            version = version.named(name)
        }
        if comment != "" {
            version = version.commented(with: comment)
        }
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct VersionView_Previews: PreviewProvider {
    static let version = Version()
        .named("Nom de la version")
        .versioned(major: 1, minor: 2, patch: 3)
        .dated(CalendarCst.now)
        .commented(with: "Commentaire de version")

    static var previews: some View {
        Form {
            VersionView(version: .constant(version))
        }
        .previewLayout(.fixed(width: 500, height: 300))
    }
}
