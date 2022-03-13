//
//  VersionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/01/2022.
//

import SwiftUI
import AppFoundation

@ViewBuilder public func headerWithVersion(label: String, version: Version) -> some View {
    HStack {
        Text(label)
        Spacer()
        Text("Version v\(version.version ?? "")")
            .foregroundColor(.secondary).textCase(.lowercase)
        Text("du \(version.date.stringShortDate)")
            .foregroundColor(.secondary).textCase(.lowercase)
    }.font(.headline)
}

// MARK: - Display & Edit the Version from inside a Form

public struct VersionEditableViewInForm: View {
    @Binding
    private var version: Version
    @State
    private var showingEditSheet = false

    public var body: some View {
        VersionVStackView(version: version, withDetails: true)
            .foregroundColor(.blue)
            .onTapGesture(count   : 1,
                          perform : { showingEditSheet = true })
            .sheet(isPresented: $showingEditSheet) {
                VersionEditSheet(version: $version)
            }
    }
    
    public init(version: Binding<Version>) {
        self._version = version
    }
}

// MARK: - Display the Version as a VStack

public struct VersionVStackView : View {
    private var version     : Version
    private var withDetails : Bool
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Version: ").bold() + Text("v\(version.version ?? "") du \(version.date.stringShortDate)")
                if let name = version.name, withDetails {
                    HStack {
                        Text("Nom: ").bold() + Text(name)
                    }.padding(.leading)
                }
            }
            if let comment = version.comment, withDetails {
                HStack {
                    Divider()
                    Text("Note: ").bold() + Text(comment)
                }
            }
        }
    }
    
    public init(version     : Version,
                withDetails : Bool) {
        self.version = version
        self.withDetails = withDetails
    }
}

// MARK: - Display the Version as a Section

public struct VersionSectionView: View {
    private var version: Version

    public var body: some View {
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
    
    public init(version: Version) {
        self.version = version
    }
}

// MARK: - Display & Edit the Version from inside another View (not a Form/List)

public struct VersionEditableView: View {
    @Binding
    private var version : Version
    @State
    private var showingEditSheet = false
    
    public var body: some View {
        VersionListView(version: version, withDetails: true)
            .frame(maxHeight: version.comment == nil ? 60 : 120)
            .foregroundColor(.blue)
            .onTapGesture(count   : 1,
                          perform : { showingEditSheet = true })
            .sheet(isPresented: $showingEditSheet) {
                VersionEditSheet(version: $version)
            }
    }
    
    public init(version: Binding<Version>) {
        self._version = version
    }
}

// MARK: - Display the Version as a List

public struct VersionListView : View {
    private var version     : Version
    private var withDetails : Bool
    
    public var body: some View {
        List {
            HStack {
                Text("Version: ").bold() + Text("v\(version.version ?? "") du \(version.date.stringShortDate)")
                if let name = version.name, withDetails {
                    HStack {
                        Text("Nom: ").bold() + Text(name)
                    }.padding(.leading)
                }
            }
            if let comment = version.comment, withDetails {
                HStack {
                    Divider()
                    Text("Note: ").bold() + Text(comment)
                }
            }
        }
    }
    
    public init(version     : Version,
                withDetails : Bool) {
        self.version = version
        self.withDetails = withDetails
    }
}

// MARK: - Sheet to Edit the Version

public struct VersionEditSheet : View {
    @Binding private var version: Version
    @Environment(\.presentationMode) var presentationMode
    @State private var name    : String
    @State private var comment : String
    @State private var major   : Int
    @State private var minor   : Int
    @State private var patch   : Int

    public init(version: Binding<Version>) {
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

    public var body: some View {
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
            VersionEditableViewInForm(version: .constant(version))
        }
        .previewLayout(.fixed(width: 500, height: 300))
    }
}
