//
//  SaturdayViewController.swift
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

class SaturdayViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Variable declaration
    var toPass: String!
    var lineDirection: NSDictionary!
    var saturdayList1: Array<String> = []
    var saturdayList2: Array<String> = []
    var dataForCell: Array<String> = []
    var dict = [String:Array<String>]()
    var clocks: Array<String>!
    var notice1: String!
    var notice2: String!
    
    //MARK: Labels connection
    @IBOutlet weak var lineNumber: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var saturdayTableView: UITableView!
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
        saturdayTableView.delegate = self
        saturdayTableView.dataSource = self
        saturdayTableView.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0)
        saturdayTableView.separatorStyle = UITableViewCellSeparatorStyle.None
        
        let parseQuery = PFQuery(className: "RiBusTimetable")
        parseQuery.fromLocalDatastore()
        parseQuery.whereKey("busname", equalTo: toPass)
        parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if (error == nil){
                if let data = objects as? [PFObject]{
                    for oneData in data{
                        if let saturday1 = oneData.objectForKey("saturday1") as? Array<String>{
                            self.saturdayList1 = saturday1
                        }
                        if let saturday2 = oneData.objectForKey("saturday2") as? Array<String>{
                            self.saturdayList2 = saturday2
                        }
                        
                        self.notice1 = oneData.objectForKey("sat1notice") as? String
                        self.notice2 = oneData.objectForKey("sat2notice") as? String
                        self.notice.text = self.notice1
                    }
                    
                    if (!self.saturdayList1.isEmpty){
                        self.dataForCell = self.saturdayList1
                        //MARK: - create dictionary from array
                        var arr = Array<String>()
                        let first = self.dataForCell[0]
                        let start = first.substringWithRange(first.startIndex ..< first.startIndex.advancedBy(2))
                        var current = start as String
                        
                        for i in 0 ..< self.dataForCell.count {
                            
                            let next = self.dataForCell[i]
                            let nexts = next.substringWithRange(next.startIndex ..< next.startIndex.advancedBy(2)) as String
                            
                            
                            if current != nexts{
                                self.dict[current] = arr
                                current = nexts
                                arr = []
                            }
                            arr.append(self.dataForCell[i])
                            if self.dataForCell.last == next {
                                self.dict[current] = arr
                            }
                            
                        }
                        let unSortedClocks1 = [String](self.dict.keys)
                        self.clocks = unSortedClocks1.sort()
                        self.saturdayTableView.reloadData()
                    }
                    else{
                        let warning = UILabel(frame: CGRectMake(0, self.view.bounds.height/2, self.view.bounds.width, 20))
                        warning.textAlignment = NSTextAlignment.Center
                        warning.textColor = UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)
                        warning.font = UIFont(name: "Avenir-Medium", size: 15)
                        warning.text = "This bus does not drive on selected day"
                        
                        self.view.addSubview(warning)
                    }
                }
            }
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
            i += 1
        }
        return 0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let label = UILabel(frame: CGRectMake(0, 0, tableView.bounds.size.width, 15))
        label.font = UIFont(name: "Avenir-Heavy", size: 15)
        label.textColor = UIColor(red: 24/255.0, green: 11/255.0, blue: 64/255.0, alpha: 1.0)
        
        label.backgroundColor = UIColor(red: 216/255.0, green: 227/255.0, blue: 236/255.0, alpha: 1.0)
        for i in 0 ..< dict.count {
            
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
        let cell = tableView.dequeueReusableCellWithIdentifier("saturdaycell", forIndexPath: indexPath) as UITableViewCell
        
        cell.backgroundColor = UIColor(red: 237/255.0, green: 247/255.0, blue: 254/255.0, alpha: 1.0)
        cell.textLabel?.textColor = UIColor(red: 32/255.0, green: 22/255.0, blue: 80/255.0, alpha: 1.0)
        cell.textLabel?.textAlignment = NSTextAlignment.Center
        
        for (_,value) in sortedDict{
            if indexPath.section == i{
                cell.textLabel?.text = value[indexPath.row]
            }
            i += 1
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
    
    @IBAction func switcherAction(sender: UISegmentedControl){
        
        let model = (self.tabBarController as! TimetableTabBarViewController).indexModel
        
        switch switcher.selectedSegmentIndex{
        case 0:
            model.index = 0
            if (!saturdayList1.isEmpty){
                dict.removeAll()
                saturdayTableView.reloadData()
                dataForCell = saturdayList1
                var arr = Array<String>()
                let first = dataForCell[0]
                let start = first.substringWithRange(first.startIndex ..< first.startIndex.advancedBy(2))
                var current = start as String
                
                for i in 0 ..< dataForCell.count {
                    
                    let next = dataForCell[i]
                    let nexts = next.substringWithRange(next.startIndex ..< next.startIndex.advancedBy(2)) as String
                    
                    
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
                self.notice.text = self.notice1
                saturdayTableView.reloadData()
            }
        case 1:
            model.index = 1
            if (!saturdayList2.isEmpty){
                dict.removeAll()
                saturdayTableView.reloadData()
                dataForCell = saturdayList2
                var arr = Array<String>()
                let first = dataForCell[0]
                let start = first.substringWithRange(first.startIndex ..< first.startIndex.advancedBy(2))
                var current = start as String
                
                for i in 0 ..< dataForCell.count {
                    
                    let next = dataForCell[i]
                    let nexts = next.substringWithRange(next.startIndex ..< next.startIndex.advancedBy(2)) as String
                    
                    
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
                self.notice.text = self.notice2
                saturdayTableView.reloadData()
            }
        default:
            break
        }
    }
    
}