//
//  Model.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 25/04/15.
//  Copyright (c) 2015 Jasmin Abou Aldan. All rights reserved.
//

import Foundation
import CoreData

@objc(Model)
class Model: NSManagedObject {

    @NSManaged var busname: String
    @NSManaged var saturday1: Array<String>
    @NSManaged var saturday2: Array<String>
    @NSManaged var sunday1: Array<String>
    @NSManaged var sunday2: Array<String>
    @NSManaged var workday1: Array<String>
    @NSManaged var workday2: Array<String>
    @NSManaged var updatedAt: NSDate

}