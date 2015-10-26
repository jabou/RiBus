//
//  AppDelegate.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 31/10/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import Parse
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var existingItem: NSManagedObject!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //Connection to Parse.com
        Parse.setApplicationId("nQ0cWqzhn2J7J05dxs7OwkHEZqEIHr7am3WGbqGW", clientKey: "sqcEWs2ZZ08mK7ADJHBDzKAmSN904JOS43d7uFVe")
        PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)

        PFAnonymousUtils.logInWithBlock {
            (user: PFUser?, error: NSError?) -> Void in
            if error != nil || user == nil{
                NSLog("Anonymous login failed.")
            } else {
                NSLog("Anonymous user logged in.")
            }
        }
        
        //Status bar background color and text color
        UINavigationBar.appearance().barTintColor = UIColor(red: 161/255.0, green: 151/255.0, blue: 131/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor(red: 235/255.0, green: 244/255.0, blue: 252/255.0, alpha: 1.0)
        let titleColor: NSDictionary = [NSForegroundColorAttributeName: UIColor(red: 235/255.0, green: 244/255.0, blue: 252/255.0, alpha: 1.0)]
        UINavigationBar.appearance().titleTextAttributes = titleColor as? [String : AnyObject]
        
        //TabBar color and appearance
        UITabBar.appearance().backgroundColor = UIColor(red: 145/255.0, green: 136/255.0, blue: 119/255.0, alpha: 1.0)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 145/255.0, green: 136/255.0, blue: 119/255.0, alpha: 1.0)], forState:.Normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)], forState:.Selected)
        UITabBarItem.appearance().setTitleTextAttributes([NSFontAttributeName:UIFont(name: "Avenir-Book", size: 14)!], forState: .Normal)
        
              return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        checkDatabase()

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        checkDatabase()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    //MARK: - CoreData
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("TimetablesLocal", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("RiBus.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            
        } catch {

            // repport error
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            
            /*
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
            */
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    //MARK: - CoreData Saving support
    func saveContext(){
        
        if managedObjectContext.hasChanges{
            do{
                try managedObjectContext.save()
            } catch {
                /*
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserrir.userInfo)")
                abort()
                */
            }
        }
    }
    
    func checkDatabase(){
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let contxt: NSManagedObjectContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "RiBusTimetable")
        var fetch: [AnyObject]?
        
        do {
            fetch = try contxt.executeFetchRequest(fetchRequest)
        } catch {
            fetch = nil
            print("Error with fetching data")
        }
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        
        if fetch?.isEmpty == false{
            
            let query = PFQuery(className: "RiBusTimetable")
            query.findObjectsInBackgroundWithBlock{
                (objects: [AnyObject]?, error: NSError?) -> Void in
                
                if (error == nil){
                    
                    if let data = objects as? [PFObject]{
                        for oneData in data{
                            
                            do {
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
                                                } catch {
                                                    print("Save filed")
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch let error as NSError{
                                print("Fetch failed: \(error.localizedDescription)")
                            }
                        }
                        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

                    }
                }
                else{
                    print(error)
                }
            }
        }
    }
    
}

