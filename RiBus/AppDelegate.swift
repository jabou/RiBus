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
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var existingItem: NSManagedObject!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //Connection to Parse.com
        Parse.enableLocalDatastore()
        Parse.setApplicationId("hNdCOyQrE4o0L9YEoK1tiuzlXsAHqnt2cnUfth4H", clientKey: "Wf44FoTiXm2CUlrID1cI5wxsI6axSC2Jt50PPP9w")
        
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
        
        Fabric.with([Crashlytics.self])
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        //MARK: - Update data
        //MARK: Storing timetables

        let parseQuery1 = PFQuery(className: "RiBusTimetable")
        parseQuery1.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                PFObject.pinAllInBackground(objects, block: { (succeeded: Bool, error: NSError?) -> Void in
                    if (error != nil) {
                        print("Error saving: \(error)")
                    } else if (!succeeded){
                        print("Saving operation failed with no error")
                    } else {
                        print("Timetables are updated")
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
                            print("Departments are updated")
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
                                print("Coordinates are updated")
                            }
                        })
                    }
                }
            }
        }
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        
    }
}

