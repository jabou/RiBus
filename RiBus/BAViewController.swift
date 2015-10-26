//
//  BAViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 24/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import CoreData

class BAViewController: UIViewController {
    
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
            var devidetElement = singleElement.componentsSeparatedByString(";")
            let addName = devidetElement[0]
            let addTime = devidetElement[1]
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
                        
                        let tmp1 = JSON(allData[i].workday2)
                        let toList1 = tmp1.arrayObject as! Array<String>
                        workdayList = toList1
                        
                        let tmp2 = JSON(allData[i].saturday2)
                        let toList2 = tmp2.arrayObject as! Array<String>
                        saturdayList = toList2
                        
                        let tmp3 = JSON(allData[i].sunday2)
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
        
        let dayFormat = NSDateFormatter()
        dayFormat.dateFormat = "EEEE"
        
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
                        if(difference2<60){
                            hours1 = Int(floor(difference1/60))
                            min1 = Int(floor(difference1%60))
                            min2 = Int(floor(difference2))
                            self.arrivalTime.text = "Bus is departing in approximately:\n\(hours1) h, \(min1) min (at: \(arrival1)).\nNext one departs in approximately:\n\(min2) min (at: \(arrival2))."
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
    }
     
    //MARK: Fill picker
    func nameForPicker(a: String) -> Array<String>{
        
        let lineNumber = a
        var name: Array<String>!
        
        switch lineNumber{
            case "1":
                name = ["Bivio;0","Dječja bolnica;3","Bazeni kantrida;4","Kantrida;6","Liburnijska - V. Bratonje;8","3. Maj;10","Krnjevo Liburnijska;11","Krnjevo Zvonimirova;12","Toretta;14","Novi list;16","Mlaka;18","KBC Rijeka;19","Željeznički kolodvor;20","Brajda;21","Žabica;22","Riva;23","Tržnica;24","Fiumara;26","Piramida - Pećine;28","OŠ Pećine;30","Hotel Jadran;31","Hotel Park;33","Pećine;34"]
            case "1A":
                name = ["Marčeljeva Draga;0","Mate Balote;1","Ploče;2","Šparići;3","OŠ Kantrida;4","Labinska ulica;5","Liburnijska - V. Bratonje;7","3. Maj;9","Krnjevo Liburnijska;10","Krnjevo Zvonimirova;11","Toretta;13","Novi List;15","Mlaka;17","KBC Rijeka;18","Željeznički kolodvor;19","Brajda;20","Žabica;21","Riva;22","Tržnica;23","Fiumara;25","A.K. Miošića;25"]
            case "1B":
                name = ["Strmica;0","Rose Leard;1","Vrlije;1","Trsat;3","Trsat groblje;4","S. Krautzeka I;5","S. Krautzeka II;6","M. Kontuša;8","OŠ Podvežica;9","Radnička;10","Tower;12"]
            case "2":
                name = ["Srdoči;0","Blečići;1","Martinkovac;3","Dražice;5","Diračje;7","Ul. I.Č. Belog;8","Zamet centar; 10","Baredice;11","Zametska;12","Krnjevo Zvonimirova;15","Toretta;17","Novi List;19","Mlaka;20","KBC Rijeka;22","Željeznički kolodvor;23","Brajda;24","Žabica;25","Riva;26","Tržnica;27","Fiumara;28","Piramida;31","Kumičićeva;33","Teta Roža;34","Mihanovićeva;35","Pošta;36","Paris;37","J. Rakovca;37","Vidikovac;38","Trsat crkva;40","Trsat;40"]
            case "2A":
                name = ["Ivana Zavidića;0","Bože Vidasa;1","Zamet tržnica;1","Zamet crkva;4","Zamet - Bože Vidasa;5","Baredice;6","Zametska;7","Krnjevo Zvonimirova;10","Toretta;11","R.Benčića;14","Tehnički fakultet;15","Štranga;17","Potok;18","Željeznički kolodvor;19","Brajda;20","Žabica;21","Riva;22","Tržnica;23","Fiumara;24","A.K. Miošića;25"]
            case "3":
                name = ["Grbci;0","Starci;0","Zamet groblje;1","N. Cesta – B. Mohorić;2","Becićeva;4","Zametska;8","Krnjevo Zvonimirova;10","Toreta;12","Novi list;14","Mlaka;16","KBC Rijeka;17","Željeznički kolodvor;18","Manzzonijeva;19","F.I. Guardie;19","Pomerio Park;21","Žrtava fašizma;21","Novi most;23","A.K. Miošiča;24"]
            case "3A":
                name = ["Bezjaki;0","Trampov breg;1","Pužići;2","Mulci;4","Drnjevići;5","Pilepići;7","Fantini;8","Braće Mohorić;11","Zamet B. Monjac;13","Baredice;14","Zametska;15","Krnjevo Zvonimirova;18","Toretta;19","Novi List;21","Mlaka;23","KBC Rijeka;24","Željeznički kolodvor;26","Brajda;27","Žabica;28","Riva;29","Tržnica;30","Jelačićev trg;30"]
            case "4":
                name = ["Brašćine;0","Kozala – Drenovski put;2","Kapitanovo;3","A. Kovačića;4","Kozala groblje;5","Laginjina;6","Guvernerova palača;9","Fiumara;11"]
            case "4A":
                name = ["Vrh Pulca;0","Pulac II;2","Pulac I;3","Galenski laboratorij;4","Internacionalnih brigada;5","Brašćine;8","Katarina I;9","Katarina II;11","Sv. Katarina;12"]
            case "5":
                name = ["Drenova;0","Frkaševo;1","Braće Hlača;2","OŠ F. Franković;3","Severinska;5","Bok;6","I.L. Ribara - I. Žorža;7","Staro okretište;8","I.L. Ribara - M. Rustambega;9","I.L. Ribara - S. Vukelića;10","Osječka - Crkva;10","Osječka - Drežnička;11","Osječka zaobilaznica;13","Osječka Lipa;14","Osječka - C. Ilijassich;15","Osječka - Mihačeva Draga;16","Osječka - F. Kresnika;17","1. maja;19","Nikole Tesle;20","Brajda;22","Žabica;23","Riva;24","Tržnica;25","Jelačićev trg;25"]
            case "5A":
                name = ["Tibljaši;0","Škurinjska cesta II;2","Škurinje spomenik;3","Škurinjska cesta I;5","Škurinje škola;6","Osječka - Crkva;8","Osječka - Drežnička;8"]
            case "5B":
                name = ["Petrci;0"," Kablari;2","Kablarska cesta;3","B. Francetića;4","B. Francetića – Tonići;6","B. Francetića – Pešćevac;6","Benaši - B. Francetića;7","Drenova;9"]
            case "6":
                name = ["Novo naselje;0","Nova cesta;1","Turnić;3","Čandekova;5","Studentski dom;6","Štranga;9","Potok;10","Željeznički kolodvor;11","Brajda;12","Žabica;13","Riva;14","Tržnica;15","Fiumara;16","Piramida;18","Kumičićeva;20","Kvaternikova;21","Kvaternikova Tihovac;22","OŠ Vežica;23","Podvežica centar;23","Podvežica;24"]
            case "7":
                name = ["Turkovo;0","Pehlin II;3","Pehlin I;5","Rujevica;7","Podmurvice;8","Vukovarska;10","Tehnički fakultet;11","Štranga;12","Potok;14","Željeznički kolodvor;15","Brajda;16","Žabica;17","Riva;18","Tržnica;19","Fiumara;20","Piramida;23","Kumičićeva;25","Teta Roža;26","KBC Sušak;28","Sveta Ana;29","Franje Belulovića;30","Gornja Vežica;32"]
            case "7A":
                name = ["Hosti;0","Ul. Hosti;1","Pehlin dj. vrtić;2","Blažićevo;3","Rujevica;5","Podmurvice;6","Vukovarska;8","Tehnički fakultet;9","Štranga;10","Potok;12","Željeznički kolodvor;13","Brajda;14","Žabica;15","Riva;16","Tržnica;17","Fiumara;18","Piramida;21","Kumičićeva;22","Teta Roža;24","KBC Sušak;25","Sveta Ana;27","R. Petrovića I;28","R. Petrovića II;29","Sveti križ;31"]
            case "8":
                let line8 = WeekDay.shared.dayOfWeek()
            
                if(line8 == 7 || line8 == 1){
                    name = ["Torpedo;0","Baračeva II;1","Baračeva I;3","Mlaka;5","KBC Rijeka;6","Željeznički kolodvor;8","Brajda;9","Žabica;10","Riva;10","Tržnica;11","Titov trg;13","ZZZ;15","Mažuranićev trg;17","Bobijevo;18","Vodosprema;19","Paris;20","J. Rakovca;21","Vidikovac;22","Trsat crkva;23","Trsat;24"]
                }
                else{
                    name = ["Torpedo;0","Baračeva II;1","Baračeva I;3","Mlaka;5","KBC Rijeka;6","Željeznički kolodvor;8","Brajda;9","Žabica;10","Riva;10","Tržnica;11","Titov trg;13","ZZZ;15","Mažuranićev trg;17","Bobijevo;18","Vodosprema;19","Paris;20","J. Rakovca;21","Vidikovac;22","Trsat crkva;23","Trsat;24","Trsat groblje;25","Sveučilišna avenija;26"]
                }
            case "8A":
                name = ["Sveučilišna avenija;0","Slavka Krautzeka I;1","Slavka Krautzeka II;1","Teta Roža;3","Kumičićeva;4","Sušački neboder;7","Fiumara;8","Jelačićev trg;11"]
            case "9":
                name = ["Baraći;0","Sv. Kuzam;2","Draga – Tijani;3","Draga - Sv. Jakov;5","Draga Brig – dom;6","Draga Orlići II;7","Draga Orlići I;8","Draga pod Ohrušvom;9","Sveta Ana;10","KBC Sušak;11","Martina Kontuša;13","OŠ Vežica;14","Radnička;15","D.Gervaisa I Vulk.naselje;16","D.Gervaisa II market;17","D.Gervaisa III;18","Kumičićeva;19","Sušački neboder;21","Fiumara;23","Delta;25"]
            default:
                print("error in geting pickerName")
        }
        return name
    }
}