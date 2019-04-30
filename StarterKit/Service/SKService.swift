//
//  SKService.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

struct SKService {
    let container: CKContainer
    
    var privateDatabase: CKDatabase {
        return container.privateCloudDatabase
    }
    
    var publicDb: CKDatabase {
        return container.publicCloudDatabase
    }
    
    var sharedDb: CKDatabase {
        return container.sharedCloudDatabase
    }
    
    init(container: CKContainer = .default()) {
        self.container = container
    }

    func clearDefaultZone(completion: @escaping (Result<Bool, Error>)->Void) {
        privateDatabase.delete(withRecordZoneID: .default) { (zoneID, error) in
            if let error = error {
                return completion(.failure(error))
            } else {
                return completion(.success(true))
            }
        }
    }
}
