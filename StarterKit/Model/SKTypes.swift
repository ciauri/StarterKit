//
//  SKTypes.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

enum SKError: LocalizedError {
    case cloudKitUnavailable
    case recordDoesNotExist
    case native(Error)
}

protocol SKCloudKitRecord {
    static var recordType: String { get }
    var encodedSystemFields: Data? { get }
    var ckRecord: CKRecord { get }
}

protocol SKStarterTimelineEntry {
    var date: Date { get }
}

extension SKCloudKitRecord {
    var decodedRecord: CKRecord {
        var record: CKRecord
        if let fields = encodedSystemFields,
            let coder = try? NSKeyedUnarchiver(forReadingFrom: fields) {
            coder.requiresSecureCoding = true
            record = CKRecord(coder: coder)!
            coder.finishDecoding()
        } else {
            record = CKRecord(recordType: Self.recordType)
        }
        return record
    }
}

extension CKRecord {
    var encodedSystemFields: Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }
}
