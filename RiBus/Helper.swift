//
//  Helper.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 24/03/15.
//  Copyright (c) 2015 Jasmin Abou Aldan. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

public class ActivityIndicator{
    
    let backgroundView = UIView()
    let loadingLabel = UILabel()
    let activityIndicator = UIActivityIndicatorView()
    
    class var shared: ActivityIndicator{
        struct Static{
            static let instance: ActivityIndicator = ActivityIndicator()
        }
        return Static.instance
    }
    
    public func startAnimating(view: UIView, title: String = "Loading..."){
        backgroundView.frame = CGRectMake(0, 0, 130, 130)
        backgroundView.center = view.center
        backgroundView.backgroundColor = UIColor(red: 39/255, green: 38/255, blue: 39/255, alpha: 0.9)
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 10
        
        loadingLabel.frame = CGRectMake(0, 0, 130, 80)
        loadingLabel.backgroundColor = UIColor.clearColor()
        loadingLabel.textColor = UIColor.whiteColor()
        loadingLabel.adjustsFontSizeToFitWidth = true
        loadingLabel.textAlignment = NSTextAlignment.Center
        loadingLabel.center = CGPointMake(backgroundView.bounds.width/2, backgroundView.bounds.height/2 + 30)
        loadingLabel.text = title
        
        activityIndicator.frame = CGRectMake(0, 0, activityIndicator.bounds.size.width, activityIndicator.bounds.size.height)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
        activityIndicator.center = CGPointMake(backgroundView.bounds.width/2, backgroundView.bounds.height/2 - 10)
        
        backgroundView.addSubview(activityIndicator)
        backgroundView.addSubview(loadingLabel)
        view.addSubview(backgroundView)
        
        activityIndicator.startAnimating()
    }
    
    public func stopAnimating(){
        activityIndicator.stopAnimating()
        backgroundView.removeFromSuperview()
    }
}

public class Connection{
    
    class var shared: Connection{
        struct Static{
            static let instance: Connection = Connection()
        }
        return Static.instance
    }

    public func isConectedToNetwork() -> Bool{
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(&zeroAddress, {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }) else {
            return false
        }
        
        var flags : SCNetworkReachabilityFlags = []
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == false {
            return false
        }
        
        let isReachable = flags.contains(.Reachable)
        let needsConnection = flags.contains(.ConnectionRequired)
        return (isReachable && !needsConnection)
    }
}

public class WeekDay{
    
    class var shared: WeekDay{
        struct Static {
            static let instance: WeekDay = WeekDay()
        }
        return Static.instance
    }
    
    public func dayOfWeek() -> Int{
        let todayDate = NSDate()
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let myComponents = myCalendar?.components(NSCalendarUnit.Weekday, fromDate: todayDate)
        let weekDay = myComponents!.weekday
        return weekDay
    }
}

