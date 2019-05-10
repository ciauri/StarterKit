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
    
    var testImage: UIImage! {
        var image: UIImage!
        DispatchQueue.main.sync {
            let view = UILabel(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
            view.text = "yolobogo"
            view.textColor = .yellow
            view.font = .preferredFont(forTextStyle: .largeTitle)
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
            defer { UIGraphicsEndImageContext() }
            if let context = UIGraphicsGetCurrentContext() {
                view.layer.render(in: context)
                image = UIGraphicsGetImageFromCurrentImageContext()
            }
        }
        return image
    }
    override func setUp() {
        let setupExpectation = expectation(description: "clear zone")
        SKService().clearDefaultZone { (result) in
            switch result {
            case .success:
                break
            default:
                XCTFail()
            }
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 5)
    }
    
    func testInitializersEqual() {
        let wr1 = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
        let wr2 = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room)
        XCTAssertTrue(wr1 == wr2)
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
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                    testExpectation.fulfill()
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
    
    func testDelete() {
        let testExpectation = expectation(description: "testPutStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        client.delete(starter, completion: { (result) in
                            switch result {
                            case .success:
                                break
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            testExpectation.fulfill()
                        })
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
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
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(name: "White", amount: .init(value: 50, unit: .grams))]
                        let image = SKImage(name: "yolobogo", data: self.testImage.jpegData(compressionQuality: 0.5)!)
                        let meal = SKStarterMeal(date: .init(), flour: flour, water: water, image: image)
                        client.feedStarter(meal: meal, completion: { (result) in
                            switch result {
                            case .success:
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
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 20)
    }
    
    func testFetchLastMeal() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(name: "White", amount: .init(value: 50, unit: .grams))]
                        let meal = SKStarterMeal(date: .init(), flour: flour, water: water)
                        client.feedStarter(meal: meal, completion: { (result) in
                            switch result {
                            case .success:
                                XCTAssertTrue(true)
                                sleep(3)
                                client.fetchLastMeal(for: starter, completion: { (result) in
                                    switch result {
                                    case .success:
                                        break
                                    case .failure(let error):
                                        XCTFail(error.localizedDescription)
                                    }
                                    testExpectation.fulfill()
                                })
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                        })
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
    
    func testFetchAllMeals() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(name: "White", amount: .init(value: 50, unit: .grams))]
                        let meals = Array(0..<20).map({_ in SKStarterMeal(date: .init(), flour: flour, water: water)})
                        let op = client.feedStarter(meals: meals, completion: {_ in})
//                        // It takes a sec for CloudKit to receive all of these
                        sleep(10)
                        client.fetchAllMeals(for: starter, dependencies: [op], completion: { (result) in
                            switch result {
                            case .success(let meals):
                                XCTAssert(meals.count == 20, "Expectd 21 meals, only received \(meals.count)")
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            testExpectation.fulfill()
                        })
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 20)
    }
    
    func testFetchMealDetails() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(name: "White", amount: .init(value: 50, unit: .grams))]
                        let image = SKImage(name: "yolobogo", data: self.testImage.jpegData(compressionQuality: 0.5)!)
                        let meals = Array(0..<1).map({_ in SKStarterMeal(date: .init(), flour: flour, water: water, image: image)})
                        let op = client.feedStarter(meals: meals, completion: {_ in})
                        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: {
                            client.fetchAllMeals(for: starter, dependencies: [op], completion: { (result) in
                                switch result {
                                case .success(let meals):
                                    if let meal = meals.first {
                                        client.fetchMealDetails(for: meal, completion: { (result) in
                                            switch result {
                                            case .success(let mealDetail):
                                                XCTAssertNotNil(mealDetail.image)
                                                XCTAssertNotNil(mealDetail.waterRation)
                                                XCTAssertNotNil(mealDetail.flourRations)
                                            case .failure(let error):
                                                XCTFail(error.localizedDescription)
                                            }
                                            testExpectation.fulfill()
                                        })
                                    }
                                case .failure(let error):
                                    XCTFail(error.localizedDescription)
                                }
                            })
                            XCTAssertNotNil(starter)
                        })
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 30)
    }
    
    func testFetchTimeline() {
        let testExpectation = expectation(description: "testFetchStarter")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        let water = SKWaterRation(amount: .init(value: 100, unit: .grams), temperature: .room, encodedSystemFields: nil)
                        let flour = [SKFlourRation(flourName: "Wheat", amount: .init(value: 50, unit: .grams), encodedSystemFields: nil), SKFlourRation(name: "White", amount: .init(value: 50, unit: .grams))]
                        let meals = Array(0..<20).map({_ in SKStarterMeal(date: .init(), flour: flour, water: water)})
                        let checkIns = Array(0..<5).map({_ in SKStarterCheckIn(date: .init(), remarks: "LGTM")})
                        let op = client.feedStarter(meals: meals, completion: {_ in})
                        //                        // It takes a sec for CloudKit to receive all of these
                        let checkInOp = client.checkInStarter(checkIns: checkIns, completion: {_ in})
                        sleep(10)
                        client.fetchTimeline(for: starter, dependencies: [op, checkInOp], completion: { (result) in
                            switch result {
                            case .success(let timeline):
                                XCTAssert(timeline.count == 25, "Expectd 21 meals, only received \(timeline.count)")
                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }
                            testExpectation.fulfill()
                        })
                        XCTAssertNotNil(starter)
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 20)
    }
    
    
    
    func testDeleteZone() {
        let testExpectation = expectation(description: "testDeleteZone")
        SKClient.initialize { (result) in
            switch result {
            case .success(let client):
                let starter = SKStarter(name: "yoloer", feedInterval: 360, birthplace: "Irvine")
                client.put(starter) { (result) in
                    switch result {
                    case .success(let starter):
                        XCTAssertNotNil(starter)
                        let service = SKService()
                        service.clearDefaultZone { (result) in
                            switch result {
                            case .success:
                                break
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
                }
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
        wait(for: [testExpectation], timeout: 10)
    }
}
