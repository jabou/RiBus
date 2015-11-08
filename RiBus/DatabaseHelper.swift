//
//  DatabaseHelper.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 31/10/15.
//  Copyright © 2015 Jasmin Abou Aldan. All rights reserved.
//

import Foundation

struct DatabaseColumn {
    static let Busname = "busname"
    static let Workday1 = "workday1"
    static let Workday2 = "workday2"
    static let Saturday1 = "saturday1"
    static let Saturday2 = "saturday2"
    static let Sunday1 = "sunday1"
    static let Sunday2 = "sunday2"
    static let UpdatedAt = "updatedAt"
}

struct DatabaseTable {
    static let LocalDayTimetable = "dayTimetable"
}

class DatabaseHelper {
    
    var dbManager: DBManager = DBManager(databaseFilename: "LocalBusTimetables.sql")
    
    func insertData(busName: String, workday1: String, workday2: String, saturday1: String, saturday2: String, sunday1: String, sunday2: String, updatedAt: Double){
        let query = "INSERT INTO \(DatabaseTable.LocalDayTimetable)(busname,workday1,workday2,saturday1,saturday2,sunday1,sunday2,updatedAt) VALUES (\"\(busName)\",\"\(workday1)\",\"\(workday2)\",\"\(saturday1)\",\"\(saturday2)\",\"\(sunday1)\",\"\(sunday2)\",\(updatedAt));"
        dbManager.executeQuery(query)
    }
    
    func updateData(busName: String, workday1: String, workday2: String, saturday1: String, saturday2: String, sunday1: String, sunday2: String, updatedAt: Double){
        let query = "UPDATE \(DatabaseTable.LocalDayTimetable) SET \(DatabaseColumn.Workday1)=\"\(workday1)\",\(DatabaseColumn.Workday2)=\"\(workday2)\",\(DatabaseColumn.Saturday1)=\"\(saturday1)\",\(DatabaseColumn.Saturday2)=\"\(saturday2)\",\(DatabaseColumn.Sunday1)=\"\(sunday1)\",\(DatabaseColumn.Sunday2)=\"\(sunday2)\",\(DatabaseColumn.UpdatedAt)=\(updatedAt) WHERE \(DatabaseColumn.Busname)=\"\(busName)\";"
        dbManager.executeQuery(query)
    }
    
    func deleteData(){
        let query = "DELETE FROM \(DatabaseTable.LocalDayTimetable);"
        dbManager.executeQuery(query)
    }
    
    func getWorkday1(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Workday1) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")

        return result
    }
    
    func getWorkday2(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Workday2) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")

        return result
    }
    
    func getSaturday1(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Saturday1) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")

        return result
    }
    
    func getSaturday2(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Saturday2) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")

        return result
    }
    
    func getSunday1(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Sunday1) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")
        
        return result
    }
    
    func getSunday2(busName: String) -> Array<String>{
        let query = "SELECT \(DatabaseColumn.Sunday2) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busName)\";"
        let queryResult = dbManager.loadDataFromDB(query)
        let jsonToArray = JSON(queryResult)[0].arrayObject as! Array<String>
        let result = jsonToArray[0].componentsSeparatedByString(",")
        
        return result
    }
    
    func getBusname(index: Int) -> String{
        let query = "SELECT \(DatabaseColumn.Busname) FROM \(DatabaseTable.LocalDayTimetable);"
        let queryResult = JSON(dbManager.loadDataFromDB(query))
        var busNameList = [String]()
        
        for (var i=0; i<queryResult.count; i++){
            busNameList.append((queryResult[i][0]).stringValue)
        }
        
        let result = busNameList.sort { (s1, s2) -> Bool in
            return s1.localizedStandardCompare(s2) == NSComparisonResult.OrderedAscending
        }

        return result[index]
    }
    
    func isEmpty() -> Bool{
        let query = "SELECT count(*) FROM \(DatabaseTable.LocalDayTimetable)"
        let queryResult = JSON(dbManager.loadDataFromDB(query))[0][0].intValue
        
        if (queryResult > 0){
            return false
        } else {
            return true
        }
    }
    
    func numberOfLines() -> Int{
        let query = "SELECT count(*) FROM \(DatabaseTable.LocalDayTimetable)"
        let queryResult = JSON(dbManager.loadDataFromDB(query))[0][0].intValue
        return queryResult
    }
    
    func updatedAt(busname: String) -> NSDate{
        let query = "SELECT \(DatabaseColumn.UpdatedAt) FROM \(DatabaseTable.LocalDayTimetable) WHERE \(DatabaseColumn.Busname) = \"\(busname)\";"
        let queryResult = JSON(dbManager.loadDataFromDB(query))[0][0].doubleValue
        let result = NSDate(timeIntervalSince1970: queryResult)
        return result
    }
}







