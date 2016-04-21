//
//  SideMenu.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 11/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit

protocol SideMenuDelegate{
    func sideMenuDidSelectButtonAtIndex(tableView: UITableView, index: Int,section: Int)
}

class SideMenu: NSObject, SideMenuTableViewControllerDelegate {
    
    //MARK: Variable declaration
    let menuWidth: CGFloat = 100.0
    let sideMenuTableViewTopInsert: CGFloat = 64.0
    let sideMenuContainerView: UIView = UIView()
    let sideMenuTableViewController: SideMenuTableViewController = SideMenuTableViewController()
    let originalView: UIView!
    var delegate: SideMenuDelegate?
    var isSideMenuOpen: Bool = false
    
    
    override init(){
        originalView = UIView()
        super.init()
        
    }


    //MARK: Inicialization
    init(sourceView: UIView, menuItems: Array<String>){
        originalView = sourceView
        sideMenuTableViewController.tableData = menuItems
        super.init()
        createSideMenu()
    }
    
    //MARK: Menu apperiance
    func createSideMenu(){
        
        //MARK: -Frame/Container
        sideMenuContainerView.frame = CGRectMake(isSideMenuOpen ? originalView.frame.size.width - menuWidth : originalView.frame.size.width + 1.0,originalView.frame.origin.y,menuWidth,originalView.frame.size.height)
        sideMenuContainerView.backgroundColor = UIColor.clearColor()
        sideMenuContainerView.layer.shadowOffset = CGSizeMake(-2.0, -2.0)
        sideMenuContainerView.layer.shadowRadius = 2.0
        sideMenuContainerView.layer.shadowOpacity = 0.125
        sideMenuContainerView.layer.shadowPath = UIBezierPath(rect: sideMenuContainerView.bounds).CGPath
        originalView.addSubview(sideMenuContainerView)
        
        //Blur effect for iOS8
        if #available(iOS 8.0, *){
            let blurView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.Light))
            blurView.frame = sideMenuContainerView.bounds
            sideMenuContainerView.addSubview(blurView)
        }
        
        //MARK: -Table Cell
        sideMenuTableViewController.delegate = self
        sideMenuTableViewController.tableView.frame = sideMenuContainerView.bounds //okvir je unutar ruba containera
        sideMenuTableViewController.tableView.separatorStyle = UITableViewCellSeparatorStyle.None //micemo separator izmedu redaka (celija)
        if #available(iOS 8.0, *){
            sideMenuTableViewController.tableView.backgroundColor = UIColor.clearColor()
        }
        else{
            sideMenuTableViewController.tableView.backgroundColor = UIColor(red: 246/255, green: 244/255, blue: 240/255, alpha: 1.0)
        }
        sideMenuTableViewController.tableView.contentInset = UIEdgeInsetsMake(sideMenuTableViewTopInsert, 0, 0, 0)
        sideMenuTableViewController.tableView.reloadData()
        sideMenuContainerView.addSubview(sideMenuTableViewController.tableView)
        
    }
    
    //MARK: Open/Close menu
    func showSideMenu(shouldOpen: Bool){
        
        isSideMenuOpen = shouldOpen
        
        var destinationFrame: CGRect
        
        destinationFrame = CGRectMake(shouldOpen ? originalView.frame.size.width - menuWidth : originalView.frame.size.width + 2.0,0,menuWidth,sideMenuContainerView.frame.size.height)
        
        UIView.animateWithDuration(0.4, animations: {() -> Void in
            self.sideMenuContainerView.frame = destinationFrame
        })
    }
    
    //MARK: -Send index and section ID in delegate
    func sideMenuControlDidSelectRow(tableView: UITableView, indexPath: NSIndexPath) {
        delegate?.sideMenuDidSelectButtonAtIndex(tableView, index: indexPath.row, section: indexPath.section)
    }
   
}
