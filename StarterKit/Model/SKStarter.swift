//
//  SKStarter.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

public struct SKStarter: Codable {
    static let recordType = "Starters"
    
    public let name: String
    public let feedIntervalMinutes: Int
    public let birthday: Date?
    public let birthplace: String?
    
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

extension SKStarter {
    public init(name: String, feedInterval: Int, birthday: Date? = .init(), birthplace: String? = nil) {
        self.init(name: name, feedIntervalMinutes: feedInterval, birthday: birthday, birthplace: birthplace, encodedSystemFields: nil)
    }
}

// MARK: - CloudKit
extension SKStarter: SKCloudKitRecord {
    enum RecordKey: String {
        case name
        case feedIntervalMinutes
        case birthday
        case birthplace
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.name.rawValue] = name
        record[RecordKey.feedIntervalMinutes.rawValue] = feedIntervalMinutes
        record[RecordKey.birthday.rawValue] = birthday
        record[RecordKey.birthplace.rawValue] = birthplace
        return record
    }
}

extension CKRecord {
    var skStarter: SKStarter? {
        guard
            let name = self[SKStarter.RecordKey.name.rawValue] as? String,
            let interval = self[SKStarter.RecordKey.feedIntervalMinutes.rawValue] as? Int else {
                return nil
        }
        let birthday = self[SKStarter.RecordKey.birthday.rawValue] as? Date
        let birthplace = self[SKStarter.RecordKey.birthplace.rawValue] as? String
        return SKStarter(name: name,
                         feedIntervalMinutes: interval,
                         birthday: birthday,
                         birthplace: birthplace,
                         encodedSystemFields:encodedSystemFields)
    }
}
