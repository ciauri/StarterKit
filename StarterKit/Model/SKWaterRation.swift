//
//  SKWaterRation.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKWaterRation: Codable, Equatable {
    static let recordType = "WaterRations"

    let amount: Measurement<UnitMass>
    let temperature: Measurement<UnitTemperature>?
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

extension SKWaterRation {
    init(amount: Measurement<UnitMass>, temperature: Measurement<UnitTemperature>) {
        self.init(amount: amount, temperature: temperature, encodedSystemFields: nil)
    }
}

// MARK: - CloudKit
extension SKWaterRation: SKCloudKitRecord {
    enum RecordKey: String {
        case weightInGrams
        case temperatureInFahrenheit
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.weightInGrams.rawValue] = amount.converted(to: .grams).value
        record[RecordKey.temperatureInFahrenheit.rawValue] = temperature?.converted(to: .fahrenheit).value
        
        return record
    }
}

extension CKRecord {
    var skWaterRation: SKWaterRation? {
        guard
            let tempInFahrenheit = self[SKWaterRation.RecordKey.temperatureInFahrenheit.rawValue] as? Double,
            let weightInGrams = self[SKWaterRation.RecordKey.weightInGrams.rawValue] as? Double else {
                return nil
        }
        let weight = Measurement(value: weightInGrams, unit: UnitMass.grams)
        let temp = Measurement(value: tempInFahrenheit, unit: UnitTemperature.fahrenheit)
        return SKWaterRation(amount: weight, temperature: temp, encodedSystemFields: encodedSystemFields)
    }
}

extension Measurement where UnitType: UnitTemperature {
    static var chilly: Measurement<UnitTemperature> {
        return .init(value: 55, unit: .fahrenheit)
    }
    static var room: Measurement<UnitTemperature> {
        return .init(value: 72, unit: .fahrenheit)
    }
    
    static var warm: Measurement<UnitTemperature> {
        return .init(value: 80, unit: .fahrenheit)
    }
}
