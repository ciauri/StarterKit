//
//  SKStarterCheckIn.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 5/6/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKStarterCheckIn: Codable {
    static let recordType = "StarterCheckIns"
    
    let date: Date
    let remarks: String
    
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

extension SKStarterCheckIn {
    init(date: Date = .init(), remarks: String) {
        self.init(date: date, remarks: remarks, encodedSystemFields: nil)
    }
}

// MARK: - CloudKit
extension SKStarterCheckIn: SKCloudKitRecord {
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
    var skStarterCheckIn: SKStarterMeal? {
        guard
            let date = self[SKStarterMeal.RecordKey.date.rawValue] as? Date else {
                return nil
        }
        return SKStarterMeal(date: date, flourRations: nil, waterRation: nil, encodedSystemFields: encodedSystemFields)
    }
}
