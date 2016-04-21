//
//  MainTabBarViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 03/01/15.
//  Copyright (c) 2015 Jasmin Abou Aldan. All rights reserved.
//

import UIKit


class IndexData {
    var index: Int!
}

class TimetableTabBarViewController: UITabBarController {
    
    //MARK: -variable declaration
    var toPass: String!
    var send: String!
    var get: Int!
    var indexModel = IndexData()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Timetable"
        
        let timeImage = UIImage(named: "time")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: timeImage, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(TimetableTabBarViewController.arrivalsClicked))
        send = toPass
        
        //remove "Back" name
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        navigationItem.backBarButtonItem = backButton

    }
    
    func arrivalsClicked(){
        performSegueWithIdentifier("arrivals", sender: self)

    }
 
    //MARK: Segues to AB and BA ViewController
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if (segue.identifier == "arrivals"){
            let tabViewController: UITabBarController = segue.destinationViewController as! UITabBarController
            //root
            let instance0: CustomTabBarViewController = segue.destinationViewController as! CustomTabBarViewController
            instance0.toPass = send as String
            instance0.openIndex = indexModel.index //TODO: add index to send!
            //A->B
            let instance1: ABViewController = tabViewController.viewControllers![0] as! ABViewController
            instance1.toPass = toPass as String
            //B->A
            let instance2: BAViewController = tabViewController.viewControllers![1] as! BAViewController
            instance2.toPass = toPass as String
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
