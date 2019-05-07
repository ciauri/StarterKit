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
    
    @discardableResult
    static func initialize(completion: @escaping (Result<SKClient, SKError>)->Void) -> Operation {
        let client = SKClient(starter: nil)
        return client.fetchStarter { (result) in
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
    
    @discardableResult
    func fetchStarter(completion: @escaping (Result<SKStarter, SKError>)->Void) -> Operation {
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
        return operation
    }
    
    @discardableResult
    func put(_ starter: SKStarter, completion: @escaping (Result<SKStarter, SKError>)->Void) -> Operation {
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
        return operation
    }
    
    @discardableResult
    func feedStarter(meal: SKStarterMeal, completion: @escaping (Result<SKStarterMeal, SKError>)->Void) -> Operation {
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
        return operation
    }
    
    @discardableResult
    func fetchLastMeal(for starter: SKStarter, completion: @escaping (Result<SKStarterMeal, SKError>)->Void) -> Operation {
        let predicate = NSPredicate(format: "owner == %@", starter.ckRecord)
        let query = CKQuery(recordType: SKStarterMeal.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetchMealOperation = CKQueryOperation(query: query)
        fetchMealOperation.resultsLimit = 1
        var mealRecord: CKRecord!
        var flourRecords: [CKRecord] = []
        var waterRecord: CKRecord!
        
        let aggregateOperation = BlockOperation {
            guard let meal = mealRecord.skStarterMeal,
                let water = waterRecord.skWaterRation else {
                    return completion(.failure(.recordDoesNotExist))
            }
            let flour = flourRecords.compactMap({$0.skFlourRation})
            let finalMeal = SKStarterMeal(date: meal.date, flourRations: flour, waterRation: water, encodedSystemFields: meal.encodedSystemFields)
            return completion(.success(finalMeal))
        }

        fetchMealOperation.recordFetchedBlock = { record in
            mealRecord = record
        }
        
        fetchMealOperation.completionBlock = {
            let fetchFlourPredicate = NSPredicate(format: "owner == %@", mealRecord)
            let flourQuery = CKQuery(recordType: SKFlourRation.recordType, predicate: fetchFlourPredicate)
            let flourOperation = CKQueryOperation(query: flourQuery)
            flourOperation.recordFetchedBlock = { fetchedFlour in
                flourRecords.append(fetchedFlour)
            }
            
            let waterPredicate = NSPredicate(format: "owner == %@", mealRecord)
            let waterQuery = CKQuery(recordType: SKWaterRation.recordType, predicate: waterPredicate)
            let waterOperation = CKQueryOperation(query: waterQuery)
            waterOperation.resultsLimit = 1
            waterOperation.recordFetchedBlock = { record in
                waterRecord = record
            }
            aggregateOperation.addDependency(flourOperation)
            aggregateOperation.addDependency(waterOperation)
            self.service.privateDatabase.add(flourOperation)
            self.service.privateDatabase.add(waterOperation)
            OperationQueue.main.addOperation(aggregateOperation)
        }

        service.privateDatabase.add(fetchMealOperation)
        return aggregateOperation
    }
}
