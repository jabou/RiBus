//
//  MapsViewController.swift
//  RiBus
//
//  Created by Jasmin Abou Aldan on 23/12/14.
//  Copyright (c) 2014 Jasmin Abou Aldan. All rights reserved.
//

import UIKit
import MapKit
import Foundation
import SystemConfiguration
import Parse
import CoreLocation

extension Array {
    func get(index: Int) -> Element? {
        if 0 <= index && index < count {
            return self[index]
        } else {
            return nil
        }
    }
}

class MapsViewController: UIViewController, SideMenuDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //MARK: variable declaration
    var sideMenu: SideMenu = SideMenu()
    var stationsData: Array<String> = []
    var lineDirection: NSDictionary!
    var lineNumber: NSArray!
    var coord1: Array<String> = []
    var coord2: Array<String> = []
    var directionNames: Array<String> = []
    var centerCoordinates: Array<Double> = []
    var spanValue: Double = 0.0
    var sortedArray: Array<String>!
    let manager = CLLocationManager()
    let navigationError: UIAlertView = UIAlertView()
    let navigationAlert: UIAlertView = UIAlertView()
    let positionError: UIAlertView = UIAlertView()
    internal var dest: String!
    internal var name: String!
    internal var direction1: Array<String>!
    internal var direction2: Array<String>!
    internal var lineNmb: String!
    internal var dirA: String!
    internal var dirB: String!
    internal var CLLocationA: Double!
    internal var CLLocationB: Double!
    internal var spanVaule: Double!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var linNumb: UILabel!
    @IBOutlet weak var direct: UILabel!
    @IBOutlet weak var rightEdgeGestureView: UIView!
    
    //MARK: Funcions
    func openMenuButtonTapped() {
        
        if(sideMenu.isSideMenuOpen){
            closeSideMenu()
        }
        else{
            sideMenu.showSideMenu(true)
            mapView.scrollEnabled = false
        }
    }
    
    func showSwipe(recognizer: UIScreenEdgePanGestureRecognizer){
        if(recognizer.state == UIGestureRecognizerState.Began){
            sideMenu.showSideMenu(true)
            mapView.scrollEnabled = false
        }
    }
    
    func closeSideMenu(){
        sideMenu.showSideMenu(false)
        mapView.scrollEnabled = true
    }
    
    func settings(){
        if #available(iOS 8.0, *){
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    //MARK: Main
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: Maps setup
        mapView.mapType = MKMapType.Standard
        mapView.showsUserLocation = true
        mapView.showsPointsOfInterest = false
        mapView.showsBuildings = false
        if #available(iOS 8.0, *){
            mapView.pitchEnabled = true
        }
        else{
            mapView.pitchEnabled = false
        }
        mapView.delegate = self
        
        //MARK: Customize navigation bar on maps view
        self.navigationItem.title = "Stations"
        let image: UIImage = UIImage(named: "menu.png")!
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MapsViewController.openMenuButtonTapped))
        self.linNumb.text = "All"
        self.direct.text = ""
        
        //MARK: gestures
        let showGestureRecognizer: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(MapsViewController.showSwipe(_:)))
        showGestureRecognizer.edges = UIRectEdge.Right
        rightEdgeGestureView.addGestureRecognizer(showGestureRecognizer)
        
        let hideGestureRecognizer1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(MapsViewController.closeSideMenu))
        hideGestureRecognizer1.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(hideGestureRecognizer1)
        let hideGestureRecognizer2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MapsViewController.closeSideMenu))
        hideGestureRecognizer2.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(hideGestureRecognizer2)
        
        //Zoom on Rijeka
        let zoomLocation = CLLocationCoordinate2DMake(45.336148, 14.445957)
        let span = MKCoordinateSpanMake(0.19, 0.19)
        let region = MKCoordinateRegion(center: zoomLocation, span: span)
        mapView.setRegion(region, animated: true)
        
        //MARK: Setup location manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest //acc in 5 m
        if #available(iOS 8.0, *){
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        
        //MARK: Load data from DayBusLines
        //path to database
        let path = NSBundle.mainBundle().URLForResource("DayBusLines", withExtension: "plist")
        //load database into dictionary
        self.lineDirection = NSDictionary(contentsOfURL: path!)
        self.lineNumber = lineDirection.allKeys
        let swArray = lineNumber as! Array<String>
        sortedArray = swArray.sort({(s1,s2) in
            return s1.localizedStandardCompare(s2) == NSComparisonResult.OrderedAscending
        })

        //sidebar
        sideMenu = SideMenu(sourceView: self.view, menuItems: sortedArray)
        sideMenu.delegate = self
        
        //First remove all pins, and then add all pins to map
        if(self.mapView.annotations.isEmpty == false){
            self.mapView.removeAnnotations(self.mapView.annotations)
        }
        
        //MARK: -data from list for picker name and time
        let parseQuery = PFQuery(className: "RiBusCoordinates")
        parseQuery.fromLocalDatastore()
        parseQuery.whereKey("busname", equalTo: "all")
        parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
            if (error == nil){
                if let data = objects as? [PFObject]{
                    for oneData in data{
                        
                        if let fetchedData = oneData.objectForKey("coordinates1") as? Array<String>{
                            self.stationsData = fetchedData
                        }
                    }
                    
                    //Put all pins (stations) on map
                    for el in self.stationsData {
                        
                        let tmp = el.componentsSeparatedByString(";")
                        let latitude = tmp[0] as NSString
                        let longitude = tmp[1] as NSString
                        let name = tmp[2]
                        let lines = tmp[3]
                        
                        let lat = latitude.doubleValue
                        let long = longitude.doubleValue
                        
                        let station = MKPointAnnotation()
                        let station_coordinates = CLLocationCoordinate2DMake(lat,long)
                        station.coordinate = station_coordinates
                        //station.setCoordinate(station_coordinates)
                        station.title = name
                        station.subtitle = lines
                        self.mapView.addAnnotation(station)
                    }
                    
                }
            } else{
                print(error)
            }
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //stop updating location to save battery
        manager.stopUpdatingLocation()
    }

    //MARK: Maps
    
    //MARK: -change pin annotation picture, and add "info" button
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        //return nil so map view can draws blue dot for standard user location
        if annotation is MKUserLocation{
            return nil
        }
        //try reuse pin
        let reuseID = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID)
        
        //if pin can not be reused, create new
        if pinView == nil{
            pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            
            //let button = UIButton.buttonWithType(UIButtonType.InfoDark) as UIButton
            let buttonImage: UIImage = UIImage(named: "navigation")!
            let button = UIButton(type: UIButtonType.Custom) as UIButton
            button.frame = CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)
            button.setImage(buttonImage, forState: UIControlState.Normal)
            pinView!.rightCalloutAccessoryView = button
        }
        else{
            pinView!.annotation = annotation
        }
        pinView!.image = UIImage(named: "pinstation")
        
        return pinView
    }
    
    //MARK: -info button action
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        //authorization status
        switch CLLocationManager.authorizationStatus(){
            case .Denied, .NotDetermined, .Restricted:
                if #available(iOS 8.0, *){
                    let navigation: UIAlertController = UIAlertController(title: "Navigation error", message: "You need to allow location access", preferredStyle: UIAlertControllerStyle.Alert)
                    navigation.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                    self.settings()
                    }))
                    navigation.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    self.presentViewController(navigation, animated: true, completion: nil)
                }
                else{
                    navigationError.title = "Navigation error"
                    navigationError.message = "You need to allow location access"
                    navigationError.addButtonWithTitle("Ok")
                    navigationError.delegate = self
                    navigationError.tag = 1
                    navigationError.show()
                }
            default:
                if #available(iOS 8.0, *){
                    let navigation: UIAlertController = UIAlertController(title: "Navigation", message: "Would you like to start navigation?", preferredStyle: UIAlertControllerStyle.Alert)
                    navigation.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {action in
                        if(Connection.shared.isConectedToNetwork()){
                            let latitude = annotationView.annotation!.coordinate.latitude
                            let longitude = annotationView.annotation!.coordinate.longitude
                            self.dest = "\(latitude),\(longitude)"
                            self.name = annotationView.annotation!.title!
                            self.provideDirections(self.dest, name: self.name)
                        }
                        else{
                            let internetError: UIAlertController = UIAlertController(title: "Connection error", message: "Please check your internet connection and try again", preferredStyle: UIAlertControllerStyle.Alert)
                            internetError.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                                self.settings()
                            }))
                            internetError.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {action in
                                self.navigationController?.popViewControllerAnimated(true)
                                return
                            }))
                            self.presentViewController(internetError, animated: true, completion: nil)
                        }
                    }))
                    navigation.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
                    self.presentViewController(navigation, animated: true, completion: nil)
                }
                else{
                    if Connection.shared.isConectedToNetwork(){
                        let latitude = annotationView.annotation!.coordinate.latitude
                        let longitude = annotationView.annotation!.coordinate.longitude
                        dest = "\(latitude),\(longitude)"
                        name = annotationView.annotation!.title!
                        navigationAlert.title = "Navigation"
                        navigationAlert.message = "Would you like to start navigation?"
                        navigationAlert.addButtonWithTitle("Yes")
                        navigationAlert.addButtonWithTitle("No")
                        navigationAlert.delegate = self
                        navigationAlert.tag = 2
                        navigationAlert.show()
                    }
                    else{
                        let internetError = UIAlertView()
                        internetError.title = "Connection error"
                        internetError.message = "Please check your internet connection and try again"
                        internetError.addButtonWithTitle("Ok")
                        internetError.delegate = self
                        internetError.tag = 5
                        internetError.show()
                    }
                }
        }
    }
    
    //MARK: -add pins into map
    func pins(coordinates1: Array<String>, coordinates2: Array<String>, linNumb: String,direction: Array<String>,CLLocation: Array<Double>,span: Double) {
        
        //coordinates and names
        direction1 = coordinates1
        direction2 = coordinates2
        lineNmb = linNumb
        dirA = direction[0]
        dirB = direction[1]
        CLLocationA = CLLocation[0]
        CLLocationB = CLLocation[1]
        spanVaule = span
        
        //popup Window for choosing direction
        if #available(iOS 8.0,*){
            
            let alert : UIAlertController = UIAlertController(title: "Direction", message: "Select a direction for bus no. \(lineNmb).", preferredStyle: UIAlertControllerStyle.Alert)
            
            alert.addAction(UIAlertAction(title: dirA, style:.Default, handler: {action in
                
                let zoomLocation = CLLocationCoordinate2DMake(self.CLLocationA, self.CLLocationB)
                let span = MKCoordinateSpanMake(self.spanVaule, self.spanVaule)
                let region = MKCoordinateRegion(center: zoomLocation, span: span)
                self.mapView.setRegion(region, animated: true)
                
                self.linNumb.text = self.lineNmb
                self.direct.text = self.dirA
                
                if(self.mapView.annotations.isEmpty == false){
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }

                
                for el in self.direction1 {
                    
                    let tmp = el.componentsSeparatedByString(";")
                    let latitude = tmp[0] as NSString
                    let longitude = tmp[1] as NSString
                    let name = tmp[2]
                    
                    let lat = latitude.doubleValue
                    let long = longitude.doubleValue
                    
                    let station1 = MKPointAnnotation()
                    let station_coordinates = CLLocationCoordinate2DMake(lat,long)
                    station1.coordinate = station_coordinates
                    //station1.setCoordinate(station_coordinates)
                    station1.title = name
                    if let notice = tmp.get(3){
                        station1.subtitle = notice
                    }
                    self.mapView.addAnnotation(station1)
                }
            }))
            
            alert.addAction(UIAlertAction(title: dirB, style:.Default, handler: {action in
                
                let zoomLocation = CLLocationCoordinate2DMake(self.CLLocationA, self.CLLocationB)
                let span = MKCoordinateSpanMake(self.spanVaule, self.spanVaule)
                let region = MKCoordinateRegion(center: zoomLocation, span: span)
                self.mapView.setRegion(region, animated: true)
                
                self.linNumb.text = self.lineNmb
                self.direct.text = self.dirB
                
                if(self.mapView.annotations.isEmpty == false){
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                
                for el in self.direction2 {
                    
                    let tmp = el.componentsSeparatedByString(";")
                    let latitude = tmp[0] as NSString
                    let longitude = tmp[1] as NSString
                    let name = tmp[2]
                    
                    let lat = latitude.doubleValue
                    let long = longitude.doubleValue
                    
                    let station2 = MKPointAnnotation()
                    let station_coordinates = CLLocationCoordinate2DMake(lat,long)
                    station2.coordinate = station_coordinates
                    //station2.setCoordinate(station_coordinates)
                    station2.title = name
                    if let notice = tmp.get(3){
                        station2.subtitle = notice
                    }
                    self.mapView.addAnnotation(station2)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style:.Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else{
            
            let pinDirection = UIAlertView(title: "Direction", message: "Select a direction for bus no. \(lineNmb).", delegate: nil, cancelButtonTitle: "Cancel", otherButtonTitles: dirA,dirB)
            pinDirection.delegate = self
            pinDirection.tag = 3
            pinDirection.show()
        }
    }
    
    //MARK: Start navigation
    func provideDirections(dest: String, name: String){
        
        let destination = dest
        let pinName = name
        
        CLGeocoder().geocodeAddressString(destination, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            
            if error != nil {
                //TODO: some allert with error?
            }
            else{
                let request = MKDirectionsRequest()
                request.source = MKMapItem.mapItemForCurrentLocation()
                
                //Convert corelocation destination to mapkit placemark
                let placemark = placemarks!.first as CLPlacemark!
                
                let destinationCoordinates = placemark.location!.coordinate
                
                //get placemark of destination adress
                let destination = MKPlacemark(coordinate: destinationCoordinates, addressDictionary: nil)
                //rename from "Unknown location" into station name
                let mapItem = MKMapItem(placemark: destination)
                mapItem.name = pinName
                request.destination = mapItem
                
                //set transportation method to any (Walking and Driveing)
                request.transportType = MKDirectionsTransportType.Any
                
                //get direction
                let directions = MKDirections(request: request)
                directions.calculateDirectionsWithCompletionHandler{(response: MKDirectionsResponse?, error: NSError?) in
                    
                //display direction on Apple maps with standard maps and walking as first option
                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking, MKLaunchOptionsMapTypeKey: MKMapType.Standard.rawValue]
                MKMapItem.openMapsWithItems([response!.destination], launchOptions: launchOptions as? [String : AnyObject])
                }
            }
        })
    }
    
    //MARK: Selected buttons (menu and alertView)
    //MARK: -menu
    func sideMenuDidSelectButtonAtIndex(tableView: UITableView, index: Int, section: Int) {
        //All bus lines
        if section == 0 {
            closeSideMenu()
            viewDidLoad()
        }
        //List of bus lines
        else{
            
            let selectedCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: section))
            let cellText = selectedCell?.textLabel?.text
            
            
            let parseQuery = PFQuery(className: "RiBusCoordinates")
            parseQuery.fromLocalDatastore()
            parseQuery.whereKey("busname", equalTo: cellText!)
            parseQuery.findObjectsInBackgroundWithBlock { (objects: [AnyObject]?, error: NSError?) -> Void in
                if (error == nil){
                    if let data = objects as? [PFObject]{
                        for oneData in data{
                            
                            if let fetchedData1 = oneData.objectForKey("coordinates1") as? Array<String>{
                                self.coord1 = fetchedData1
                            }
                            if let fetchedData2 = oneData.objectForKey("coordinates2") as? Array<String>{
                                self.coord2 = fetchedData2
                            }
                            if let fetchData3 = oneData.objectForKey("direction") as? Array<String>{
                                self.directionNames = fetchData3
                            }
                            if let fetchData4 = oneData.objectForKey("center") as? Array<Double>{
                                self.centerCoordinates = fetchData4
                            }
                            if let fetchData5 = oneData.objectForKey("span") as? Double{
                                self.spanValue = fetchData5
                            }
                            
                            self.closeSideMenu()
                            self.pins(self.coord1, coordinates2: self.coord2, linNumb: cellText!, direction: self.directionNames, CLLocation: self.centerCoordinates, span: self.spanValue)
                        }
                        
                        
                        
                    }
                } else{
                    print(error)
                }
            }
        }
    }
    
    //MARK: -alertViews
    func alertView(View: UIAlertView!, clickedButtonAtIndex buttonIndex: Int){
        
        //start GPS navigation
        if(View.tag == 2 && buttonIndex == 0){
            if(Connection.shared.isConectedToNetwork()){
                self.provideDirections(dest, name: name)
            }
            else{
                if #available(iOS 8.0, *){
                    let internetError: UIAlertController = UIAlertController(title: "Connection error", message: "Please check your internet connection and try again", preferredStyle: UIAlertControllerStyle.Alert)
                    internetError.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                        self.settings()
                    }))
                    internetError.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {action in
                        self.navigationController?.popViewControllerAnimated(true)
                        return
                    }))
                    self.presentViewController(internetError, animated: true, completion: nil)
                }
                else{
                    let internetError = UIAlertView()
                    internetError.title = "Connection error"
                    internetError.message = "Please check your internet connection and try again"
                    internetError.addButtonWithTitle("Ok")
                    internetError.delegate = self
                    internetError.tag = 5
                    internetError.show()
                }
            }
        }
        //show pins for selected
        else if(View.tag == 3 && buttonIndex == 1){
            
            let zoomLocation = CLLocationCoordinate2DMake(self.CLLocationA, self.CLLocationB)
            let span = MKCoordinateSpanMake(spanVaule, spanVaule)
            let region = MKCoordinateRegion(center: zoomLocation, span: span)
            self.mapView.setRegion(region, animated: true)
            
            self.linNumb.text = self.lineNmb
            self.direct.text = self.dirA
            
            if(self.mapView.annotations.isEmpty == false){
                self.mapView.removeAnnotations(self.mapView.annotations)
            }

            for el in self.direction1 {
                
                let tmp = el.componentsSeparatedByString(";")
                let latitude = tmp[0] as NSString
                let longitude = tmp[1] as NSString
                let name = tmp[2]
                
                let lat = latitude.doubleValue
                let long = longitude.doubleValue
                
                let station1 = MKPointAnnotation()
                let station_coordinates = CLLocationCoordinate2DMake(lat,long)
                station1.coordinate = station_coordinates
                //station1.setCoordinate(station_coordinates)
                station1.title = name
                if let notice = tmp.get(3){
                    station1.subtitle = notice
                }
                self.mapView.addAnnotation(station1)
            }
        }
        else if(View.tag == 3 && buttonIndex == 2){
            let zoomLocation = CLLocationCoordinate2DMake(self.CLLocationA, self.CLLocationB)
            let span = MKCoordinateSpanMake(self.spanVaule, self.spanVaule)
            let region = MKCoordinateRegion(center: zoomLocation, span: span)
            self.mapView.setRegion(region, animated: true)
            
            self.linNumb.text = self.lineNmb
            self.direct.text = self.dirB
            
            if(self.mapView.annotations.isEmpty == false){
                self.mapView.removeAnnotations(self.mapView.annotations)
            }
            
            for el in self.direction2 {
                
                let tmp = el.componentsSeparatedByString(";")
                let latitude = tmp[0] as NSString
                let longitude = tmp[1] as NSString
                let name = tmp[2]
                
                let lat = latitude.doubleValue
                let long = longitude.doubleValue
                
                let station2 = MKPointAnnotation()
                let station_coordinates = CLLocationCoordinate2DMake(lat,long)
                station2.coordinate = station_coordinates
                //station2.setCoordinate(station_coordinates)
                station2.title = name
                if let notice = tmp.get(3){
                    station2.subtitle = notice
                }
                self.mapView.addAnnotation(station2)
            }
        }
    }
    
    //MARK: myPosition button
    @IBAction func myPosition(sender: AnyObject) {
        
        switch CLLocationManager.authorizationStatus(){
        case .Denied, .NotDetermined, .Restricted:
            if #available(iOS 8.0, *){
                let navigation: UIAlertController = UIAlertController(title: "Navigation error", message: "You need to allow location access", preferredStyle: UIAlertControllerStyle.Alert)
                navigation.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                    self.settings()
                }))
                navigation.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(navigation, animated: true, completion: nil)
            }
            else{
                navigationError.title = "Navigation error"
                navigationError.message = "You need to allow location access"
                navigationError.addButtonWithTitle("Ok")
                navigationError.delegate = self
                navigationError.tag = 1
                navigationError.show()
            }
        default:
            if mapView.userLocation.location == nil{
                if #available(iOS 8.0, *){
                    let navigation: UIAlertController = UIAlertController(title: "Position error", message: "User location not obtained yet. If this is repeated, check your settings", preferredStyle: UIAlertControllerStyle.Alert)
                    navigation.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {action in
                        self.settings()
                    }))
                    navigation.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.presentViewController(navigation, animated: true, completion: nil)
                }
                else{
                    positionError.title = "Position error"
                    positionError.message = "User location not obtained yet. If this is repeated, check your settings"
                    positionError.addButtonWithTitle("Ok")
                    positionError.tag = 4
                    positionError.show()
                }
            }
            else{
                let newRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpanMake(0.007, 0.007))
                mapView.setRegion(newRegion, animated: true)
            }
        }
    }
}
