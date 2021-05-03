//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - SINGLETON: Modèle fiscal

public struct Fiscal {
    
    // MARK: - Nested types

    public struct Model: BundleCodable {
        
        // MARK: - Static Properties
        
        public static var defaultFileName   : String = "FiscalModelConfig.json"
        
        // MARK: - Properties
        
        public var PASS                     : Double // Plafond Annuel de la Sécurité Sociale en €
        // impôts
        public var incomeTaxes              : IncomeTaxesModel
        public var isf                      : IsfModel
        public var estateCapitalGainIrpp    : RealEstateCapitalGainIrppModel
        // charges sociales
        public var estateCapitalGainTaxes   : RealEstateCapitalGainTaxesModel
        public var pensionTaxes             : PensionTaxesModel
        public var financialRevenuTaxes     : FinancialRevenuTaxesModel
        public var turnoverTaxes            : TurnoverTaxesModel
        public var allocationChomageTaxes   : AllocationChomageTaxesModel
        public var layOffTaxes              : LayOffTaxes
        public var lifeInsuranceTaxes       : LifeInsuranceTaxes
        public var companyProfitTaxes       : CompanyProfitTaxesModel
        // autres
        public var demembrement             : DemembrementModel
        public var inheritanceDonation      : InheritanceDonation
        public var lifeInsuranceInheritance : LifeInsuranceInheritance
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public func initialized() -> Model {
            var model = self
            do {
                try model.incomeTaxes.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.incomeTaxes\n" + convertErrorToString(error))
            }
            do {
                try model.isf.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.isf\n" + convertErrorToString(error))
            }
            model.layOffTaxes.initialize(PASS: PASS)
            do {
                try model.inheritanceDonation.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.inheritanceDonation\n" + convertErrorToString(error))
            }
            do {
                try model.lifeInsuranceInheritance.initialize()
            } catch {
                fatalError("Failed to initialize Fiscal.model.lifeInsuranceInheritance\n" + convertErrorToString(error))
            }
            return model
        }
    }
    
    // MARK: - Static Properties

    public static var model: Model = Model().initialized()

    // MARK: - Initializer
    
    private init() {
    }
}
