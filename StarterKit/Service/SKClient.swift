//
//  SKClient.swift
//  StarterKit
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

class SKClient {
    let service: SKService = SKService()
    var starter: SKStarter?
    
    static func initialize(completion: @escaping (Result<SKClient, SKError>)->Void) {
        let client = SKClient(starter: nil)
        client.fetchStarter { (result) in
            switch result {
            case .success(let starter):
                return completion(.success(SKClient(starter: starter)))
            case .failure(let error):
                switch error {
                case .recordDoesNotExist:
                    return completion(.success(.init()))
                default:
                    return completion(.failure(error))
                }
            }
        }
    }
    
    private init(starter: SKStarter? = nil) {
        self.starter = starter
    }
    
    func fetchStarter(completion: @escaping (Result<SKStarter, SKError>)->Void) {
        let query = CKQuery(recordType: SKStarter.recordType, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .userInteractive
        var records: [CKRecord] = []
        operation.recordFetchedBlock = { record in
            records.append(record)
        }
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                let starters = records.compactMap({$0.skStarter})
                if let starter = starters.first {
                    return completion(.success(starter))
                } else {
                    return completion(.failure(.recordDoesNotExist))
                }
            }
        }
        service.privateDatabase.add(operation)
    }
    
    func putStarter(name: String, feedInterval: Int, birthday: Date?, birthplace: String?, completion: @escaping (Result<SKStarter, SKError>)->Void) {
        let starter = SKStarter(name: name, feedIntervalMinutes: feedInterval, birthday: birthday, birthplace: birthplace, encodedSystemFields: nil)
        let operation = CKModifyRecordsOperation(recordsToSave: [starter.ckRecord], recordIDsToDelete: nil)
        operation.qualityOfService = .userInteractive
        operation.modifyRecordsCompletionBlock = {[weak self] savedRecords, deletedIds, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                let starters = savedRecords?.compactMap({$0.skStarter})
                if let starter = starters?.first {
                    self?.starter = starter
                    return completion(.success(starter))
                } else {
                    return completion(.failure(.recordDoesNotExist))
                }
            }
        }
        service.privateDatabase.add(operation)
    }
    
    func feedStarter(meal: SKStarterMeal, completion: @escaping (Result<SKStarterMeal, SKError>)->Void) {
        let starterRef = CKRecord.Reference(record: starter!.ckRecord, action: .deleteSelf)
        let mealRecord = meal.ckRecord
        let mealRef = CKRecord.Reference(record: mealRecord, action: .deleteSelf)
        let flourRecords = meal.flourRations?.map({ $0.ckRecord }) ?? []
        let waterRecord = meal.waterRation!.ckRecord
        flourRecords.forEach({
            $0["owner"] = mealRef
        })
        waterRecord["owner"] = mealRef
        mealRecord["owner"] = starterRef
        
        let operation = CKModifyRecordsOperation(recordsToSave: flourRecords + [mealRecord, waterRecord], recordIDsToDelete: nil)
        operation.qualityOfService = .userInteractive
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedIds, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                let meals = savedRecords?.compactMap({$0.skStarterMeal})
                if let meal = meals?.first {
                    return completion(.success(meal))
                } else {
                    return completion(.failure(.recordDoesNotExist))
                }
            }
        }
        service.privateDatabase.add(operation)
    }
}
