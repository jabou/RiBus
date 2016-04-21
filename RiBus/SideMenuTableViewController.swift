//
//  SideMenuTableViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 11/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit

protocol SideMenuTableViewControllerDelegate{
    func sideMenuControlDidSelectRow(tableView: UITableView, indexPath: NSIndexPath)
}

class SideMenuTableViewController: UITableViewController {
    
    //MARK: Variable Declaration
    var delegate: SideMenuTableViewControllerDelegate?
    var tableData: Array<String> = []
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }
        else{
            return tableData.count
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return nil
        }
        else{
            return "Day"
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell!
        
        if cell == nil {
            
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
            
            cell!.backgroundColor = UIColor.clearColor()
            cell!.textLabel!.textColor = UIColor(red: 20/255, green: 11/255, blue: 62/255, alpha: 1.0)

            let selectedView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: cell!.frame.size.width, height: cell!.frame.size.height))
            selectedView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3) //kad je oznaceno, prozirno crna
            
            cell!.selectedBackgroundView = selectedView
        }
        
        if indexPath.section == 0{
            cell!.textLabel?.text = "All"
        }
        else{
            cell!.textLabel!.text = tableData[indexPath.row] // ispis teksta (broj autobusa)
        }
        return cell!
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 45.0
    }

    //MARK: -Index ID in delegate, and deselect selection
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true)
        delegate?.sideMenuControlDidSelectRow(tableView, indexPath: indexPath)
    }
}