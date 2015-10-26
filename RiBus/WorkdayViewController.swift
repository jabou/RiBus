//
//  WorkdayViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 24/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import CoreData

class WorkdayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    //MARK: Variable declaration
    var toPass: String!
    var lineDirection: NSDictionary!
    var workdayList1: Array<String> = []
    var workdayList2: Array<String> = []
    var dataForCell: Array<String> = []
    var dict = [String:Array<String>]()
    var clocks: Array<String>!
    
    //MARK: Labels connection
    @IBOutlet weak var lineNumber: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var workdayTableView: UITableView!
    @IBOutlet weak var switcher: UISegmentedControl!
    @IBOutlet weak var notice: UILabel!
    
    //MARK: Functions    
    func settings(){
        if #available(iOS 8.0, *){
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: -send index 0 to main tab
        let model = (self.tabBarController as! TimetableTabBarViewController).indexModel
        model.index = 0
        
        
        //MARK: - Connect to bus list
        let url = NSBundle.mainBundle().URLForResource("DayBusLines", withExtension: "plist")
        self.lineDirection = NSDictionary(contentsOfURL: url!)
        
        //MARK: - UI background
        self.view.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0)
        
        //MARK: -set UI Text
        let lineName = lineDirection.valueForKey(toPass) as! String
        
        let reverseLineName = reverseWords(lineName)
        let font = NSDictionary(object: UIFont(name: "Avenir-Book", size: 15)!, forKey: NSFontAttributeName)
        lineNumber.text = toPass
        infoLabel.text = "Choose starting point:"

        //MARK: -set switcher
        switcher.setTitleTextAttributes(font as [NSObject: AnyObject], forState: UIControlState.Normal)
        switcher.tintColor = UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)
        let fromA = lineName.componentsSeparatedByString("-")
        let fromB = reverseLineName.componentsSeparatedByString("-")
        switcher.setTitle("\(fromA[0])", forSegmentAtIndex: 0)
        switcher.setTitle("\(fromB[0])", forSegmentAtIndex: 1)
        
        //MARK: -tableView setup
        workdayTableView.delegate = self
        workdayTableView.dataSource = self
        workdayTableView.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0)
        workdayTableView.separatorStyle = UITableViewCellSeparatorStyle.None

        //MARK: -get data from database
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let contxt: NSManagedObjectContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "RiBusTimetable")
        do {
            if let allData = try contxt.executeFetchRequest(fetchRequest) as? [Model]{
                for (var i=0 ; i < allData.count ; i++){
                    if allData[i].busname == toPass{
                        
                        let tmp1 = JSON(allData[i].workday1)
                        let toList1 = tmp1.arrayObject as! Array<String>
                        workdayList1 = toList1
                        
                        let tmp2 = JSON(allData[i].workday2)
                        let toList2 = tmp2.arrayObject as! Array<String>
                        workdayList2 = toList2
                    }
                }
            }
        } catch {
            print("Error fetching data")
        }
        
        if workdayList1.isEmpty == false{
            dataForCell = workdayList1
            
            //MARK: - create dictionary from array
            var arr = Array<String>()
            let first = dataForCell[0]
            let start = first.substringWithRange(Range(start: first.startIndex, end: first.startIndex.advancedBy(2)))
            var current = start as String
            
            for (var i=0 ; i<dataForCell.count ; i++) {
                
                let next = dataForCell[i]
                let nexts = next.substringWithRange(Range(start: next.startIndex, end: next.startIndex.advancedBy(2))) as String
                
                
                if current != nexts{
                    dict[current] = arr
                    current = nexts
                    arr = []
                }
                arr.append(dataForCell[i])
                if dataForCell.last == next {
                    dict[current] = arr
                }
                
            }
            
            let unSortedClocks1 = [String](dict.keys)
            clocks = unSortedClocks1.sort()
            
            workdayTableView.reloadData()
        }
        else{
            let warning = UILabel(frame: CGRectMake(0, self.view.bounds.height/2, self.view.bounds.width, 20))
            warning.textAlignment = NSTextAlignment.Center
            warning.textColor = UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)
            warning.font = UIFont(name: "Avenir-Medium", size: 15)
            warning.text = "This bus does not drive on selected day"
            
            self.view.addSubview(warning)
        }
        
        //MARK: -notice setup
        let noticeList = ["1","2","2A","4","6","7","7A","8"]
            
        if noticeList.contains(toPass){
                notice.text = "G - the bus is driving to the garage"
        }
        switch toPass{
        case "1B":
            notice.text = "* - the bus departes from Trsat to Strmica"
        case "3A":
            notice.text = "* - during school, bus drives to Zamet trznica"
        case "4A":
            notice.text = "* - the bus departes from Brašćine"
        case "5A":
            notice.text = "* - the bus departes from Ž.Kolodvor to Tibljaši"
        case "5B":
            notice.text = "* - during school, bus drives from OŠ F. Franković"
        default:
            break
        }
    }
    
    //MARK: - fill tableview
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dict.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sortedDict = dict.sort{$0.0 < $1.0}
        var i = 0
        for (_,value) in sortedDict{
            
            if section == i{
                return value.count
            }
            i++
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, 15))
        label.font = UIFont(name: "Avenir-Heavy", size: 15)
        label.textColor = UIColor(red: 24/255.0, green: 11/255.0, blue: 64/255.0, alpha: 1.0)
        label.backgroundColor = UIColor(red: 216/255.0, green: 227/255.0, blue: 236/255.0, alpha: 1.0)

        for (var i = 0 ; i<dict.count ; i++){
            
            label.text = "  \(clocks[i]) h"
            if section == i{
                return label
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 22
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let sortedDict = dict.sort{$0.0 < $1.0}
        var i = 0
        let cell = tableView.dequeueReusableCellWithIdentifier("workdaycell", forIndexPath: indexPath) as UITableViewCell
        
        cell.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 0.5)
        cell.textLabel?.textColor = UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        
        for (_,value) in sortedDict{
            if indexPath.section == i{
                cell.textLabel?.text = value[indexPath.row]
            }
            i++
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func reverseWords(s: String) -> String {
        var tmp = s.componentsSeparatedByString("-")
        tmp = Array(tmp.filter{ $0 != "" }.reverse())
        return tmp.joinWithSeparator(" - ")
    }
    
    //MARK: - switcher action
    @IBAction func switcherAction(sender: UISegmentedControl){
        
        let model = (self.tabBarController as! TimetableTabBarViewController).indexModel

        switch switcher.selectedSegmentIndex{
        case 0:
            //selectIndex = 0
            model.index = 0
            if workdayList1.isEmpty == false{
                dataForCell = workdayList1
                var arr = Array<String>()
                let first = dataForCell[0]
                let start = first.substringWithRange(Range(start: first.startIndex, end: first.startIndex.advancedBy(2)))
                var current = start as String
                
                for (var i=0 ; i<dataForCell.count ; i++) {
                    
                    let next = dataForCell[i]
                    let nexts = next.substringWithRange(Range(start: next.startIndex, end: next.startIndex.advancedBy(2))) as String
                    
                    
                    if current != nexts{
                        dict[current] = arr
                        current = nexts
                        arr = []
                    }
                    arr.append(dataForCell[i])
                    if dataForCell.last == next {
                        dict[current] = arr
                    }
                    
                }
                let unSortedClocks1 = [String](dict.keys)
                clocks = unSortedClocks1.sort()
                workdayTableView.reloadData()
            }
        case 1:
            model.index = 1
            if workdayList2.isEmpty == false{
                dataForCell = workdayList2
                var arr = Array<String>()
                let first = dataForCell[0]
                let start = first.substringWithRange(Range(start: first.startIndex, end: first.startIndex.advancedBy(2)))
                var current = start as String
                
                for (var i=0 ; i<dataForCell.count ; i++) {
                    
                    let next = dataForCell[i]
                    let nexts = next.substringWithRange(Range(start: next.startIndex, end: next.startIndex.advancedBy(2))) as String
                    
                    
                    if current != nexts{
                        dict[current] = arr
                        current = nexts
                        arr = []
                    }
                    arr.append(dataForCell[i])
                    if dataForCell.last == next {
                        dict[current] = arr
                    }
                }
                let unSortedClocks1 = [String](dict.keys)
                clocks = unSortedClocks1.sort()
                workdayTableView.reloadData()
            }
        default:
            break
        }
    }
}