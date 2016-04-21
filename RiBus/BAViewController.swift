//
//  BAViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 24/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import CoreData
import Parse

class BAViewController: UIViewController {
    
    //MARK: Variable declaration
    var toPass: String!
    var departureList: Array<String> = []
    var pickerName: Array<String>! = ["--pick a station--"]
    var pickerTime: Array<String>! = [""]
    var originalTime: Array<String>!
    var increasedTime: Array<String>!
    var workdayList: Array<String>!
    var saturdayList: Array<String>!
    var sundayList: Array<String>!
    var calculate1 = NSTimer()
    var calculate2 = NSTimer()

    
    //MARK: Labels connection
    @IBOutlet weak var stationsPicker: UIPickerView!
    @IBOutlet weak var lineName: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Functions    
    func settings(){
        if #available(iOS 8.0, *){
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //MARK: -UI Background color
        self.view.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0)
        
        //MARK: -set linename and station list into pickerview
        self.lineName.text = toPass
        //MARK: -data from list for picker name and time
        let parseQuery = PFQuery(className: "RiBusDepartments")
        parseQuery.fromLocalDatastore()
        parseQuery.whereKey("busname", equalTo: toPass)
        parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if (error == nil){
                if let data = objects as? [PFObject]{
                    for oneData in data{
                        
                        if self.toPass == "8"{
                            if WeekDay.shared.dayOfWeek() == 7 || WeekDay.shared.dayOfWeek() == 1 {
                                if let departures = oneData.objectForKey("times2") as? Array<String>{
                                    self.departureList = departures
                                }
                            } else {
                                if let departures = oneData.objectForKey("times2b") as? Array<String>{
                                    self.departureList = departures
                                }
                            }
                        } else {
                            if let departures = oneData.objectForKey("times2") as? Array<String>{
                                self.departureList = departures
                            }
                        }
                        
                        
                        
                    }
                    
                    for singleElement in self.departureList{
                        var dividedElement = singleElement.componentsSeparatedByString(";")
                        let addName = dividedElement[0]
                        let addTime = dividedElement[1]
                        self.pickerName.append(addName)
                        self.pickerTime.append(addTime)
                    }
                    
                    self.stationsPicker.reloadAllComponents()
                    
                }
            } else{
                print(error)
            }
        }
        
        self.arrivalTime.numberOfLines = 0

        let parseQuery2 = PFQuery(className: "RiBusTimetable")
        parseQuery2.fromLocalDatastore()
        parseQuery2.whereKey("busname", equalTo: toPass)
        parseQuery2.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if (error == nil){
                if let data = objects as? [PFObject]{
                    for oneData in data{
                        if let workday2 = oneData.objectForKey("workday2") as? Array<String>{
                            self.workdayList = workday2
                        }
                        if let saturday2 = oneData.objectForKey("saturday2") as? Array<String>{
                            self.saturdayList = saturday2
                        }
                        if let sunday2 = oneData.objectForKey("sunday2") as? Array<String>{
                            self.sundayList = sunday2
                        }
                    }
                }
            }
        }
        
    }
    
    //MARK: Setup PickerView
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = pickerName[row]
        let customPicker = NSAttributedString(string: title, attributes: [NSFontAttributeName:UIFont(name: "Avenir-Book", size: 15.0)!,NSForegroundColorAttributeName:UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)])
        return customPicker
    }
    
    func numberOfComponentsInPickerView(pickerAB: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerAB: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return pickerName.count
    }
    
    func pickerView(pickerAB: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String{
        return pickerName[row]
    }
    
    //MARK: Time Calculation and Print
    func pickerView(pickerAB: UIPickerView!, didSelectRow row: Int, inComponent component: Int){
        
        //MARK: -turn off all counters and clean label
        if(row == 0){
            if calculate1.valid{
                calculate1.invalidate()
            }
            else if(calculate2.valid){
                calculate2.invalidate()
            }
            arrivalTime.text = ""
        }
        else{
            
            let addTime = pickerTime[row] as NSString
            
            if (calculate1.valid){
                calculate1.invalidate()
                calculate2 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(BAViewController.timeCalculate(_:)), userInfo: addTime, repeats: true)
                calculate2.fire()
            }
            else if (calculate2.valid){
                calculate2.invalidate()
                calculate1 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(BAViewController.timeCalculate(_:)), userInfo: addTime, repeats: true)
                calculate1.fire()
            }
            else{
                calculate1 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(BAViewController.timeCalculate(_:)), userInfo: addTime, repeats: true)
                calculate1.fire()
            }
        }
    }
    
    

    //MARK: Calculating function
    func timeCalculate(val: NSTimer){
        
        //empty increased array every time
        increasedTime = []
        var take: AnyObject!
        let addTime = val.userInfo as! NSString
        
        //MARK: -Holidays in 2015
        let holidays = ["01.01.","06.01.","06.04.","01.05.","04.06.","22.06.","25.06.","05.08.","15.08.","08.10.","25.12.","26.12."]
        
        let dayFormat = NSDateFormatter()
        dayFormat.dateFormat = "EEEE"
        
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "dd.MM."
        let date = dateFormat.stringFromDate(NSDate())
        
        var day: Int!
        
        if holidays.contains(date){
            day = 1
        }
        else{
            day = WeekDay.shared.dayOfWeek()
        }
        
        switch day {
        case 2,3,4,5,6:
            take = workdayList
        case 7:
            take = saturdayList
        case 1:
            take = sundayList
        default:
            print("error")
        }
        
        if(take == nil){
            self.arrivalTime.text = "This bus does not drive today."
        }
            //MARK: -Time Calculation
        else{
            
            let json1 = JSON(take)
            self.originalTime = json1.arrayObject as! Array<String>!
            
            let interval = addTime.doubleValue
            let numb = self.originalTime.count
            let time = NSDate()
            let format = NSDateFormatter()
            format.dateFormat = "HH:mm"
            let now = format.stringFromDate(time)
            var cleanOriginalTime: String!
            
            for singleOriginalTime in self.originalTime{
                if singleOriginalTime.rangeOfString("G") != nil {
                    cleanOriginalTime = singleOriginalTime.stringByReplacingOccurrencesOfString("G", withString: "")
                }
                else if singleOriginalTime.rangeOfString("*") != nil{
                    cleanOriginalTime = singleOriginalTime.stringByReplacingOccurrencesOfString("*", withString: "")
                }
                else{
                    cleanOriginalTime = singleOriginalTime
                }
                
                let toTime1 = format.dateFromString(cleanOriginalTime)
                let calculated = toTime1?.dateByAddingTimeInterval(60 * interval)
                let toArrayBack = format.stringFromDate(calculated!)
                self.increasedTime.append(toArrayBack)
            }
            
            var arrival1: String!
            var arrival2: String!
            
            //compare current time with list of times
            for i in 0 ..< numb {
                
                if(now<self.increasedTime[i]){
                    
                    arrival1 = self.increasedTime[i]
                    
                    if(i+1 < numb){
                        arrival2 = self.increasedTime[i+1]
                    }
                        //if all second buses were gone
                    else{
                        arrival2 = nil
                    }
                    //bus was find, exit for loop
                    break
                }
                    //else, all buses were gone
                else{
                    arrival1 = nil //vrijeme koje nam treba je ono 1. u nizu
                    arrival2 = nil //vrijeme kada drugi autobus dolazi
                }
            }
            
            let timenow = format.dateFromString(now)!
            var arrivalnow1: NSDate!
            var arrivalnow2: NSDate!
            var difference1: Double!
            var difference2: Double!
            var min1: Int!
            var min2: Int!
            var min3: Int!
            var hours1: Int!
            var hours2: Int!
            
            //MARK: -Printing
            if(arrival1 == nil){
                self.arrivalTime.text = "There are no more buses today on this line."
            }
            else{
                //First bus comes, second not
                if(arrival2 == nil){
                    arrivalnow1 = format.dateFromString(arrival1)!
                    difference1 = arrivalnow1.timeIntervalSinceDate(timenow) / 60
                    
                    if (difference1 < 60){
                        min1 = Int(floor(difference1))
                        self.arrivalTime.text = "Bus is departing in approximately:\n\(min1) min (at: \(arrival1)).\nAnd it is the last bus of the day!"
                    }
                    else{
                        hours1 = Int(floor(difference1/60))
                        min1 = Int(floor(difference1%60))
                        self.arrivalTime.text = "Bus is departing in approximately:\n\(hours1) h, \(min1) min (at: \(arrival1)).\nAnd it is the last bus of the day!"
                    }
                }
                    //Both buses comes
                else{
                    arrivalnow1 = format.dateFromString(arrival1)!
                    arrivalnow2 = format.dateFromString(arrival2)!
                    difference1 = arrivalnow1.timeIntervalSinceDate(timenow) / 60
                    difference2 = arrivalnow2.timeIntervalSinceDate(timenow) / 60
                    
                    if difference2 < 0 {
                        
                        let midnight = "00:00"
                        let midnightTime = format.dateFromString(midnight)
                        
                        let minuteToMidnight = "23:59"
                        let minuteToMidnightTime = format.dateFromString(minuteToMidnight)
                        
                        let midnightToArrival = arrivalnow2.timeIntervalSinceDate(midnightTime!) / 60
                        let currentToMidnight = minuteToMidnightTime!.timeIntervalSinceDate(timenow) / 60
                        
                        difference2 = midnightToArrival + currentToMidnight + 1
                    }
                    
                    if (difference1 < 60){
                        min1 = Int(floor(difference1))
                        if(difference2 < 60){
                            min2 = Int(floor(difference2))
                            self.arrivalTime.text = "Bus is departing in approximately:\n\(min1) min (at: \(arrival1)).\nNext one departs in approximately:\n\(min2) min (at: \(arrival2))."
                        }
                        else{
                            hours2 = Int(floor(difference2/60))
                            min3 = Int(floor(difference2%60))
                            self.arrivalTime.text = "Bus is departing in approximately:\n\(min1) min (at: \(arrival1)).\nNext one departs in approximately:\n\(hours2) h, \(min3) min (at: \(arrival2))."
                        }
                    }
                    else{
                        if(difference2<60){
                            hours1 = Int(floor(difference1/60))
                            min1 = Int(floor(difference1%60))
                            min2 = Int(floor(difference2))
                            self.arrivalTime.text = "Bus is departing in approximately:\n\(hours1) h, \(min1) min (at: \(arrival1)).\nNext one departs in approximately:\n\(min2) min (at: \(arrival2))."
                        }
                        else{
                            hours1 = Int(floor(difference1/60))
                            min1 = Int(floor(difference1%60))
                            hours2 = Int(floor(difference2/60))
                            min3 = Int(floor(difference2%60))
                            self.arrivalTime.text = "Bus is departing in approximately:\n\(hours1) h, \(min1) min (at: \(arrival1)).\nNext one departs in approximately:\n\(hours2) h, \(min3) min (at: \(arrival2))."
                        }
                    }
                }
            }
        }
    }
}