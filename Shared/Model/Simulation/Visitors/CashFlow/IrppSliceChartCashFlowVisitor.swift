//
//  IrppSliceChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation
import AppFoundation
import FiscalModel
import Charts

// MARK: - Génération de graphiques - Synthèse - FISCALITE IRPP

enum IrppEnum: Int, PickableEnum {
    case bareme
    case withChildren
    case withoutChildren

    var id: Int {
        return self.rawValue
    }

    var pickerString: String {
        switch self {
            case .bareme:
                return "Barême"
            case .withChildren:
                return "Quotient Familial \n avec Enfants"
            case .withoutChildren:
                return "Quotient Familial \n sans Enfant"
        }
    }
}

/// Dessiner un graphe à lignes : revenu imposable + irpp
/// - Returns: tableau de LineChartDataSet
class IrppSliceChartCashFlowVisitor: CashFlowIrppSliceVisitorP {

    var dataSets: BarChartDataSet?
    private var _dataSets = BarChartDataSet()
    private var yVals1    = [ChartDataEntry]()
    private var yVals2    = [ChartDataEntry]()
    private var year       : Int
    private var nbAdults   : Int
    private var nbChildren : Int

    init(element            : CashFlowArray,
         for year           : Int,
         nbAdults           : Int,
         nbChildren         : Int) {
        self.year       = year
        self.nbAdults   = nbAdults
        self.nbChildren = nbChildren
        buildIrppSliceChart(element: element)
    }

    func buildIrppSliceChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }
        // si l'année n'existe pas dans le tableau de cash flow
        guard let cfLine = element[year] else { return }

        let slicedIrpp = try! Fiscal.model.incomeTaxes.slicedIrpp(taxableIncome : cfLine.taxes.irpp.amount / cfLine.taxes.irpp.averageRate,
                                                                  nbAdults      : nbAdults,
                                                                  nbChildren    : nbChildren)
        let bars = IrppEnum.allCases.map { (xLabel) -> BarChartDataEntry in
            var yVals = [Double]()
            switch xLabel {
                case .bareme:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        $0.size
                    }
                case .withChildren:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        $0.sizeithChildren
                    }
                case .withoutChildren:
                    yVals = slicedIrpp.map { // pour chaque tranche = série
                        return $0.sizeithoutChildren
                    }
            }
            return BarChartDataEntry(x       : Double(xLabel.id),
                                     yValues : yVals)
        }
        _dataSets = BarChartDataSet(entries: bars,
                                    label: "Tranches par taux d'imposition")
        _dataSets.colors = slicedIrpp.map { // pour chaque tranche
            ChartThemes.taxRateColor(rate: $0.rate)
        }
        _dataSets.stackLabels = slicedIrpp.map { // pour chaque tranche
            ($0.rate).percentStringRounded
        }
        dataSets = _dataSets

    }
}
