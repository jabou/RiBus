//
//  BusListTableViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 01/11/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import CoreData
import Parse

class BusListTableViewController: UITableViewController {
    
    //MARK: variable declaration
    var lineDirection: NSDictionary!
    var lineNumber: NSArray!
    var sortedArray: Array<String>!
    
    //MARK: Check if database is full
    override func viewWillAppear(animated: Bool) {
        
        let localParseQuery = PFQuery(className: "RiBusTimetable")
        localParseQuery.fromLocalDatastore()
        localParseQuery.findObjectsInBackgroundWithBlock{ (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                
                if(objects!.count == 0){
                    if #available(iOS 8.0, *){
                        let databaseError: UIAlertController = UIAlertController(title: "Database error", message: "Your database is empty, please check your internet connection and try again", preferredStyle: UIAlertControllerStyle.Alert)
                        databaseError.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: {action in
                            self.navigationController?.popViewControllerAnimated(true)
                            return
                        }))
                        self.presentViewController(databaseError, animated: true, completion: nil)
                    }
                    else{
                        let databaseError: UIAlertView = UIAlertView()
                        databaseError.title = "Database error"
                        databaseError.message = "Your database is empty, please check your internet connection and try again"
                        databaseError.addButtonWithTitle("Ok")
                        databaseError.delegate = self
                        databaseError.tag = 1
                        databaseError.show()
                    }
                } else {
                    let parseQuery = PFQuery(className: "RiBusTimetable")
                    parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                        if error == nil {
                            PFObject.pinAllInBackground(objects, block: { (succeeded: Bool, error: NSError?) -> Void in
                                if (error != nil) {
                                    print("Error saving: \(error)")
                                } else if (!succeeded){
                                    print("Saving operation failed with no error")
                                } else {
                                    print("Data is saved")
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    //MARK: -alertViews
    func alertView(View: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        
        //start GPS navigation
        if(View.tag == 1 && buttonIndex == 0){
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    //MARK: Main
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //show navigation bar on info view
        self.navigationItem.title = "Lines"
        
        //remove "Back" name
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton
        
        //MARK: -load data
        //path to database
        let url = NSBundle.mainBundle().URLForResource("DayBusLines", withExtension: "plist")
        //load database into dictionary
        self.lineDirection = NSDictionary(contentsOfURL: url!)
        self.lineNumber = lineDirection.allKeys
        let swArray = lineNumber as! Array<String>
        sortedArray = swArray.sort({(s1,s2) in
            return s1.localizedStandardCompare(s2) == NSComparisonResult.OrderedAscending
        })
        
    }
    
    //if row is selected, clear selection
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: (NSIndexPath!)) {
        self.tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view drawing
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return sortedArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel!.text = sortedArray[indexPath.row]
        cell.detailTextLabel?.text = lineDirection[sortedArray[indexPath.row]] as? String
        
        return cell
    }
    
    //MARK: Sending data to other ViewController-s
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "segueLine"){
            
            let indexPath = self.tableView.indexPathForSelectedRow
            let tabViewController: UITabBarController = segue.destinationViewController as! UITabBarController
            
            //root
            let instance0: TimetableTabBarViewController = segue.destinationViewController as! TimetableTabBarViewController
            instance0.toPass = sortedArray[indexPath!.row] as String
            //workday
            let instance1: WorkdayViewController = tabViewController.viewControllers![0] as! WorkdayViewController
            instance1.toPass = sortedArray[indexPath!.row] as String
            //saturday
            let instance2: SaturdayViewController = tabViewController.viewControllers![1] as! SaturdayViewController
            instance2.toPass = sortedArray[indexPath!.row] as String
            //sunday
            let instance3: SundayHolidaysViewController = tabViewController.viewControllers![2] as! SundayHolidaysViewController
            instance3.toPass = sortedArray[indexPath!.row] as String
            
            //MARK: Open tab with proper date
            var day: Int!
            
            //MARK: -Holidays in 2015
            let holidays = ["01.01.","06.01.","06.04.","01.05.","04.06.","22.06.","25.06.","05.08.","15.08.","08.10.","25.12.","26.12."]
            
            let dayFormat = NSDateFormatter()
            dayFormat.dateFormat = "EEEE"
            
            let dateFormat = NSDateFormatter()
            dateFormat.dateFormat = "dd.MM."
            let date = dateFormat.stringFromDate(NSDate())

            if holidays.contains(date){
                day = 1
            }
            else{
                day = WeekDay.shared.dayOfWeek()
            }
            
            switch day {
                case 2,3,4,5,6:
                    tabViewController.selectedIndex = 0
                case 7:
                    tabViewController.selectedIndex = 1
                case 1:
                    tabViewController.selectedIndex = 2
            default:
                print("error")
            }
        }
    }
}