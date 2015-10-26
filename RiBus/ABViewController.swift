//
//  ABViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 24/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import CoreData

class ABViewController: UIViewController {
    
    //MARK: Variable declaration
    var toPass: String!
    var stationsList: Array<String>!
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
    @IBOutlet weak var lineName: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Functions
    ///Function for opening settings
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
        stationsList = nameForPicker(toPass)

        self.arrivalTime.numberOfLines = 0
        
        //MARK: -data from list for picker name and time
        for singleElement in stationsList{
            var dividedElement = singleElement.componentsSeparatedByString(";")
            let addName = dividedElement[0]
            let addTime = dividedElement[1]
            self.pickerName.append(addName)
            self.pickerTime.append(addTime)
        }
        
        //MARK: -get data from database
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let contxt: NSManagedObjectContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "RiBusTimetable")
        
        do {
            if let allData = try contxt.executeFetchRequest(fetchRequest) as? [Model]{
                for (var i = 0 ; i < allData.count ; i++){
                    if (allData[i].busname == toPass){
                        
                        let tmp1 = JSON(allData[i].workday1)
                        let toList1 = tmp1.arrayObject as! Array<String>
                        workdayList = toList1
                        
                        let tmp2 = JSON(allData[i].saturday1)
                        let toList2 = tmp2.arrayObject as! Array<String>
                        saturdayList = toList2
                        
                        let tmp3 = JSON(allData[i].sunday1)
                        let toList3 = tmp3.arrayObject as! Array<String>
                        sundayList = toList3
                    }
                }
            }

        } catch {
            print("Error fetching data")
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
                calculate2 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeCalculate:"), userInfo: addTime, repeats: true)
                calculate2.fire()
            }
            else if (calculate2.valid){
                calculate2.invalidate()
                calculate1 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeCalculate:"), userInfo: addTime, repeats: true)
                calculate1.fire()
            }
            else{
                calculate1 = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeCalculate:"), userInfo: addTime, repeats: true)
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
            for(var i=0; i<numb; i++){
                
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
    
    //MARK: Fill picker
    func nameForPicker(a: String) -> Array<String>{
    
        let lineNumber = a
        var name: Array<String>!
        
        switch lineNumber{
            case "1":
                name = ["Pećine;0","J.P. Kamova WTC;1","J.P. Kamova;3","Pećine Ž. Kolodvor;4","Sušački neboder;7","Fiumara;9","Trg RH;10","Riječki neboder;11","Brajda;12","Željeznički kolodvor;13","KBC Rijeka;14","Mlaka;16","Novi list;17","Toretta;20","Krnjevo Liburnijska;22","3. Maj;24","Liburnijska - V. Bratonje;26","Kantrida;27","Bazeni Kantrida;30","Dječja bolnica;30","Bivio;34"]
            case "1A":
                name = ["A.K. Miošića;0"," Sušački neboder;2","Fiumara;4","Trg RH;6","Riječki neboder;6","Brajda;8","Željeznički kolodvor;8","KBC Rijeka;10","Mlaka;11","Novi list;13","Toretta;15","Krnjevo Liburnijska;17","3. Maj;20","Liburnijska - V. Bratonje;21","Labinska ulica;23","OŠ Kantrida;23","Šparići;25","Ploče;26","Mate Balote;27","Marčeljeva Draga;28"]
            case "1B":
                name = ["Tower;0","Radnička;4","Podvežica centar;6","Z. Kučića III;8","KBC Sušak;10","Mihanovićeva;11","Drage Ščitara;13","Park heroja;15","Trsat;16","Josipa Kuflaneka;18","Slave Raškaj;18","Strmica;19"]
            case "2":
                name = ["Trsat;0","Trsat groblje;1","Slavka Krautzeka I;2","Slavka Krautzeka II;3","Teta Roža;4","Kumičićeva;6","Sušački neboder;8","Fiumara;10","Trg RH;12","Riječki neboder;12","Brajda;14","Željeznički kolodvor;14","KBC Rijeka;16","Mlaka;17","Novi List;19","Toretta;21","Krnjevo Zametska;23","Zametska;25","Baredice;26","Zamet centar;28","Ul. I.Č. Belog;29","Diračje;30","Dražice;33","Martinkovac I;35","Srdoči;37"]
            case "2A":
                name = ["A.K. Miošića;0","Sušački neboder;2","Fiumara;4","Trg RH;6","Riječki neboder;6","Brajda;8","Nikole Tesle;9","Potok;10","Štranga;11","Tehnički fakultet;12","R. Benčića;14","Toretta;17","Krnjevo Zametska;19","Zametska;21","Baredice;22","Zamet - Bože Vidasa;23","Zamet crkva;24","Zamet tržnica;26","Bože Vidasa;27","Ivana Zavidića;28"]
            case "3":
                name = ["A.K. Miošića;0","Sušački neboder;2","Ivana Grohovca;4","Žrtava fašizma;6","Pomerio park;7","F.I. Guardie;8","N. Tesle;9","KBC Rijeka;11","Mlaka;12","Novi list;14","Toretta;16","Krnjevo Zametska;18","Zametska;20","Becićeva;22","N. Cesta – B. Mohorić;23","Fantini;25","Pilepići;26","Drnjevići;28","J. Mohorića;29","Selinari;30","Šumci;30","Grbci;31"]
            case "3A":
                name = ["Jelačićev trg;0","Trg RH;2","Riječki neboder;2","Brajda;4","Željeznički kolodvor;4","KBC Rijeka;6","Mlaka;7","Novi List;9","Toretta;11","Krnjevo Zametska;13","Zametska;15","Baredice;16","Zamet B. Monjac;18","Braće Mohorić;20","N. Cesta - B. Mohorić;21","Fantini;23","Pilepići;24","Drnjevići;25","Mulci;26","Pužići;28","Trampov breg;29","Bezjaki;30"]
            case "4":
                name = ["Fiumara;0","Palazzo Modello;1","Trg RH;2","Riječki neboder;3","Manzzonijeva;4","1. maja;6","Tizianova;8","Belveder;9","Kozala groblje;10","Ante Kovačića;11","Kapitanovo;12","Kozala - Drenovski put;13","Kozala;15","Vinas;16","Brašćine okretište;17"]
            case "4A":
                name = ["Sv. Katarina;0","Katarina II;1","Katarina I;3","Brašćine;6","Internacionalnih brigada;7","Galenski laboratorij;9","Pulac I;10","Pulac II;12","Vrh Pulca;13"]
            case "5":
                name = ["Jelačićev trg;0","Trg RH;2","Riječki neboder;2","Manzzonijeva;4","1. maja;5","Osječka - F. Kresnika;7","Osječka - Mihačeva Draga;8","Osječka Lipa;10","Osječka zaobilaznica;11","Osječka - Drežnička;12","Osječka - Crkva;13","I.L. Ribara - S. Vukelića;14","I.L. Ribara - M. Ruslambega;15","Staro okretište;16","I.L. Ribara - I. Žorža;17","Bok;18","Severinska;19","OŠ F. Franković;21","Braće Hlača;22","Frkaševo;23","Drenova;24"]
            case "5A":
                    name = ["Osječka - Drežnička;0","Osječka - Crkva;1","Škurinjska cesta I;3","Škurinje spomenik;5","Tibljaši;8"]
            case "5B":
                name = ["Drenova;0","Benaši – B. Francetića;2","B. Francetića – Pešćevac;3","B. Francetića – Tonići;3","B. Francetića;5","Kablarska cesta;6","Kablari;7","Petrci;9"]
            case "6":
                name = ["Podvežica;0","Podvežica centar;1","OŠ Vežica;2","Kvaternikova Tihovac;3","Kvaternikova;4","Kumičićeva;5","Sušački neboder;7","Fiumara;8","Trg RH;10","Riječki neboder;11","Brajda;12","Nikole Tesle;13","Potok;14","Štranga;15","Tehnički fakultet;16","Studentski dom;17","Čandekova;18","Turnić;20","Dom umirovljenika;22","G. Carabino;23","Vidovićeva;24","Novo naselje;25"]
            case "7":
                name = ["Gornja Vežica;0","F. Belulovića - Z. Kučića;1","Zdravka Kučića I;2","Zdravka Kučića II;3","Zdravka Kučića III;4","KBC Sušak;7","Teta Roža;9","Kumičićeva;10","Sušački neboder;13","Fiumara;14","Palazzo Modello;15","Trg RH;16","Riječki neboder;17","Brajda;18","Nikole Tesle;19","Potok;20","Štranga;21","Tehnički fakultet;22","Vukovarska;24","Podmurvice;26","Čepićka;27","Rujevica;27","Pehlin I;30","Pehlin škola;31","Pehlin II;32","Turkovo;34"]
            case "7A":
                name = ["Sveti križ;0","R. Petrovića II;2","R. Petrovića I;3","Sveta Ana;4","KBC Sušak;5","Teta Roža;8","Kumičićeva;9","Sušački neboder;11","Fiumara;13","Palazzo Modello;14","Trg RH;15","Riječki neboder;16","Brajda;17","Nikole Tesle;18","Potok;19","Štranga;20","Tehnički fakultet;21","Vukovarska;23","Podmurvice;25","Čepićka;25","Rujevica;26","Blažićevo;27","Pehlin dj. vrtić;28","Ul. Hosti;29","Hosti;30"]
            case "8":
                let line8 = WeekDay.shared.dayOfWeek()
            
                if(line8 == 7 || line8 == 1){
                    name = ["Trsat;0","Trsat groblje;1","Slavka Krautzeka I;2","Slavka Krautzeka II;3","Mihanovićeva;4","Pošta;5","Paris;6","Vodosprema;7","Bobijevo;9","ZZZ;11","Ivana Grahovca;14","Žrtava fašizma;15","Pomerio park;16","F.I. Guaride;17","Nikole Tesle;19","KBC Rijeka;20","Mlaka - Baračeva;22","Baračeva I;23","Baračeva II;25","Torpedo;27"]
                }
                else{
                    name = ["Sveučilišna avenija;0","Radmile Matejčić;1","KBC Sušak;3","Mihanovićeva;4","Pošta;5","Paris;6","Vodosprema;7","Bobijevo;9","ZZZ;11","Ivana Grahovca;14","Žrtava fašizma;15","Pomerio park;16","F.I. Guaride;17","Nikole Tesle;19","KBC Rijeka;20","Mlaka - Baračeva;22","Baračeva I;23","Baračeva II;25","Torpedo;27"]
                }
            case "8A":
                name = ["Jelačićev trg;0","Fiumara;2","Piramida;4","Kumičićeva;6","Teta Roža;7","KBC Sušak;9","Radmila Matejčić;11","Sveučilišna avenija;13"]
            case "9":
                name = ["Delta;0","Piramida;2","Kumičićeva;3","D.Gervaisa III;4","D.Gervaisa II market;6","D.Gervaisa I Vulk.naselje;7","Radnička;9","OŠ Vežica;11","Podvežica  centar;12","Zdravka Kučića III;14","Sveta Ana;15","Draga pod Ohrušvom;17"," Orlići I;18","Draga Orlići II;19","Draga Brig – dom;20","Draga - Sv. Jakov;21","Draga – Tijani;22","Sv. Kuzam;23","Baraći;25"]
            default:
                print("error in geting pickerName")
        }
        return name
    }
}