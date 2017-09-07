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
            
           // getFBUserData()

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
            
            
            
            //check if it is
            print(healthStore.authorizationStatus(for: stepCounterType!).rawValue)
            
            healthStore.requestAuthorization(toShare: [], read: [stepCounterType!,heartRateType!], completion: { (res, error) in
                if(res){
                    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                    let today = Date()
                    let lastMonth = Calendar.current.date(byAdding: .day, value: -30, to: today)
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
                                    print(type(of:json["body"]))
                                    ajaxObject.append(json["body"])
                                } catch {
                                    print("error")
                                    return
                                }
                                
                            }
                        Alamofire.request("http://192.168.1.98:3005/", method: .post, parameters:  ["data": ajaxObject], encoding: URLEncoding.httpBody)
                    }
                    
                    //need dict [date][array of values]
                    
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

