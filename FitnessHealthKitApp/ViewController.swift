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
import AlamofireImage
import FirebaseAuth
import Granola
import SwiftyJSON

class ViewController: UIViewController, LoginButtonDelegate {
    @IBOutlet weak var heartRate: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var getCallButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        heartRate.isHidden = false
        profileImageView.isHidden = false
        getCallButton.isHidden = false
        nameLabel.isHidden = false
        emailLabel.isHidden = false
        uidLabel.isHidden = false
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("log out of application")
        heartRate.isHidden = true
        profileImageView.isHidden = true
        getCallButton.isHidden = true
        nameLabel.isHidden = true
        emailLabel.isHidden = true
        uidLabel.isHidden = true
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
        
        
        print("here a")
        if (FBSDKAccessToken.current()) != nil{
            print("here b")
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            
            Auth.auth().signIn(with: credential) { (user, error) in
                if error != nil {
                    // ...
                    return
                }
                print("here c")
                print(user!)
                self.nameLabel.text = user?.displayName
                self.emailLabel.text = user?.email
                self.uidLabel.text = user?.uid
                
                if let x = user?.photoURL {
                    self.profileImageView.af_setImage(withURL: x)
                }
            }
            
            heartRate.isHidden = false
            profileImageView.isHidden = false
            getCallButton.isHidden = false
            nameLabel.isHidden = false
            emailLabel.isHidden = false
            

        }else {
            print("not logged in")
            heartRate.isHidden = true
            profileImageView.isHidden = true
            getCallButton.isHidden = true
            nameLabel.isHidden = true
            emailLabel.isHidden = true
            uidLabel.isHidden = true
        }


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //sync health data
    
    
    @IBAction func getHeartRateData(_ sender: Any) {
        if HKHealthStore.isHealthDataAvailable() {
            
            //create quanity type
            let stepCounterType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let heartRateType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
            let flightsClimbed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed)
            //let standHours = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.)
            let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
            
            if #available(iOS 11.0, *) {
                let restingHeartRate = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate) //figure how to best handle this
            } else {
                // Fallback on earlier versions
            }
            let restingEnergy = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.basalEnergyBurned)
            let walkingRunningDistance = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
            
            
            
            
            let sleepData = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)
            
            
            //stand hours
            //exercise minutes
            
            
            
            
            
            //check if it is
            print(healthStore.authorizationStatus(for: stepCounterType!).rawValue)
            
            healthStore.requestAuthorization(toShare: [], read: [
                stepCounterType!, //Done
                heartRateType!, //Done
                flightsClimbed!, //Done
                activeEnergyBurned!, //Done
                restingEnergy!, //workaround
                walkingRunningDistance!,
                sleepData! //Done
                
                ], completion: { (res, error) in
                if(res){
                    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                    let today = Date()
                    let lastMonth = Calendar.current.date(byAdding: .day, value: -7, to: today)
                    let predicateDate = HKQuery.predicateForSamples(withStart: lastMonth, end: today)
                    var ajaxObject = [JSON]()
                    
                    
                    
                    let heartQuery = HKSampleQuery(sampleType: heartRateType!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKQuantitySample]
                            {
                                do{
                                    let jsonData = try serializer.json(for: result)
                                    let data  = jsonData.data(using: String.Encoding.utf8)!
                                    let json = JSON(data)
                                    let jsony: JSON = [
                                        self.uidLabel.text! : json["body"]
                                    ]
                                    ajaxObject.append(jsony)
                                } catch {
                                    print("error")
                                    return
                                }
                            }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/heartrate", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
                    
                    let stepCounterQuery = HKSampleQuery(sampleType: stepCounterType!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKQuantitySample]
                        {
                            do{
                                let jsonData = try serializer.json(for: result)
                                let data  = jsonData.data(using: String.Encoding.utf8)!
                                let json = JSON(data)
                                let jsony: JSON = [
                                    self.uidLabel.text! : json["body"]
                                ]
                                ajaxObject.append(jsony)
                            } catch {
                                print("error")
                                return
                            }
                        }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/stepCounter", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
                    
                    
                    let flightsClimbedQuery = HKSampleQuery(sampleType: flightsClimbed!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKQuantitySample]
                        {
                            do{
                                let jsonData = try serializer.json(for: result)
                                let data  = jsonData.data(using: String.Encoding.utf8)!
                                let json = JSON(data)
                                let jsony: JSON = [
                                    self.uidLabel.text! : json["body"]
                                ]
                                ajaxObject.append(jsony)
                            } catch {
                                print("error")
                                return
                            }
                        }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/flightsClimbed", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
                    
                    let activeEnergyBurnedQuery = HKSampleQuery(sampleType: activeEnergyBurned!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKQuantitySample]
                        {
                            do{
                                let jsonData = try serializer.json(for: result)
                                let data  = jsonData.data(using: String.Encoding.utf8)!
                                let json = JSON(data)
                                let jsony: JSON = [
                                    self.uidLabel.text! : json["body"]
                                ]
                                ajaxObject.append(jsony)
                            } catch {
                                print("error")
                                return
                            }
                        }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/activeEnergyBurned", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
                    
                    let walkingRunningDistance = HKSampleQuery(sampleType: walkingRunningDistance!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKQuantitySample]
                        {
                            do{
                                let jsonData = try serializer.json(for: result)
                                let data  = jsonData.data(using: String.Encoding.utf8)!
                                let json = JSON(data)
                                let jsony: JSON = [
                                    self.uidLabel.text! : json["body"]
                                ]
                                ajaxObject.append(jsony)
                            } catch {
                                print("error")
                                return
                            }
                        }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/walkingRunningDistance", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
                    
                    let sleepQuery = HKSampleQuery(sampleType: sleepData!, predicate: predicateDate, limit: 0, sortDescriptors: [sortDescriptor]){
                        (query, results, error) -> Void in
                        let serializer = OMHSerializer()
                        for result in results as! [HKCategorySample]
                        {
                            do{
                                let jsonData = try serializer.json(for: result)
                                let data  = jsonData.data(using: String.Encoding.utf8)!
                                let json = JSON(data)
                                let jsony: JSON = [
                                    self.uidLabel.text! : json["body"]
                                ]
                                ajaxObject.append(jsony)
                            } catch {
                                print("error")
                                return
                            }
                        }
                        let parameters: [String: [JSON]] = [
                            "data" : ajaxObject
                        ]
                        Alamofire.request("http://192.168.1.98:3005/sleepData", method: .post, parameters:  parameters, encoding: URLEncoding.httpBody)
                        //todo handle the reponse
                    }
             
                    
                   
                    self.healthStore.execute(walkingRunningDistance)
                    self.healthStore.execute(sleepQuery)
                    self.healthStore.execute(activeEnergyBurnedQuery)
                    self.healthStore.execute(flightsClimbedQuery)
                    self.healthStore.execute(heartQuery)
                    self.healthStore.execute(stepCounterQuery)
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

