//
//  SKStarterMeal.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKStarterMeal: Codable {
    static let recordType = "StarterMeals"
    
    let date: Date
    let flourRations: [SKFlourRation]?
    let waterRation: SKWaterRation?
    
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

// MARK: - CloudKit
extension SKStarterMeal: SKCloudKitRecord {
    enum RecordKey: String {
        case date
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.date.rawValue] = date
        
        return record
    }
}

extension CKRecord {
    var skStarterMeal: SKStarterMeal? {
        guard
            let date = self[SKStarterMeal.RecordKey.date.rawValue] as? Date else {
                return nil
        }
        return SKStarterMeal(date: date, flourRations: nil, waterRation: nil, encodedSystemFields: encodedSystemFields)
    }
}
