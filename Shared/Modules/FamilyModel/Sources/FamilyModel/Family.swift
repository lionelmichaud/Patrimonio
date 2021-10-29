import Foundation
import AppFoundation
import Files
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git
import ModelEnvironment
import Ownership
import DateBoundary
import LifeExpense
import PersonModel
import PatrimoineModel

// MARK: - Class Family: la Famille, ses membres, leurs actifs et leurs revenus

/// la Famille, ses membres, leurs actifs et leurs revenus
public final class Family: ObservableObject {
    
    // MARK: - Properties
    
    // structure de la famille
    @Published private(set) public var members = PersistableArrayOfPerson()
    // nombre d'enfant encore en vie dans la famille à la date du jour
    public var nbOfLivingChildren: Int { // computed
        var nb = 0
        for person in members.items where person is Child {
            if person.isAlive(atEndOf: Date.now.year) { nb += 1 }
        }
        return nb
    }
    public var adults  : [Adult] { // computed
        members.items.compactMap {$0 as? Adult}
    }
    public var children: [Child] { // computed
        members.items.compactMap {$0 as? Child}
    }
    
    public var isModified: Bool { // computed
        members.isModified
    }
    
    // MARK: - Initializers
    
    /// Initialiser à vide
    /// - Note: Utilisé à la création de l'App, avant que le dossier n'ait été sélectionné
    public init() {    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    /// - Throws: en cas d'échec de lecture des données
    public convenience init(fromFolder folder: Folder) throws {
        self.init()
        members  = try PersistableArrayOfPerson(fromFolder: folder)
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le `bundle`
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameters:
    ///   - bundle: le bundle où se trouve le fichier JSON à utiliser
    ///   - model: modèle à utiliser pour initialiser les membres de la famille
    /// - Throws: en cas d'échec de lecture des données
    public convenience init(fromBundle bundle : Bundle,
                            using model       : Model) throws {
        self.init()
        members  = try PersistableArrayOfPerson(fromBundle: bundle,
                                                using     : model)
    }
    
    // MARK: - Methodes
    
    /// lire à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - model: modèle à utiliser pour initialiser les membres de la famille
    /// - Throws: en cas d'échec de lecture des données
    public func loadFromJSON(fromFolder folder : Folder,
                             using model       : Model) throws {
        members  = try PersistableArrayOfPerson(fromFolder: folder,
                                                using     : model)
    }
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        try members.saveAsJSON(to: folder)
    }
    
    // revenus
    public func workNetIncome(using model: Model) -> Double { // computed
        var netIcome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult { netIcome += adult.workNetIncome(using: model) }
        }
        return netIcome
    }
    public func workTaxableIncome(using model: Model) -> Double { // computed
        var taxableIncome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult { taxableIncome += adult.workTaxableIncome(using: model) }
        }
        return taxableIncome
    }
    // coefficient familial à la date du jour
    public func familyQuotient(using model: Model) -> Double { // computed
        try! model.fiscalModel.incomeTaxes.familyQuotient(nbAdults   : nbOfAdults,
                                                          nbChildren : nbOfLivingChildren)
    }
    // impots à la date du jour
    public func irpp(using model: Model) -> Double { // computed
        try! model.fiscalModel.incomeTaxes.irpp(taxableIncome : workTaxableIncome(using: model),
                                                nbAdults      : nbOfAdults,
                                                nbChildren    : nbOfLivingChildren).amount
    }
    /// Rend la liste des enfants vivants
    /// - Parameter year: année
    /// - Warning: Vérifie que l'enfant est vivant
    public func chidldrenAlive(atEndOf year: Int) -> [Child]? {
        members.items
            .filter { person in
                person is Child && person.isAlive(atEndOf: year)
            }
            .map { person in
                person as! Child
            }
    }
    
    /// Retourne la liste des noms des personnes décédées dans l'année
    /// - Parameter year: année où l'on recherche des décès
    /// - Returns: liste des personnes décédées dans l'année
    public func deceasedAdults(during year: Int) -> [String] {
        members.items
            .sorted(by: \.birthDate)
            .compactMap { member in
                if member is Adult && member.isDeceased(during: year) {
                    // un décès est survenu
                    return member.displayName
                } else {
                    return nil
                }
            }
    }
    
    /// Revenus du tavail cumulés de la famille durant l'année
    /// - Parameter year: année
    /// - Parameter netIncome: revenu net de charges et d'assurance (à vivre)
    /// - Parameter taxableIncome: Revenus du tavail cumulés imposable à l'IRPP
    public func income(during year : Int,
                       using model : Model)
    -> (netIncome     : Double,
        taxableIncome : Double) {
        var totalNetIncome     : Double = 0.0
        var totalTaxableIncome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult {
                let income = adult.workIncome(during: year, using: model)
                totalNetIncome     += income.net
                totalTaxableIncome += income.taxableIrpp
            }
        }
        return (totalNetIncome, totalTaxableIncome)
    }
    
    /// Quotient familiale durant l'année
    /// - Parameter year: année
    public func familyQuotient (during year : Int,
                                using model : Model) -> Double {
        try! model.fiscalModel.incomeTaxes.familyQuotient(nbAdults   : nbOfAdultAlive(atEndOf: year),
                                                          nbChildren : nbOfFiscalChildren(during: year))
    }
    
    /// IRPP sur les revenus du travail de la famille
    /// - Parameter year: année
    public func irpp (for year    : Int,
                      using model : Model) -> Double {
        try! model.fiscalModel.incomeTaxes.irpp(
            // FIXME: A CORRIGER pour prendre en compte tous les revenus imposable
            taxableIncome : income(during : year, using: model).taxableIncome, // A CORRIGER
            nbAdults      : nbOfAdultAlive(atEndOf    : year),
            nbChildren    : nbOfFiscalChildren(during : year))
            .amount
    }
    
    /// Pensions de retraite cumulées de la famille durant l'année
    /// - Parameter year: année
    /// - Returns: Pensions de retraite cumulées brutes
    public func pension(during year   : Int,
                        withReversion : Bool = true,
                        using model   : Model) -> Double {
        var pension = 0.0
        for person in members.items {
            if let adult = person as? Adult {
                pension += adult.pension(during        : year,
                                         withReversion : withReversion,
                                         using         : model).brut
            }
        }
        return pension
    }
    
    /// Mettre à jour le nombre d'enfant de chaque parent de la famille
    public func updateChildrenNumber() {
        for member in members.items { // pour chaque membre de la famille
            if let adult = member as? Adult { // si c'est un parent
                adult.gaveBirthTo(children: nbOfBornChildren) // mettre à jour le nombre d'enfant
            }
        }
    }
    
    /// Actualiser les propriétés d'une personne à partir des valeurs modifiées
    /// des paramètres du modèle (valeur déterministes modifiées par l'utilisateur).
    /// Mémoriser l'existence d'une modification pour ne sauvegarde ultérieure.
    public func updateMembersDterministicValues(
        _ menLifeExpectation    : Int,
        _ womenLifeExpectation  : Int,
        _ nbOfYearsOfdependency : Int,
        _ ageMinimumLegal       : Int,
        _ ageMinimumAGIRC       : Int
    ) {
        members.items.forEach { member in
            member.updateMembersDterministicValues(
                menLifeExpectation,
                womenLifeExpectation,
                nbOfYearsOfdependency,
                ageMinimumLegal,
                ageMinimumAGIRC)
        }
        // exécuter la transition
        members.persistenceSM.process(event: .onModify)
    }
    
    /// Ajouter un membre à la famille
    /// - Parameter person: personne à ajouter
    public func addMember(_ person: Person) {
        // ajouter le nouveau membre
        members.add(person)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
    }
    
    public func deleteMembers(at offsets: IndexSet) {
        // retirer les membres
        members.delete(at: offsets)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
    }
    
    public func moveMembers(from indexes: IndexSet, to destination: Int) {
        self.members.move(from: indexes, to: destination)
    }
    
    public func aMemberIsModified() {
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        self.updateChildrenNumber()
        
        // exécuter la transition
        members.persistenceSM.process(event: .onModify)
    }
    
    /// Réinitialiser les prioriétés aléatoires des membres et des dépenses
    public func nextRandomProperties(using model: Model) {
        // Réinitialiser les prioriété aléatoires des membres
        members.items.forEach {
            $0.nextRandomProperties(using: model)
        }
    }
    
    public func currentRandomProperties() -> DictionaryOfAdultRandomProperties {
        var dicoOfAdultsRandomProperties = DictionaryOfAdultRandomProperties()
        members.items.forEach {
            if let adult = $0 as? Adult {
                dicoOfAdultsRandomProperties[adult.displayName] = AdultRandomProperties(ageOfDeath          : adult.ageOfDeath,
                                                                                        nbOfYearOfDependency: adult.nbOfYearOfDependency)
            }
        }
        return dicoOfAdultsRandomProperties
        
    }
    
    public func nextRun(using model: Model) -> DictionaryOfAdultRandomProperties {
        // Réinitialiser les prioriété aléatoires des membres
        members.items.forEach {
            $0.nextRandomProperties(using: model)
        }
        return currentRandomProperties()
    }
}

