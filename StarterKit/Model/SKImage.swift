//
//  SKImage.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 5/6/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKImage: Codable {
    static let recordType = "Images"
    
    let name: String?
    let dateTaken: Date?
    let data: Data
    
    // MARK: - CloudKit
    let encodedSystemFields: Data?
}

extension SKImage {
    init(name: String? = nil, date: Date? = nil, data: Data) {
        self.init(name: name, dateTaken: date, data: data, encodedSystemFields: nil)
    }
}

// MARK: - CloudKit
extension SKImage: SKCloudKitRecord {
    enum RecordKey: String {
        case name
        case dateTaken
        case data
    }
    
    var ckRecord: CKRecord {
        let record = decodedRecord
        record[RecordKey.name.rawValue] = name
        record[RecordKey.dateTaken.rawValue] = dateTaken
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let tempFilename = UUID().uuidString
        let tempFileURL = tempDirURL.appendingPathComponent(tempFilename)
        try? data.write(to: tempFileURL)
        record[RecordKey.data.rawValue] = CKAsset(fileURL: tempFileURL)
        
        return record
    }
}

extension CKRecord {
    var skImage: SKImage? {
        guard
            let asset = self[SKImage.RecordKey.data.rawValue] as? CKAsset,
            let dataURL = asset.fileURL,
            let data = try? Data(contentsOf: dataURL) else {
                return nil
        }
        let name = self[SKImage.RecordKey.name.rawValue] as? String
        let date = self[SKImage.RecordKey.dateTaken.rawValue] as? Date
        return SKImage(name: name, dateTaken: date, data: data, encodedSystemFields: encodedSystemFields)
    }
}
