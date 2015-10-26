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

class ViewController: UIViewController {
    
    
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
    

    override func viewWillAppear(animated: Bool) {
                
        //MARK: Remove "Back" name
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        //MARK: -Save/Update data from Parse.com into CoreData
        
        //Reference to our app delegate
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //Reference moc
        let contxt: NSManagedObjectContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "RiBusTimetable")
        var fetch: [AnyObject]?
        do {
            fetch = try contxt.executeFetchRequest(fetchRequest)
        } catch {
            fetch = nil
            print("Error with fetching data")
        }
        
        //if database is empty
        if fetch?.isEmpty == true{
            
            //MARK: -check internet connection for first update!
            if Connection.shared.isConectedToNetwork(){
                
                ActivityIndicator.shared.startAnimating(self.view, title: "Retriving and Storing data...")
                let query = PFQuery(className: "RiBusTimetable")
                query.findObjectsInBackgroundWithBlock{
                    (objects: [AnyObject]?, error: NSError?) -> Void in
                    
                    if (error == nil){
                        
                        if let data = objects as? [PFObject]{
                            for oneData in data{
                                
                                //Create instance of our data model and init
                                let newItem = NSEntityDescription.insertNewObjectForEntityForName("RiBusTimetable", inManagedObjectContext: contxt) as! Model
                                
                                //Map our properties
                                if let busname = oneData.objectForKey("busname") as? String{
                                    newItem.busname = busname
                                }
                                if let workday1 = oneData.objectForKey("workday1") as? Array<String>{
                                    newItem.workday1 = workday1
                                }
                                if let workday2 = oneData.objectForKey("workday2") as? Array<String>{
                                    newItem.workday2 = workday2
                                }
                                if let saturday1 = oneData.objectForKey("saturday1") as? Array<String>{
                                    newItem.saturday1 = saturday1
                                }
                                if let saturday2 = oneData.objectForKey("saturday2") as? Array<String>{
                                    newItem.saturday2 = saturday2
                                }
                                if let sunday1 = oneData.objectForKey("sunday1") as? Array<String>{
                                    newItem.sunday1 = sunday1
                                }
                                if let sunday2 = oneData.objectForKey("sunday2") as? Array<String>{
                                    newItem.sunday2 = sunday2
                                }
                                if let updatedA = oneData.updatedAt{
                                    newItem.updatedAt = updatedA
                                }
                                do {
                                    try contxt.save()
                                } catch {
                                    print("Save filed")
                                }
                            }
                            ActivityIndicator.shared.stopAnimating()
                        }
                    }
                    else{
                        print(error)
                    }
                }

            }
            else{
                if #available(iOS 8.0,*){
                    let internetError: UIAlertController = UIAlertController(title: "Connection error", message: "Please check your internet connection and try again", preferredStyle: UIAlertControllerStyle.Alert)
                    internetError.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                        self.settings()
                    }))
                    internetError.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    self.presentViewController(internetError, animated: true, completion: nil)
                }
                else{
                    let internetError: UIAlertView = UIAlertView()
                    internetError.title = "Connection error"
                    internetError.message = "Please check your internet connection and try again"
                    internetError.addButtonWithTitle("Ok")
                    internetError.delegate = self
                    internetError.show()
                }
            }
            
        }
        //if database is full, but need to be updated
        else{
            let query = PFQuery(className: "RiBusTimetable")
            query.findObjectsInBackgroundWithBlock{
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if (error == nil){
                    
                    if let data = objects as? [PFObject]{
                        for oneData in data{
                            
                            do{
                                if let allData = try contxt.executeFetchRequest(fetchRequest) as? [Model]{
                                    
                                    for(var i=0 ; i < allData.count ; i++){
                                        
                                        let existingItem:NSManagedObject = allData[i]
                                        if allData[i].busname == oneData.objectForKey("busname") as! String{
                                            if allData[i].updatedAt != oneData.updatedAt{
                                                if let workday1 = oneData.objectForKey("workday1") as? Array<String>{
                                                    existingItem.setValue(workday1, forKey: "workday1")
                                                }
                                                if let workday2 = oneData.objectForKey("workday2") as? Array<String>{
                                                    existingItem.setValue(workday2, forKey: "workday2")
                                                }
                                                if let saturday1 = oneData.objectForKey("saturday1") as? Array<String>{
                                                    existingItem.setValue(saturday1, forKey: "saturday1")
                                                }
                                                if let saturday2 = oneData.objectForKey("saturday2") as? Array<String>{
                                                    existingItem.setValue(saturday2, forKey: "saturday2")
                                                }
                                                if let sunday1 = oneData.objectForKey("sunday1") as? Array<String>{
                                                    existingItem.setValue(sunday1, forKey: "sunday1")
                                                }
                                                if let sunday2 = oneData.objectForKey("sunday2") as? Array<String>{
                                                    existingItem.setValue(sunday2, forKey: "sunday2")
                                                }
                                                if let updatedA = oneData.updatedAt{
                                                    existingItem.setValue(updatedA, forKey: "updatedAt")
                                                }
                                                do {
                                                    try contxt.save()
                                                } catch _ {
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {
                                
                            }
                        }
                    }
                }
                else{
                    print(error)
                }
            }
        }
        
        /*
        //MARK: Ads
        let AddBannerView = ADBannerView(frame: CGRectMake(0, self.view.frame.size.height - 50, 320,38))
        self.view.addSubview(AddBannerView)
        */
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