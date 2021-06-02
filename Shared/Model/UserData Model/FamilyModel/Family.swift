import Foundation
import FiscalModel
import Files
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

// MARK: - Class Family: la Famille, ses membres, leurs actifs et leurs revenus

/// la Famille, ses membres, leurs actifs et leurs revenus
final class Family: ObservableObject {
    
    // MARK: - Properties
    
    // structure de la famille
    @Published private(set) var members = PersistableArrayOfPerson()
    // dépenses
    @Published var expenses = LifeExpensesDic()
    // revenus
    var workNetIncome    : Double { // computed
        var netIcome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult {netIcome += adult.workNetIncome}
        }
        return netIcome
    }
    var workTaxableIncome: Double { // computed
        var taxableIncome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult {taxableIncome += adult.workTaxableIncome}
        }
        return taxableIncome
    }
    // coefficient familial
    var familyQuotient   : Double { // computed
        try! Fiscal.model.incomeTaxes.familyQuotient(nbAdults: nbOfAdults, nbChildren: nbOfChildren)
    }
    // impots
    var irpp             : Double { // computed
        try! Fiscal.model.incomeTaxes.irpp(taxableIncome: workTaxableIncome, nbAdults: nbOfAdults, nbChildren: nbOfChildren).amount
    }

    var nbOfChildren     : Int { // computed
        var nb = 0
        for person in members.items where person is Child {nb += 1}
        return nb
    }
    var nbOfAdults       : Int { // computed
        var nb = 0
        for person in members.items where person is Adult {nb += 1}
        return nb
    }
    
    var adults  : [Person] {
        members.items.filter {$0 is Adult}
    }
    var children: [Person] {
        members.items.filter {$0 is Child}
    }

    var isModified: Bool {
        expenses.isModified || members.isModified
    }

    // MARK: - Initializers

    /// Initialiser à vide
    init() {
        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(self)
        // injection de family dans la propriété statique de Expense
        LifeExpense.setMembersCountProvider(self)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(self)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.family = self
    }

    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    convenience init(fromFolder folder: Folder) throws {
        self.init()
        try self.expenses = LifeExpensesDic(fromFolder: folder)
    }

    // MARK: - Methodes

    func loadFromJSON(fromFolder folder: Folder) throws {
        expenses = try LifeExpensesDic(fromFolder : folder)
        members  = try PersistableArrayOfPerson(from: folder)
    }

    func saveAsJSON(toFolder folder: Folder) throws {
        try expenses.saveAsJSON(toFolder: folder)
        try members.saveAsJSON(to: folder)
    }

    /// Rend la liste des enfants vivants
    /// - Parameter year: année
    /// - Warning: Vérifie que l'enfant est vivant
    func chidldrenAlive(atEndOf year: Int) -> [Child]? {
        members.items
            .filter { person in
                person is Child && person.isAlive(atEndOf: year)
            }
            .map { person in
                person as! Child
            }
    }
    
    /// Nombre d'enfant vivant à la fin de l'année
    /// - Parameter year: année considérée
    func nbOfChildrenAlive(atEndOf year: Int) -> Int {
        members.items
            .reduce(0) { (result, person) in
                result + ((person is Child && person.isAlive(atEndOf: year)) ? 1 : 0)
            }
    }
    
    /// Retourne la liste des personnes décédées dans l'année
    /// - Parameter year: année où l'on recherche des décès
    /// - Returns: liste des personnes décédées dans l'année
    func deceasedAdults(during year: Int) -> [Person] {
        members.items.compactMap { member in
            if member is Adult && member.isDeceased(during: year) {
                // un décès est survenu
                return member
            } else {
                return nil
            }
        }
        .sorted(by: \.birthDate)
    }
    
    /// Revenus du tavail cumulés de la famille durant l'année
    /// - Parameter year: année
    /// - Parameter netIncome: revenu net de charges et d'assurance (à vivre)
    /// - Parameter taxableIncome: Revenus du tavail cumulés imposable à l'IRPP
    func income(during year: Int) -> (netIncome: Double, taxableIncome: Double) {
        var totalNetIncome     : Double = 0.0
        var totalTaxableIncome : Double = 0.0
        for person in members.items {
            if let adult = person as? Adult {
                let income = adult.workIncome(during: year)
                totalNetIncome     += income.net
                totalTaxableIncome += income.taxableIrpp
            }
        }
        return (totalNetIncome, totalTaxableIncome)
    }
    
    /// Quotient familiale durant l'année
    /// - Parameter year: année
    func familyQuotient (during year: Int) -> Double {
        try! Fiscal.model.incomeTaxes.familyQuotient(nbAdults: nbOfAdultAlive(atEndOf: year), nbChildren: nbOfFiscalChildren(during: year))
    }
    
    /// IRPP sur les revenus du travail de la famille
    /// - Parameter year: année
    func irpp (for year: Int) -> Double {
        try! Fiscal.model.incomeTaxes.irpp(
            // FIXME: A CORRIGER pour prendre en compte tous les revenus imposable
            taxableIncome : income(during : year).taxableIncome, // A CORRIGER
            nbAdults      : nbOfAdultAlive(atEndOf    : year),
            nbChildren    : nbOfFiscalChildren(during : year))
            .amount
    }
    
    /// Pensions de retraite cumulées de la famille durant l'année
    /// - Parameter year: année
    /// - Returns: Pensions de retraite cumulées brutes
    func pension(during year: Int, withReversion: Bool = true) -> Double {
        var pension = 0.0
        for person in members.items {
            if let adult = person as? Adult {
                pension += adult.pension(during        : year,
                                         withReversion : withReversion).brut
            }
        }
        return pension
    }
    
    /// Mettre à jour le nombre d'enfant de chaque parent de la famille
    func updateChildrenNumber() {
        for member in members.items { // pour chaque membre de la famille
            if let adult = member as? Adult { // si c'est un parent
                adult.gaveBirthTo(children: nbOfChildren) // mettre à jour le nombre d'enfant
            }
        }
    }
    
    /// Trouver le membre de la famille avec le displayName recherché
    /// - Parameter name: displayName recherché
    /// - Returns: membre de la famille trouvé ou nil
    func member(withName name: String) -> Person? {
        self.members.items.first(where: { $0.displayName == name })
    }
    
    /// Ajouter un membre à la famille
    /// - Parameter person: personne à ajouter
    func addMember(_ person: Person) {
        // ajouter le nouveau membre
        members.add(person)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
    }
    
    func deleteMembers(at offsets: IndexSet) {
        // retirer les membres
        members.delete(at: offsets)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        updateChildrenNumber()
    }
    
    func moveMembers(from indexes: IndexSet, to destination: Int) {
        self.members.items.move(fromOffsets: indexes, toOffset: destination)
    }
    
    func aMemberIsUpdated() {
        // exécuter la transition
        members.persistenceSM.process(event: .modify)
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        self.updateChildrenNumber()
    }
    
    /// Réinitialiser les prioriétés aléatoires des membres et des dépenses
    func nextRandomProperties() {
        // Réinitialiser les prioriété aléatoires des membres
        members.items.forEach {
            $0.nextRandomProperties()
        }
    }

    func currentRandomProperties() -> DictionaryOfAdultRandomProperties {
        var dicoOfAdultsRandomProperties = DictionaryOfAdultRandomProperties()
        members.items.forEach {
            if let adult = $0 as? Adult {
                dicoOfAdultsRandomProperties[adult.displayName] = AdultRandomProperties(ageOfDeath          : adult.ageOfDeath,
                                                                                        nbOfYearOfDependency: adult.nbOfYearOfDependency)
            }
        }
        return dicoOfAdultsRandomProperties

    }

    func nextRun() -> DictionaryOfAdultRandomProperties {
        // Réinitialiser les prioriété aléatoires des membres
        members.items.forEach {
            $0.nextRandomProperties()
        }
        return currentRandomProperties()
    }
}

