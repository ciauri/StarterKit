//
//  StarterKitTests.swift
//  StarterKitTests
//
//  Created by Stephen Ciauri on 4/22/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import XCTest
@testable import StarterKit

class StarterKitTests: XCTestCase {
    override func setUp() {
        let setupExpectation = expectation(description: "clear zone")
        SKService().clearDefaultZone { (result) in
            switch result {
            case .success(let bool):
                XCTAssert(bool)
            default:
                XCTFail()
            }
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 5)
    }
    
    func testFetchStarter() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                XCTAssertNil(client.starter)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            testExpectation.fulfill()
        }
        
        wait(for: [testExpectation], timeout: 10)
    }
    
    func testPutStarter() {
        let testExpectation = expectation(description: "testPutStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                client.putStarter(name: "yoloer", feedInterval: 360, birthday: Date(), birthplace: "Boston", completion: { (result) in
                    switch result {
                    case .success(let starter):
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    testExpectation.fulfill()
                })
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
    
    func testFeedStarter() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                client.putStarter(name: "yoloer", feedInterval: 360, birthday: Date(), birthplace: "Boston", completion: { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(flourName: "White", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil)]
                        let meal = SKStarterMeal(date: .init(), flourRations: flour, waterRation: water, encodedSystemFields: nil)
                        client.feedStarter(meal: meal, completion: { (result) in
                            switch result {
                            case .success(let meal):
                                XCTAssertTrue(true)
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            testExpectation.fulfill()
                        })
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
    
    
    
    func testDeleteZone() {
        let testExpectation = expectation(description: "testDeleteZone")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                client.putStarter(name: "yoloer", feedInterval: 360, birthday: Date(), birthplace: "Boston", completion: { (result) in
                    switch result {
                    case .success(let starter):
                        XCTAssertNotNil(starter)
                        let service = SKService()
                        service.clearDefaultZone { (result) in
                            switch result {
                            case .success(let boolResult):
                                XCTAssert(boolResult)
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            client.fetchStarter(completion: { (result) in
                                switch result {
                                case .failure(let error):
                                    switch error {
                                    case .recordDoesNotExist:
                                        break
                                    default:
                                        XCTFail("Unexpected error type")
                                    }
                                case .success(let starter):
                                    XCTAssertNil(starter)
                                }
                                testExpectation.fulfill()
                            })
                        }
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
}