extension Family: CustomStringConvertible {
    public var description: String {
        var desc =
            """

        FAMILLE:
        - Nombre d'adultes dans ls famille: \(nbOfAdults)
        - Nombre d'enfants nés dans la famille: \(nbOfBornChildren)
        - MEMBRES DE LA FAMILLE:
        """
        members.items.forEach { member in
            desc += String(describing: member).withPrefixedSplittedLines("  ")
        }
        desc += "\n"
        
        return desc
    }
}

extension Family: PersonAgeProviderP {
    public func ageOf(_ name: String, _ year: Int) -> Int {
        let person = member(withName: name)
        return person?.age(atEndOf: year) ?? -1
    }
}

extension Family: PersonEventYearProviderP {
    public func yearOf(lifeEvent : LifeEvent,
                       for name  : String) -> Int? {
        // rechercher la personne
        if let person = member(withName: name) {
            // rechercher l'année de l'événement pour cette personne
            return person.yearOf(event: lifeEvent)
        } else {
            // on ne trouve pas le nom de la personne dans la famille
            return nil
        }
    }
    
    public func yearOf(lifeEvent : LifeEvent,
                       for group : GroupOfPersons,
                       order     : SoonestLatest) -> Int? {
        var persons: [Person]?
        switch group {
            case .allAdults:
                persons = adults
                
            case .allChildrens:
                persons = children
                
            case .allPersons:
                persons = members.items
        }
        if let years = persons?.map({ $0.yearOf(event: lifeEvent)! }) {
            switch order {
                case .soonest:
                    return years.min()
                case .latest:
                    return years.max()
            }
        } else {
            return nil
        }
    }
}

