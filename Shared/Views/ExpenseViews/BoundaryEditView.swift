//
//  BoundaryEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import DateBoundary
import HelpersView

// MARK: - View Model for BoundaryEditView

struct DateBoundaryViewModel: Equatable {
    
    // MARK: - Properties
    
    var fixedYear       : Int
    var event           : LifeEvent
    var isLinkedToEvent : Bool
    var name            : String
    var group           : GroupOfPersons
    var isLinkedToGroup : Bool
    var order           : SoonestLatest
    
    // MARK: - Computed Properties
    
    // vérifier qu'il est possible de calculer l'année de la borne temporelle
//    var boundaryYearIsComputable: Bool {
//        if isLinkedToEvent {
//            if isLinkedToGroup {
//                return true
//            } else {
//                return name != ""
//            }
//        } else {
//            return true
//        }
//    }
    
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var year  : Int? {
        if isLinkedToEvent {
            // la borne temporelle est accrochée à un événement
            if isLinkedToGroup {
                // l'événement est accroché à un groupe
                // construire un tableau des membres du groupe
                return DateBoundary.yearOf(lifeEvent : event,
                                           for       : group,
                                           order     : order)
                
            } else {
                // l'événement est accroché à une personne
                // rechercher la personne
                if let year = DateBoundary.yearOf(lifeEvent: event,
                                                  for: name) {
                    // rechercher l'année de l'événement pour cette personne
                    return year
                } else {
                    // on ne trouve pas le nom de la personne dans la famille
                    return nil
                }
            }
            
        } else {
            // pas d'événement, la date est fixe
            return fixedYear
        }
    }
    
    // construire l'objet de type DateBoundary correspondant au ViewModel
    var dateBoundary: DateBoundary {
        var _event : LifeEvent?
        var _name  : String?
        var _group : GroupOfPersons?
        var _order : SoonestLatest?
        
        if isLinkedToEvent {
            _event = self.event
            if isLinkedToGroup {
                _name  = nil
                _group = self.group
                _order = self.order
            } else {
                _name  = self.name
                _group = nil
                _order = nil
            }
            
        } else {
            _event = nil
            _name  = nil
            _group = nil
            _order = nil
        }
        return DateBoundary(fixedYear : fixedYear,
                            event     : _event,
                            name      : _name,
                            group     : _group,
                            order     : _order)
    }
    
    // MARK: - Initializers of ViewModel from Model
    
    internal init(from dateBoundary: DateBoundary) {
        self.fixedYear       = dateBoundary.fixedYear
        self.event           = dateBoundary.event ?? .deces
        self.isLinkedToEvent = dateBoundary.event != nil
        self.name            = dateBoundary.name ?? ""
        self.group           = dateBoundary.group ?? .allAdults
        self.isLinkedToGroup = dateBoundary.group != nil
        self.order           = dateBoundary.order ?? .soonest
    }
}

extension DateBoundaryViewModel: CustomStringConvertible {
    var description : String {
        guard let year = self.year else {
            return "indéfini"
        }
        var description: String = ""

        if isLinkedToEvent {
            description = event.displayString + " de "
            if isLinkedToGroup {
                description += group.displayString + (order == .soonest ? " (-)" : " (+)")

            } else {
                description += name
            }
            return description + ": " + String(year)

        } else {
            return String(year)
        }
    }
}

extension DateBoundaryViewModel: ValidableP {
    /// Retourne True si une date peut être calculée à partir de la définition de l'objet
    var isValid: Bool {
        self.dateBoundary.isValid
    }
}
    
// MARK: - View

struct BoundaryEditView: View {

    // MARK: - Properties

    let label                             : String
    @Binding var boundaryVM               : DateBoundaryViewModel
    @State private var presentGroupPicker : Bool = false // pour affichage local
    
    // MARK: - Computed Properties
    
