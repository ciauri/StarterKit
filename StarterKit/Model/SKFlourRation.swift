//
//  SKFlourRation.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKFlourRation: Codable {
    static let recordType = "FlourRations"

    let flourName: String
    let amount: Measurement<UnitMass>
    
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

// MARK: - CloudKit
extension SKFlourRation: SKCloudKitRecord {
    enum RecordKey: String {
        case flourName
        case weightInGrams
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.flourName.rawValue] = flourName
        record[RecordKey.weightInGrams.rawValue] = amount.converted(to: .grams).value

        return record
    }
}

extension CKRecord {
    var skFlourRation: SKFlourRation? {
        guard
            let flourName = self[SKFlourRation.RecordKey.flourName.rawValue] as? String,
            let weightInGrams = self[SKFlourRation.RecordKey.weightInGrams.rawValue] as? Double else {
                return nil
        }
        let weight = Measurement(value: weightInGrams, unit: UnitMass.grams)
        return SKFlourRation(flourName: flourName, amount: weight, encodedSystemFields: encodedSystemFields)
    }
}
