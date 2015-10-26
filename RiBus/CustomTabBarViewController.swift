//
//  CustomTabBarViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 26/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit

class CustomTabBarViewController: UITabBarController {

    
    var toPass: String!
    var lineDirection: NSDictionary!
    var openIndex: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Variable declaration and inicialization
        let url = NSBundle.mainBundle().URLForResource("DayBusLines", withExtension: "plist")
        self.lineDirection = NSDictionary(contentsOfURL: url!)
        let lineName = lineDirection.valueForKey(toPass) as! String
        let reverseLineName = reverseWords(lineName)
        
        let fromA = lineName.componentsSeparatedByString("-")
        let fromB = reverseLineName.componentsSeparatedByString("-")
        
        //MARK: TAB names
        let tabItems = self.tabBar.items as [UITabBarItem]!
        let tabItem0 = tabItems[0] as UITabBarItem
        let tabItem1 = tabItems[1] as UITabBarItem
        tabItem0.title = "From: \(fromA[0])"
        tabItem1.title = "From: \(fromB[0])"
        
        self.navigationItem.title = "Departures"
        
        //MARK: Preselect tab with index from segment controller
        if openIndex == 0{
            selectedIndex = 0
        }
        else if openIndex == 1{
            selectedIndex = 1
        }
    }

    func reverseWords(s: String) -> String {
        var tmp = s.componentsSeparatedByString("-")
        tmp = Array(tmp.filter{ $0 != "" }.reverse())
        return tmp.joinWithSeparator(" - ")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}