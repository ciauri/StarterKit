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
    func delete(_ record: SKCloudKitRecord, completion: @escaping (Result<Void, SKError>)->Void) -> Operation {
        precondition(record.encodedSystemFields != nil, "Cannot delete a record that doesn't exist in CloudKit")
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record.ckRecord.recordID])
        operation.qualityOfService = .utility
        operation.modifyRecordsCompletionBlock = { _, deletedIds, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                if deletedIds?.first == record.ckRecord.recordID {
                    return completion(.success(()))
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
        let imageRecord = meal.image?.ckRecord
        flourRecords.forEach({
            $0["owner"] = mealRef
        })
        imageRecord?["owner"] = mealRef
        waterRecord["owner"] = mealRef
        mealRecord["owner"] = starterRef
        
        let operation = CKModifyRecordsOperation(recordsToSave: flourRecords + [mealRecord, waterRecord, imageRecord].compactMap({$0}), recordIDsToDelete: nil)
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
    func checkInStarter(checkIn: SKStarterCheckIn, completion: @escaping (Result<SKStarterCheckIn, SKError>)->Void) -> Operation {
        let starterRef = CKRecord.Reference(record: starter!.ckRecord, action: .deleteSelf)
        let checkInRecord = checkIn.ckRecord
        checkInRecord["owner"] = starterRef
        
        return execute(checkInRecords: [checkInRecord], completion: { (result) in
            switch result {
            case .success(let records):
                return completion(.success(records.first!))
            case .failure(let error):
                return completion(.failure(error))
            }
        })
    }
    
    @discardableResult
    func checkInStarter(checkIns: [SKStarterCheckIn], completion: @escaping (Result<[SKStarterCheckIn], SKError>)->Void) -> Operation {
        let starterRef = CKRecord.Reference(record: starter!.ckRecord, action: .deleteSelf)
        var checkInRecords: [CKRecord] = []
        for checkIn in checkIns {
            let checkInRecord = checkIn.ckRecord
            checkInRecord["owner"] = starterRef
            checkInRecords.append(checkInRecord)
        }
        
        return execute(checkInRecords: checkInRecords, completion: completion)
    }
    
    private func execute(checkInRecords: [CKRecord], completion: @escaping (Result<[SKStarterCheckIn], SKError>)->Void) -> Operation {
        let operation = CKModifyRecordsOperation(recordsToSave: checkInRecords, recordIDsToDelete: nil)
        operation.qualityOfService = .userInteractive
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedIds, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                if let checkIns = savedRecords?.compactMap({$0.skStarterCheckIn}) {
                    return completion(.success(checkIns))
                } else {
                    return completion(.failure(.recordDoesNotExist))
                }
            }
        }
        service.privateDatabase.add(operation)
        return operation
    }
    
    @discardableResult
    func feedStarter(meals: [SKStarterMeal], completion: @escaping (Result<[SKStarterMeal], SKError>)->Void) -> Operation {
        let starterRef = CKRecord.Reference(record: starter!.ckRecord, action: .deleteSelf)
        var mealRecords: [CKRecord] = []
        var totalFlourRecords: [CKRecord] = []
        var totalWaterRecords: [CKRecord] = []
        var totalImageRecords: [CKRecord] = []
        for meal in meals {
            let mealRecord = meal.ckRecord
            let mealRef = CKRecord.Reference(record: mealRecord, action: .deleteSelf)
            let flourRecords = meal.flourRations?.map({ $0.ckRecord }) ?? []
            let waterRecord = meal.waterRation!.ckRecord
            let imageRecord = meal.image?.ckRecord
            flourRecords.forEach({
                $0["owner"] = mealRef
            })
            imageRecord?["owner"] = mealRef
            waterRecord["owner"] = mealRef
            mealRecord["owner"] = starterRef
            mealRecords.append(mealRecord)
            totalFlourRecords += flourRecords
            totalWaterRecords.append(waterRecord)
            if let imageRecord = imageRecord {
                totalImageRecords.append(imageRecord)
            }
        }
        
        
        let operation = CKModifyRecordsOperation(recordsToSave: totalFlourRecords + mealRecords + totalWaterRecords + totalImageRecords, recordIDsToDelete: nil)
        operation.qualityOfService = .userInteractive
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedIds, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                let meals = savedRecords?.compactMap({$0.skStarterMeal})
                if let meals = meals {
                    return completion(.success(meals))
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
        var imageRecord: CKRecord?
        
        let aggregateOperation = BlockOperation {
            guard let meal = mealRecord.skStarterMeal,
                let water = waterRecord.skWaterRation else {
                    return completion(.failure(.recordDoesNotExist))
            }
            let flour = flourRecords.compactMap({$0.skFlourRation})
            let image = imageRecord?.skImage
            let finalMeal = SKStarterMeal(date: meal.date, flourRations: flour, waterRation: water, image: image, encodedSystemFields: meal.encodedSystemFields)
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
            
            let imagePredicate = NSPredicate(format: "owner == %@", mealRecord)
            let imageQuery = CKQuery(recordType: SKImage.recordType, predicate: imagePredicate)
            let imageOperation = CKQueryOperation(query: imageQuery)
            imageOperation.resultsLimit = 1
            imageOperation.recordFetchedBlock = { record in
                imageRecord = record
            }
            aggregateOperation.addDependency(imageOperation)
            aggregateOperation.addDependency(flourOperation)
            aggregateOperation.addDependency(waterOperation)
            
            self.service.privateDatabase.add(flourOperation)
            self.service.privateDatabase.add(waterOperation)
            self.service.privateDatabase.add(imageOperation)
            OperationQueue.main.addOperation(aggregateOperation)
        }

        service.privateDatabase.add(fetchMealOperation)
        return aggregateOperation
    }
    
    @discardableResult
    func fetchMealDetails(for meal: SKStarterMeal, completion: @escaping (Result<SKStarterMeal, SKError>)->Void) -> Operation {
        let mealRecord = meal.ckRecord
        var flourRecords: [CKRecord] = []
        var waterRecord: CKRecord!
        var imageRecord: CKRecord?
        
        let aggregateOperation = BlockOperation {
            guard let meal = mealRecord.skStarterMeal,
                let water = waterRecord.skWaterRation else {
                    return completion(.failure(.recordDoesNotExist))
            }
            let flour = flourRecords.compactMap({$0.skFlourRation})
            let image = imageRecord?.skImage
            let finalMeal = SKStarterMeal(date: meal.date, flourRations: flour, waterRation: water, image: image, encodedSystemFields: meal.encodedSystemFields)
            return completion(.success(finalMeal))
        }
        
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
        
        let imagePredicate = NSPredicate(format: "owner == %@", mealRecord)
        let imageQuery = CKQuery(recordType: SKImage.recordType, predicate: imagePredicate)
        let imageOperation = CKQueryOperation(query: imageQuery)
        imageOperation.resultsLimit = 1
        imageOperation.recordFetchedBlock = { record in
            imageRecord = record
        }
        aggregateOperation.addDependency(imageOperation)
        aggregateOperation.addDependency(flourOperation)
        aggregateOperation.addDependency(waterOperation)
        
        self.service.privateDatabase.add(flourOperation)
        self.service.privateDatabase.add(waterOperation)
        self.service.privateDatabase.add(imageOperation)
        OperationQueue.main.addOperation(aggregateOperation)
        
        return aggregateOperation
    }
    
    @discardableResult
    func fetchAllMeals(for starter: SKStarter, dependencies: [Operation] = [], completion: @escaping (Result<[SKStarterMeal], SKError>)->Void) -> Operation {
        let predicate = NSPredicate(format: "owner == %@", starter.ckRecord)
        let query = CKQuery(recordType: SKStarterMeal.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetchMealOperation = CKQueryOperation(query: query)
        var mealRecords: [CKRecord] = []
        
        fetchMealOperation.recordFetchedBlock = { record in
            mealRecords.append(record)
        }
        
        fetchMealOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                return completion(.failure(.native(error)))
            } else {
                return completion(.success(mealRecords.compactMap({$0.skStarterMeal})))
            }
        }

        
        dependencies.forEach({fetchMealOperation.addDependency($0)})
        service.privateDatabase.add(fetchMealOperation)
        return fetchMealOperation
    }
    
    @discardableResult
    func fetchAllCheckIns(for starter: SKStarter, dependencies: [Operation] = [], completion: @escaping (Result<[SKStarterCheckIn], SKError>)->Void) -> Operation {
        let predicate = NSPredicate(format: "owner == %@", starter.ckRecord)
        let query = CKQuery(recordType: SKStarterCheckIn.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetchCheckInsOperation = CKQueryOperation(query: query)
        var checkInRecords: [CKRecord] = []
        
        fetchCheckInsOperation.recordFetchedBlock = { record in
            checkInRecords.append(record)
        }
        
        fetchCheckInsOperation.completionBlock = {
            return completion(.success(checkInRecords.compactMap({$0.skStarterCheckIn})))
        }
        
        dependencies.forEach({fetchCheckInsOperation.addDependency($0)})
        service.privateDatabase.add(fetchCheckInsOperation)
        return fetchCheckInsOperation
    }
    
    @discardableResult
    func fetchTimeline(for starter: SKStarter, dependencies: [Operation] = [], completion: @escaping (Result<[SKStarterTimelineEntry], SKError>)->Void) -> Operation {
        let predicate = NSPredicate(format: "owner == %@", starter.ckRecord)
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        
        let checkInQuery = CKQuery(recordType: SKStarterCheckIn.recordType, predicate: predicate)
        checkInQuery.sortDescriptors = [sortDescriptor]
        let fetchCheckInsOperation = CKQueryOperation(query: checkInQuery)
        var checkInRecords: [CKRecord] = []
        
        fetchCheckInsOperation.recordFetchedBlock = { record in
            checkInRecords.append(record)
        }

        let mealQuery = CKQuery(recordType: SKStarterMeal.recordType, predicate: predicate)
        mealQuery.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let fetchMealOperation = CKQueryOperation(query: mealQuery)
        var mealRecords: [CKRecord] = []
        
        fetchMealOperation.recordFetchedBlock = { record in
            mealRecords.append(record)
        }
 
        let aggregateOperation = BlockOperation {
            let results: [SKStarterTimelineEntry] = (checkInRecords.compactMap({$0.skStarterCheckIn}) + mealRecords.compactMap({$0.skStarterMeal})).sorted(by: {$0.date > $1.date})
            return completion(.success(results))
        }
        
        aggregateOperation.addDependency(fetchMealOperation)
        aggregateOperation.addDependency(fetchCheckInsOperation)
        OperationQueue.main.addOperation(aggregateOperation)
        
        dependencies.forEach({fetchMealOperation.addDependency($0)})
        service.privateDatabase.add(fetchMealOperation)
        
        dependencies.forEach({fetchCheckInsOperation.addDependency($0)})
        service.privateDatabase.add(fetchCheckInsOperation)
        return fetchCheckInsOperation
    }
}
