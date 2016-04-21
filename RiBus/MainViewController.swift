//
//  ViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 31/10/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import CoreLocation
import iAd
import CoreData
import Foundation
import SystemConfiguration
import Parse


class MainViewController: UIViewController {
    
    
    //MARK: variable declaration
    let manager = CLLocationManager()
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    //MARK: Funcions
    //MARK: open settings app
    func settings(){
        if #available(iOS 8.0,*){
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    //Kod tebe je to onCreate()
    override func viewWillAppear(animated: Bool) {
        //MARK: Remove "Back" name
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        let parseQuery = PFQuery(className: "RiBusTimetable")
        parseQuery.fromLocalDatastore()
        parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if (objects!.count == 0){
                    self.parseQuery(true)
                } else {
                    self.parseQuery(false)
                }
            }
        }
    }
    
    func parseQuery(isFirstTime: Bool){
        
        //MARK: Storing timetables
        
        if (isFirstTime){
            ActivityIndicator.shared.startAnimating(self.view, title: "Retrieving and storing data...")
        }

        let parseQuery1 = PFQuery(className: "RiBusTimetable")
        parseQuery1.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                PFObject.pinAllInBackground(objects, block: { (succeeded: Bool, error: NSError?) -> Void in
                    if (error != nil) {
                        print("Error saving: \(error)")
                    } else if (!succeeded){
                        print("Saving operation failed with no error")
                    } else {
                        print("Timetables are saved")
                    }
                })
            }
            
            
            //MARK: Storing departures
            
            let parseQuery2 = PFQuery(className: "RiBusDepartments")
            parseQuery2.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                if error == nil {
                    PFObject.pinAllInBackground(objects, block: { (succeeded: Bool, error: NSError?) -> Void in
                        if (error != nil) {
                            print("Error saving: \(error)")
                        } else if (!succeeded){
                            print("Saving operation failed with no error")
                        } else {
                            print("Departments are saved")
                        }
                    })
                }
                
                //MARK: Storing coordinates
                
                let parseQuery3 = PFQuery(className: "RiBusCoordinates")
                parseQuery3.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                    if error == nil {
                        PFObject.pinAllInBackground(objects, block: { (succeeded: Bool, error: NSError?) -> Void in
                            if (error != nil) {
                                print("Error saving: \(error)")
                            } else if (!succeeded){
                                print("Saving operation failed with no error")
                            } else {
                                print("Coordinates are saved")
                            }
                        })
                    }
                }
            }
            
            
            if (isFirstTime){
                ActivityIndicator.shared.stopAnimating()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        //MARK: Title and style (fond, size) for "RiBus"
        let titleLabel: UILabel = UILabel(frame: CGRectMake(0, 0, 0, 30))
        titleLabel.font = UIFont(name: "Avenir-Medium", size: 30)
        titleLabel.backgroundColor = UIColor.clearColor()
        titleLabel.textColor = UIColor(red: 235/255.0, green: 244/255.0, blue: 252/255.0, alpha: 1.0)
        titleLabel.text = "RiBus"
        self.navigationController?.navigationBar.topItem?.titleView = titleLabel

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}