//
//  ViewController.swift
//  FitnessHealthKitApp
//
//  Created by Brent Gammon on 28/08/2017.
//  Copyright © 2017 Brent Gammon. All rights reserved.
//

import UIKit
import HealthKit
import FacebookLogin
import FBSDKLoginKit
import Alamofire

class ViewController: UIViewController, LoginButtonDelegate {
    @IBOutlet weak var heartRate: UIButton!
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        heartRate.isHidden = false
        getFBUserData()
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("log out of application")
        heartRate.isHidden = true
        let loginManager = LoginManager()
        loginManager.logOut()
    }
    
  
    
    
 
    
  
 let healthStore = HKHealthStore()
     var dict : [String : AnyObject]!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = CGPoint(x: 190, y: 630)

        view.addSubview(loginButton)
        loginButton.delegate = self

        if (FBSDKAccessToken.current()) != nil{
            heartRate.isHidden = false
            getFBUserData()

        }else {
            print("not logged in")
            heartRate.isHidden = true
        }


    }


    //function is fetching the user data
    func getFBUserData(){
        print("hello world")
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! [String : AnyObject]
                    print(result!)
                    print(self.dict["name"]!)
                    print(self.dict["email"]!)
                    var x: [String : AnyObject]! = self.dict["picture"]!["data"]!! as! [String : AnyObject]
                    print(x["url"]!)
                }
            })
        }
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
                            print(String(describing: result).components(separatedBy: " "))
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