    var body: some View {
        Section {
            /// la date est-elle liée à un événement ?
            Toggle(isOn: $boundaryVM.isLinkedToEvent) { Text("Associé à un événement") }
                .onChange(of: boundaryVM.isLinkedToEvent, perform: updateIsLinkedToEvent)

            if boundaryVM.isLinkedToEvent {
                Group {
                    /// la date est liée à un événement:
                    /// choisir le type d'événement
                    CasePicker(pickedCase: $boundaryVM.event, label: "Nature de cet événement")
                        .onChange(of: boundaryVM.event, perform: updateGroup)

                    /// choisir à quoi associer l'événement: personne ou groupe
                    Toggle(isOn: $boundaryVM.isLinkedToGroup) { Text("Associer cet évenement à un groupe") }
                        .onChange(of: boundaryVM.isLinkedToGroup, perform: updateGroup)

                    if boundaryVM.isLinkedToGroup {
                        Group {
                            /// choisir le type de groupe si nécessaire
                            if presentGroupPicker {
                                CasePicker(pickedCase: $boundaryVM.group, label: "Groupe associé")
                            } else {
                                LabeledText(label: "Groupe associé", text: boundaryVM.group.displayString).foregroundColor(.secondary)
                            }
                            CasePicker(pickedCase: $boundaryVM.order, label: "Ordre")
                        }.padding(.leading)

                    } else {
                        /// choisir la personne
                        PersonPickerView(name: $boundaryVM.name, event: boundaryVM.event)
                    }
                    /// afficher la date résultante
                    if let boundaryYear = self.boundaryYear {
                        IntegerView(label: "\(label)", integer: boundaryYear).foregroundColor(.secondary)
                    } else {
                        Text("Choisir un événement et la personne ou le groupe associé")
                            .foregroundColor(.red)
                    }
                }.padding(.leading)

            } else {
                /// choisir une date absolue
                IntegerEditView(label    : "\(label) (année inclue)",
                                integer  : $boundaryVM.fixedYear,
                                validity : .poz)
            }
        } header: {
            Text("\(label) de période")
        }
    }
    
    private var isValid: Bool {
        boundaryVM.isValid
    }

    private var boundaryYear: Int? {
        boundaryVM.year
    }

    // MARK: - Initializers
    
    init(label    : String,
         boundary : Binding<DateBoundaryViewModel?>) {
        self.label  = label
        _boundaryVM = boundary ?? DateBoundaryViewModel(from: DateBoundary.empty)
    }
    init(label    : String,
         boundary : Binding<DateBoundaryViewModel>) {
        self.label  = label
        _boundaryVM = boundary
    }
    
    // MARK: - Methods
    
    func updateIsLinkedToEvent(newIsLinkedToEvent: Bool) {
        if !newIsLinkedToEvent {
            boundaryVM.fixedYear = CalendarCst.thisYear
        }
    }
    
    func updateGroup(isAssociatedToGroup: Bool) {
        if isAssociatedToGroup {
            if boundaryVM.event.isAdultEvent {
                boundaryVM.group   = .allAdults
                presentGroupPicker = false
                
            } else if boundaryVM.event.isChildEvent {
                boundaryVM.group   = .allChildrens
                presentGroupPicker = false
                
            } else {
                presentGroupPicker = true
            }
        }
    }
    
    func updateGroup(newEvent: LifeEvent) {
        if boundaryVM.isLinkedToGroup {
            if newEvent.isAdultEvent {
                boundaryVM.group   = .allAdults
                presentGroupPicker = false
                
            } else if newEvent.isChildEvent {
                boundaryVM.group   = .allChildrens
                presentGroupPicker = false
                
            } else {
                presentGroupPicker = true
            }
        }
    }
}

// MARK: - View

struct BoundaryEditView2: View {

    // MARK: - Properties

    let label                             : String
    @Binding var boundary                 : DateBoundary
    @State private var presentGroupPicker : Bool = false // pour affichage local
    private var boundaryVM : Binding<DateBoundaryViewModel> {
        Binding(
            get: {
                DateBoundaryViewModel(from: self.boundary)
            },
            set: {
                self.boundary = $0.dateBoundary
            }
        )
    }

    // MARK: - Computed Properties

