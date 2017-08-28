//
//  ViewController.swift
//  FitnessHealthKitApp
//
//  Created by Brent Gammon on 28/08/2017.
//  Copyright © 2017 Brent Gammon. All rights reserved.
//

import UIKit
import HealthKit

import Alamofire

class ViewController: UIViewController {
 let healthStore = HKHealthStore()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func getHeartRateData(_ sender: Any) {
        if HKHealthStore.isHealthDataAvailable() {
            
            //create quanity type
            let stepCounterType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
            
            
            
            //check if it is
            print(healthStore.authorizationStatus(for: stepCounterType!).rawValue)
            
            healthStore.requestAuthorization(toShare: [], read: [stepCounterType!,heartRateType!], completion: { (res, error) in
                if(res){
                    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                    //var x: [String] = [];
                    let heartQuery = HKSampleQuery(sampleType: heartRateType!,
                                                   predicate: nil,
                                                   limit: 1,
                                                   sortDescriptors: [sortDescriptor])
                    {
                        (query, results, error) -> Void in
                        for result in results as! [HKQuantitySample]
                        {
                            
                            //print(result.quantity.doubleValue(for: HKUnit.count()))
                            //print(type(of: result))
                            //print(String(describing: result).components(separatedBy: " "))
                        }
                    }
                    
                    self.healthStore.execute(heartQuery)
                    
                }
            })
        }
    }
    
    @IBAction func getData(_ sender: Any) {
        Alamofire.request("https://jsonplaceholder.typicode.com/users").responseJSON {
            response in print(response)
        }
    }
}