extension Family: MembersCountProviderP {
    // nombre d'enfant nés dans la famille
    public var nbOfBornChildren: Int { // computed
        var nb = 0
        for person in members.items where person is Child {nb += 1}
        return nb
    }
    
    public var nbOfAdults: Int { // computed
        var nb = 0
        for person in members.items where person is Adult {nb += 1}
        return nb
    }
    
    /// Nombre d'adulte vivant à la fin de l'année
    /// - Parameter year: année
    public func nbOfAdultAlive(atEndOf year: Int) -> Int {
        members.items.reduce(0) { (result, person) in
            result + ((person is Adult && person.isAlive(atEndOf: year)) ? 1 : 0)
        }
    }
    
    /// Nombre d'enfant vivant à la fin de l'année
    /// - Parameter year: année considérée
    public func nbOfChildrenAlive(atEndOf year: Int) -> Int {
        members.items
            .reduce(0) { (result, person) in
                result + ((person is Child && person.isAlive(atEndOf: year)) ? 1 : 0)
            }
    }
    
    /// Nombre d'enfant dans le foyer fiscal
    /// - Parameter year: année d'imposition
    /// - Note: [service-public.fr](https://www.service-public.fr/particuliers/vosdroits/F3085)
    public func nbOfFiscalChildren(during year: Int) -> Int {
        members.items
            .reduce(0) { (result, person) in
                guard let child = person as? Child else {
                    return result
                }
                let isFiscalementACharge = child.isFiscalyDependant(during: year)
                return result + (isFiscalementACharge ? 1 : 0)
            }
    }
}

extension Family: FiscalHouseholdSumatorP {
    public func sum(atEndOf year : Int,
                    memberValue  : (String) -> Double) -> Double {
        /// pour: adultes + enfants fiscalement dépendants
        var cumulatedvalue: Double = 0.0
        
        for member in members.items {
            var toBeConsidered : Bool
            
            if member is Adult {
                toBeConsidered = member.isAlive(atEndOf: year)
                
            } else if member is Child {
                let child = member as! Child
                toBeConsidered = child.isFiscalyDependant(during: year)
                
            } else {
                toBeConsidered = false
            }
            
            if toBeConsidered {
                cumulatedvalue +=
                    memberValue(member.displayName)
            }
        }
        return cumulatedvalue
    }
}

extension Family: AdultSpouseProviderP {
    /// Rend l'époux d'un adult de la famille (s'il existe), qu'il soit vivant où décédé
    /// - Parameter member: membre adult de la famille
    /// - Returns: époux  (s'il existe)
    /// - Warning: Ne vérifie pas que l'époux est vivant
    public func spouseOf(_ member: Adult) -> Adult? {
        return members.items
            .first { person in
                person is Adult && person != member
            } as? Adult
    }
    
    public func spouseNameOf(_ memberName: String) -> String? {
        return members.items
            .first { person in
                person is Adult && person.displayName != memberName
            }?
            .displayName
    }
}

extension Family: MembersNameProviderP {
    public var membersName: [String] {
        members.items
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
    public var adultsName: [String] {
        adults
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
    public var childrenName: [String] {
        children
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
    public func childrenAliveName(atEndOf year: Int) -> [String]? {
        chidldrenAlive(atEndOf: year)?.map { $0.displayName }
    }
}

extension Family: MembersProviderP {
    /// Trouver le membre de la famille avec le displayName recherché
    /// - Parameter name: displayName recherché
    /// - Returns: membre de la famille trouvé ou nil
    public func member(withName name: String) -> Person? {
        self.members.items.first(where: { $0.displayName == name })
    }
    
}