    var body: some View {
        Section {
            /// la date est-elle liée à un événement ?
            Toggle(isOn: boundaryVM.isLinkedToEvent.animation()) { Text("Associé à un événement") }
                .onChange(of: boundaryVM.wrappedValue.isLinkedToEvent, perform: updateIsLinkedToEvent)

            if boundaryVM.wrappedValue.isLinkedToEvent {
                Group {
                    /// la date est liée à un événement:
                    /// choisir le type d'événement
                    CasePicker(pickedCase: boundaryVM.event, label: "Nature de cet événement")
                        .onChange(of: boundaryVM.wrappedValue.event, perform: updateGroup)

                    /// choisir à quoi associer l'événement: personne ou groupe
                    Toggle(isOn: boundaryVM.isLinkedToGroup.animation()) { Text("Associer cet évenement à un groupe") }
                        .onChange(of: boundaryVM.wrappedValue.isLinkedToGroup, perform: updateGroup)

                    if boundaryVM.wrappedValue.isLinkedToGroup {
                        Group {
                            /// choisir le type de groupe si nécessaire
                            if presentGroupPicker {
                                CasePicker(pickedCase: boundaryVM.group, label: "Groupe associé")
                            } else {
                                LabeledText(label: "Groupe associé", text: boundaryVM.wrappedValue.group.displayString).foregroundColor(.secondary)
                            }
                            CasePicker(pickedCase: boundaryVM.order, label: "Ordre")
                        }.padding(.leading)

                    } else {
                        /// choisir la personne
                        PersonPickerView(name: boundaryVM.name, event: boundaryVM.wrappedValue.event)
                    }
                    /// afficher la date résultante
                    if let boundaryYear = self.boundaryYear {
                        IntegerView(label: "\(label) (année inclue)", integer: boundaryYear).foregroundColor(.secondary)
                    } else {
                        Text("Choisir un événement et la personne ou le groupe associé")
                            .foregroundColor(.red)
                    }
                }.padding(.leading)

            } else {
                /// choisir une date absolue
                IntegerEditView(label    : "\(label) (année inclue)",
                                integer  : boundaryVM.fixedYear,
                                validity : .poz)
            }
        } header: {
            Text("\(label) de période")
        }
    }

    private var isValid: Bool {
        boundaryVM.wrappedValue.isValid
    }

    var boundaryYear: Int? {
        boundaryVM.wrappedValue.year
    }

    // MARK: - Initializers

    init(label    : String,
         boundary : Binding<DateBoundary?>) {
        self.label  = label
        _boundary = boundary ?? DateBoundary.empty
    }
    init(label    : String,
         boundary : Binding<DateBoundary>) {
        self.label  = label
        _boundary = boundary
    }

    // MARK: - Methods

    func updateIsLinkedToEvent(newIsLinkedToEvent: Bool) {
        if !newIsLinkedToEvent {
            boundaryVM.wrappedValue.fixedYear = CalendarCst.thisYear
        }
    }

    func updateGroup(isAssociatedToGroup: Bool) {
        if isAssociatedToGroup {
            if boundaryVM.wrappedValue.event.isAdultEvent {
                boundaryVM.wrappedValue.group   = .allAdults
                presentGroupPicker = false

            } else if boundaryVM.wrappedValue.event.isChildEvent {
                boundaryVM.wrappedValue.group   = .allChildrens
                presentGroupPicker = false

            } else {
                presentGroupPicker = true
            }
        }
    }

    func updateGroup(newEvent: LifeEvent) {
        if boundaryVM.wrappedValue.isLinkedToGroup {
            if newEvent.isAdultEvent {
                boundaryVM.wrappedValue.group   = .allAdults
                presentGroupPicker = false

            } else if newEvent.isChildEvent {
                boundaryVM.wrappedValue.group   = .allChildrens
                presentGroupPicker = false

            } else {
                presentGroupPicker = true
            }
        }
    }
}

// MARK: - View

struct BoundaryEditNavigationView: View {

    // MARK: - Properties

    let label                             : String
    let updateDependenciesToModel         : () -> Void
    @Transac var boundary                 : DateBoundary

    @State private var presentGroupPicker : Bool = false // pour affichage local