extension Family: CustomStringConvertible {
    var description: String {
        var desc =
        """

        FAMILLE:
        - Nombre d'adultes dans ls famille: \(nbOfAdults)
        - Nombre d'enfants dans la famille: \(nbOfChildren)
        - family net income:     \(workNetIncome.€String)
        - family taxable income: \(workTaxableIncome.€String)
        - family income tax quotient: \(familyQuotient)
        - family income taxes: \(irpp.€String)
        - MEMBRES DE LA FAMILLE:
        """
        members.items.forEach { member in
            desc += String(describing: member).withPrefixedSplittedLines("  ")
        }
        desc += "\n"
        desc += "- DEPENSES:\n"
        desc += String(describing: expenses).withPrefixedSplittedLines("  ")
        
        return desc
    }
}

extension Family: PersonAgeProvider {
    func ageOf(_ name: String, _ year: Int) -> Int {
        let person = member(withName: name)
        return person?.age(atEndOf: Date.now.year) ?? -1
    }
}

extension Family: PersonEventYearProvider {
    func yearOf(lifeEvent : LifeEvent,
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
    
    func yearOf(lifeEvent : LifeEvent,
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

extension Family: MembersCountProvider {
    /// Nombre d'adulte vivant à la fin de l'année
    /// - Parameter year: année
    func nbOfAdultAlive(atEndOf year: Int) -> Int {
        members.items.reduce(0) { (result, person) in
            result + ((person is Adult && person.isAlive(atEndOf: year)) ? 1 : 0)
        }
    }

    /// Nombre d'enfant dans le foyer fiscal
    /// - Parameter year: année d'imposition
    /// - Note: [service-public.fr](https://www.service-public.fr/particuliers/vosdroits/F3085)
    func nbOfFiscalChildren(during year: Int) -> Int {
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

extension Family: FiscalHouseholdSumator {
    func sum(atEndOf year : Int,
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

extension Family: AdultSpouseProvider {
    /// Rend l'époux d'un adult de la famille (s'il existe), qu'il soit vivant où décédé
    /// - Parameter member: membre adult de la famille
    /// - Returns: époux  (s'il existe)
    /// - Warning: Ne vérifie pas que l'époux est vivant
    func spouseOf(_ member: Adult) -> Adult? {
        for person in members.items {
            if let adult = person as? Adult {
                if adult != member { return adult }
            }
        }
        return nil
    }
}

extension Family: MembersNameProvider {
    var membersName: [String] {
        members.items
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
    var adultsName: [String] {
        adults
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
    var childrenName: [String] {
        children
            .sorted(by: \.birthDate)
            .map { $0.displayName }
    }
}
