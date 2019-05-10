//
//  SKStarterCheckIn.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 5/6/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKStarterCheckIn: Codable, SKStarterTimelineEntry {
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
        case remarks
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.date.rawValue] = date
        record[RecordKey.remarks.rawValue] = remarks
        return record
    }
}

extension CKRecord {
    var skStarterCheckIn: SKStarterCheckIn? {
        guard
            let date = self[SKStarterCheckIn.RecordKey.date.rawValue] as? Date,
            let remarks = self[SKStarterCheckIn.RecordKey.remarks.rawValue] as? String else {
                return nil
        }
        return SKStarterCheckIn(date: date, remarks: remarks, encodedSystemFields: encodedSystemFields)
    }
}