    private var boundaryVM : Binding<DateBoundaryViewModel> {
        Binding(
            get: {
                DateBoundaryViewModel(from: self.boundary)
            },
            set: {
                self.boundary = $0.dateBoundary
            }
        )
    }

    // MARK: - Computed Properties

    var body: some View {
        Form {
            /// la date est-elle liée à un événement ?
            Toggle(isOn: boundaryVM.isLinkedToEvent.animation()) { Text("Associé à un événement") }
                .onChange(of: boundaryVM.wrappedValue.isLinkedToEvent, perform: updateIsLinkedToEvent)

            if boundaryVM.wrappedValue.isLinkedToEvent {
                Group {
                    /// la date est liée à un événement:
                    /// choisir le type d'événement
                    CasePicker(pickedCase: boundaryVM.event, label: "Nature de cet événement")
                        .onChange(of: boundaryVM.wrappedValue.event, perform: updateGroup)

                    /// choisir à quoi associer l'événement: personne ou groupe
                    Toggle(isOn: boundaryVM.isLinkedToGroup.animation()) { Text("Associer cet évenement à un groupe") }
                        .onChange(of: boundaryVM.wrappedValue.isLinkedToGroup, perform: updateGroup)

                    if boundaryVM.wrappedValue.isLinkedToGroup {
                        Group {
                            /// choisir le type de groupe si nécessaire
                            if presentGroupPicker {
                                CasePicker(pickedCase: boundaryVM.group, label: "Groupe associé")
                            } else {
                                LabeledText(label: "Groupe associé", text: boundaryVM.wrappedValue.group.displayString).foregroundColor(.secondary)
                            }
                            CasePicker(pickedCase: boundaryVM.order, label: "Ordre")
                        }.padding(.leading)

                    } else {
                        /// choisir la personne
                        PersonPickerView(name: boundaryVM.name, event: boundaryVM.wrappedValue.event)
                    }
                    /// afficher la date résultante
                    if let boundaryYear = self.boundaryYear {
                        IntegerView(label: "\(label) (année inclue)", integer: boundaryYear).foregroundColor(.secondary)
                    } else {
                        Text("Choisir un événement et la personne ou le groupe associé")
                            .foregroundColor(.red)
                    }
                }.padding(.leading)

            } else {
                /// choisir une date absolue
                IntegerEditView(label    : "\(label) (année inclue)",
                                integer  : boundaryVM.fixedYear,
                                validity : .poz)
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("\(label) de période")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $boundary,
                             isValid                   : isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }

    private var isValid: Bool {
        boundaryVM.wrappedValue.isValid
    }

    var boundaryYear: Int? {
        boundaryVM.wrappedValue.year
    }

    // MARK: - Initializers

    init(label    : String,
         boundary : Transac<DateBoundary>,
         updateDependenciesToModel : @escaping () -> Void) {
        self.label  = label
        _boundary = boundary
        self.updateDependenciesToModel = updateDependenciesToModel
    }

    // MARK: - Methods

    func updateIsLinkedToEvent(newIsLinkedToEvent: Bool) {
        if !newIsLinkedToEvent {
            boundaryVM.wrappedValue.fixedYear = CalendarCst.thisYear
        }
    }

    func updateGroup(isAssociatedToGroup: Bool) {
        if isAssociatedToGroup {
            if boundaryVM.wrappedValue.event.isAdultEvent {
                boundaryVM.wrappedValue.group   = .allAdults
                presentGroupPicker = false

            } else if boundaryVM.wrappedValue.event.isChildEvent {
                boundaryVM.wrappedValue.group   = .allChildrens
                presentGroupPicker = false

            } else {
                presentGroupPicker = true
            }
        }
    }

    func updateGroup(newEvent: LifeEvent) {
        if boundaryVM.wrappedValue.isLinkedToGroup {
            if newEvent.isAdultEvent {
                boundaryVM.wrappedValue.group   = .allAdults
                presentGroupPicker = false

            } else if newEvent.isChildEvent {
                boundaryVM.wrappedValue.group   = .allChildrens
                presentGroupPicker = false

            } else {
                presentGroupPicker = true
            }
        }
    }
}
