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
    var lineDirection: NSDictionary!
    var lineNumber: NSArray!
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("openMenuButtonTapped"))
        self.linNumb.text = "All"
        self.direct.text = ""
        
        //MARK: gestures
        let showGestureRecognizer: UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "showSwipe:")
        showGestureRecognizer.edges = UIRectEdge.Right
        rightEdgeGestureView.addGestureRecognizer(showGestureRecognizer)
        
        let hideGestureRecognizer1: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "closeSideMenu")
        hideGestureRecognizer1.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(hideGestureRecognizer1)
        let hideGestureRecognizer2: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "closeSideMenu")
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

        let stations = ["45.341748;14.372572;Bazeni Kantrida;1","45.341403;14.373520;Bazeni Kantrida;1","45.344672;14.358355;Bivio -O;1","45.341965;14.368903;Dječja bolnica;1","45.342112;14.369577;Dječja bolnica;1","45.319345;14.463418;Hotel Jadran;1","45.316817;14.468140;Hotel Park;1","45.319122;14.465713;J.P.Kamova;1","45.316130;14.470423;J.P.Kamova WTC;1","45.340107;14.380535;Kantrida;1","45.339723;14.381755;Kantrida;1","45.321420;14.459790;OŠ Pećine;1","45.314145;14.473235;Pećine Plumbum;1","45.321268;14.462003;Pećine ž. kolodvor;1","45.324122;14.454672;Piramida - Pećine;1","45.353398;14.369488;Blečići;2","45.347063;14.378032;Diračje;2","45.347135;14.377862;Diračje;2","45.350195;14.370017;Dražice;2","45.350595;14.369450;Dražice;2","45.346032;14.381813;I.Ćikovića Belog;2","45.345782;14.384412;I.Ćikovića Belog;2","45.353600;14.364685;Martinkovac bGA;2","45.353008;14.363833;Martinkovac GPB;2","45.355650;14.368592;Srdoči ;2","45.344448;14.386803;Zamet centar;2","45.344388;14.388380;Zamet centar;2","45.327082;14.456653;J.Rakovca;2,8","45.325463;14.458645;Paris;2,8","45.324203;14.462012;Pošta;2,8","45.331283;14.456970;Trsat crkva;2,8","45.328470;14.455012;Vidikovac;2,8","45.343845;14.395322;Becićeva;3","45.343900;14.395572;Becićeva;3","45.330560;14.435097;F.l.Guardie;3","45.351265;14.381285;Grbci ;3","45.353595;14.385973;J.Mohorića;3","45.345375;14.392382;Nova Cesta - B.Mohorić;3","45.326718;14.448082;Novi most;3","45.330078;14.439993;Pomerio park;3","45.353717;14.383448;Selinari;3","45.349802;14.382995;Starci;3","45.354027;14.381748;Šumci;3","45.348493;14.385473;Zamet groblje;3","45.328985;14.442543;Žrtava fašizma;3","45.330777;14.433817;F.l.Guardie;3,8","45.328793;14.446327;Ivana Grohovca;3,8","45.330283;14.438418;Pomerio park;3,8","45.329675;14.441278;Žrtava fašizma;3,8","45.332650;14.445873;Ante Kovačića;4","45.333105;14.446373;Ante Kovačića;4","45.333815;14.437303;Belveder;4","45.329275;14.442348;Guvernerova palača B;4","45.335387;14.446498;Kapitanovo;4","45.336013;14.446012;Kapitanovo;4","45.339703;14.443195;Kozala;4","45.338160;14.444857;Kozala - Drenovski put;4","45.338175;14.444967;Kozala - Drenovski put;4","45.332837;14.442472;Kozala Groblje;4","45.332725;14.443063;Kozala Groblje;4","45.332548;14.439078;Laginjina;4","45.335653;14.433822;Tizianova;4","45.341712;14.438232;Vinas;4","45.334308;14.433233;1. maja;4,5","45.333713;14.433160;1. maja;5","45.346782;14.432563;Bok;5","45.346697;14.430942;Bok;5","45.354240;14.426108;Braće Hlača;5","45.353865;14.427280;Braće Hlača;5","45.355950;14.426667;Frkaševo;5","45.355953;14.426745;Frkaševo;5","45.348568;14.426753;I.L.Ribara - I.Žorža;5","45.348000;14.427480;I.L.Ribara - I.Žorža;5","45.350830;14.421833;I.L.Ribara - M.Rustambega;5","45.350940;14.421352;I.L.Ribara - M.Rustambega;5","45.351952;14.419865;I.L.Ribara - S.Vukelića;5","45.352157;14.419127;I.L.Ribara - S.Vukelića;5","45.331378;14.430905;Nikole Tesle;5,KBC","45.340468;14.426327;Osječka - C.Ilijassich;5","45.337370;14.432247;Osječka - F.Kresnika;5","45.337637;14.431708;Osječka - F.Kresnika;5","45.339505;14.428212;Osječka - Mihačeva Draga;5","45.339922;14.427395;Osječka - Mihačeva Draga;5","45.342753;14.424028;Osječka Lipa;5","45.343872;14.423640;Osječka Lipa;5","45.345793;14.422897;Osječka zaobilaznica;5","45.344853;14.423107;Osječka zaobilaznica;5","45.351905;14.430175;OŠ F. Franković;5","45.352422;14.429665;OŠ F. Franković;5","45.347303;14.433933;Severinska;5","45.347667;14.433665;Severinska;5","45.350500;14.423595;Staro okretište;5","45.350207;14.424217;Staro okretište;5","45.339442;14.414663;Čandekova;6","45.339120;14.415757;Čandekova;6","45.341410;14.408083;Dom umirovljenika Turnić;6","45.341807;14.403462;G.Carabino;6","45.321370;14.466212;Kvaternikova;6","45.322070;14.464978;Kvaternikova;6","45.320758;14.468037;Kvaternikova Tihovac;6","45.320647;14.468457;Kvaternikova Tihovac;6","45.340852;14.401550;Nova cesta;6","45.342797;14.397168;Novo naselje;6","45.320777;14.474757;Podvežica  centar;6,9","45.319477;14.478048;Podvežica;6","45.338063;14.419537;Studentski dom;6","45.338173;14.420053;Studentski dom;6","45.340397;14.407770;Turnić;6","45.340242;14.409452;Turnić;6","45.343340;14.398757;Vidovićeva;6","45.320142;14.482182;F.Belulovića-Z.Kučića;7","45.323428;14.479390;Franje Belulovića;7","45.322082;14.482583;G.Vežica ;7","45.351078;14.406765;Pehlin 1;7","45.350758;14.407557;Pehlin 1;7","45.353158;14.404647;Pehlin škola;7","45.354393;14.403210;Pehlin 2;7","45.359113;14.396978;Turkovo;7","45.320745;14.479170;Zdravka Kučića I;7","45.322148;14.477713;Zdravka Kučića II;7","45.334030;14.416143;Baračeva I;8","45.334162;14.416280;Baračeva I;8","45.335338;14.409030;Baračeva II;8","45.335312;14.410437;Baračeva II;8","45.327592;14.453005;Bobijevo;8","45.327262;14.452505;Bobijevo;8","45.326233;14.453808;Mažuranićev trg;8","45.333700;14.421691;Mlaka - Baračeva;8","45.325127;14.458557;Paris A;8","45.328093;14.468794;Radmile Matejčić;8","45.327208;14.447822;Titov trg;8","45.335508;14.404227;Torpedo;8","45.326780;14.455052;Vodosprema;8","45.326955;14.454542;Vodosprema;8","45.326465;14.450810;ZZZ;8","45.326257;14.451008;ZZZ;8","45.324608;14.448008;Delta;9,13","45.339517;14.392678;3. maj;1,1A","45.339738;14.391402;3. maj;1,1A","45.338682;14.400213;Krnjevo Liburnijska;1,1A","45.338825;14.401400;Krnjevo Liburnijska;1,1A","45.339813;14.385672;Liburnijska - Vere Bratonje;1,1A","45.339940;14.387087;Liburnijska - Vere Bratonje;1,1A","45.338475;14.404088;Krnjevo Zvonimirova;1,1A,2,2A,3,3A","45.338047;14.410053;Toretta;1,1A,2,2A,3,3A","45.338242;14.407653;Toretta;1,1A,2,2A,3,3A","45.330319;14.430867;Željeznički kolodvor ;1,1A,2,2A,3,3A,6,7,7A,8,KBC","45.325192;14.451762;Sušački neboder;1,1A,2,2A,3,6,7,7A,8A,9,KBC","45.327868;14.438232;Riječki neboder;1,1A,2,2A,3A,4,5,6,7,7A,8,KBC","45.327128;14.440335;Trg RH;1,1A,2,2A,3A,4,5,6,7,7A,8,KBC","45.329513;14.434123;Brajda;1,1A,2,2A,3A,5,6,7,7A,8,KBC","45.326378;14.440090;Riva;1,1A,2,2A,3A,5,6,7,7A,8,KBC","45.324925;14.443947;Tržnica;1,1A,2,2A,3A,5,6,7,7A,8,KBC","45.327255;14.437783;Žabica;1,1A,2,2A,3A,5,6,7,7A,8,KBC","45.329773;14.433685;Brajda;1,1A,2,2A,3A,6,7,7A,8,KBC","45.333952;14.422355;Mlaka;1,1A,2,3,3A","45.335952;14.416880;Novi List;1,1A,2,3,3A","45.335673;14.417787;Novi List;1,1A,2,3,3A","45.331417;14.426168;KBC Rijeka;1,1A,2,3,3A,8","45.331348;14.426507;KBC Rijeka;1,1A,2,3,3A,8","45.333425;14.422990;Mlaka;1,1A,2,3,3A,8","45.330498;14.431331;Željeznički kolodvor ;1,1A,2,3A,8,KBC","45.341850;14.380448;Labinska;1A","45.341642;14.381257;Labinska;1A","45.346168;14.364617;Marčeljeva Draga;1A","45.345388;14.367367;Mate Balote;1A","45.345413;14.367600;Mate Balote;1A","45.342527;14.377630;OŠ Kantrida;1A","45.342363;14.379120;OŠ Kantrida;1A","45.344393;14.370950;Ploče;1A","45.344460;14.370147;Ploče;1A","45.343802;14.373542;Šparići;1A","45.344015;14.372867;Šparići;1A","45.332465;14.462370;Vrlije;1A","45.326227;14.448750;A.K. Miošića;1A,2A,3","45.322138;14.472820;Martina Kontuša;1B,9","45.321005;14.471858;OŠ Podvežica;1B,6,9","45.328627;14.459103;Park Heroja;1B","45.319307;14.471830;Radnička;1B,9","45.319208;14.472038;Radnička;1B","45.333283;14.463745;Rose Leard;1B","45.333478;14.465490;Slava Raškaj;1B","45.334347;14.464225;Strmica;1B","45.317368;14.469047;Tower;1B","45.323650;14.465208;Mihanovićeva;1B,2,8","45.328430;14.462168;Trsat groblje;1B,2,8","45.330117;14.459523;Trsat;1B,2,8","45.326358;14.465338;Slavka Krautzeka I;1B,2,8,8A","45.325050;14.467345;Slavka Krauzeka II;1B,2,8,8A","45.320910;14.474823;Podvežica  centar A;1B,6","45.325470;14.471185;KBC Sušak;1B,7,7A,8,8A,9","45.339442;14.400822;Krnjevo Zametska;2,2A,3,3A","45.341643;14.395545;Zametska;2,2A,3,3A","45.341622;14.395777;Zametska;2,2A,3,3A","45.343480;14.392540;Baredice;2,2A,3A","45.343488;14.391825;Baredice;2,2A,3A","45.326705;14.447252;Fiumara;2,2A,4,6,7,7A,8A,KBC","45.326586;14.446901;Fiumara;2,2A,4,6,7,7A,8,8A,9,KBC","45.322493;14.460970;Kumičićeva;2,6,7,7A,8A,9,KBC","45.322667;14.460528;Kumičićeva;2,6,7,7A,8A,9,KBC","45.324308;14.454365;Piramida;2,6,7,7A,8A,9,KBC","45.322392;14.465108;Teta Roža;2,7,7A,8A,KBC","45.322393;14.464753;Teta Roža;2,7,7A,8A,KBC","45.345350;14.376958;Bože Vidasa;2A","45.345287;14.377600;Bože Vidasa;2A","45.346962;14.371453;I.Zavidić ;2A","45.337055;14.418773;R.Benčić;2A","45.337173;14.419607;R.Benčića;2A","45.344152;14.387507;Zamet - Bože Vidasa A;2A","45.344183;14.387783;Zamet - Bože Vidasa B;2A","45.343965;14.383207;Zamet crkva A;2A","45.343972;14.384078;Zamet crkva B;2A","45.344140;14.380993;Zamet tržnica;2A","45.344270;14.380460;Zamet tržnica;2A","45.331397;14.430870;Nikole Tesle A;2A,3,6,7,7A,8","45.333078;14.430742;Potok;2A,6,7,7A","45.333252;14.430542;Potok;2A,6,7,7A","45.334900;14.426407;Štranga;2A,6,7,7A","45.335148;14.426315;Štranga;2A,6,7,7A","45.336522;14.424803;Tehnički fakultet;2A,6,7,7A","45.336822;14.424390;Tehnički fakultet;2A,7,7A","45.352647;14.391640;Drnjevići;3, 3A","45.348857;14.387563;Fantini;3,3A","45.346648;14.390880;Nova Cesta - B.Mohorić;3,3A","45.349178;14.391293;Pilepići;3,3A","45.330383;14.432737;Manzzonijeva;3,4,5","45.363665;14.381728;Bezjaki;3A","45.346610;14.388183;Braće Mohorić;3A","45.346509;14.388522;Braće Mohorić;3A","45.352617;14.391733;Drnjevići;3A","45.348873;14.387592;Fantini;3A","45.354930;14.389035;Mulci;3A","45.354938;14.389190;Mulci;3A","45.349255;14.390965;Pilepići;3A","45.358175;14.386628;Pužići;3A","45.358212;14.386703;Pužići;3A","45.361043;14.386077;Trampov breg;3A","45.361040;14.386015;Trampov breg;3A","45.344483;14.388818;Zamet - Braće Monjac;3A","45.344670;14.388980;Zamet - Braće Monjac;3A","45.325539;14.445637;Jelačićev trg;3A,5,8A","45.342225;14.440983;Brašćine ;4,4A","45.325700;14.444043;Pallazo Modello;4,7,7A","45.343865;14.443243;Galenski laboratorij;4A","45.343962;14.443272;Galenski laboratorij;4A","45.342653;14.443068;Internacionalni brigada;4A","45.342367;14.443147;Internacionalni brigada;4A","45.345578;14.444770;Pulac I;4A","45.345537;14.444820;Pulac I;4A","45.346772;14.446282;Pulac II;4A","45.346782;14.446262;Pulac II;4A","45.348153;14.444365;Vrh Pulca;4A","45.351940;14.418073;Osječka - Crkva;5,5A","45.351606;14.418472;Osječka - Crkva;5,5A","45.349625;14.419497;Osječka - Drežnička;5,5A","45.350050;14.419235;Osječka - Drežnička;5,5A","45.356893;14.424668;Drenova;5,5B","45.362873;14.411238;Škurinje spomenik;5A","45.362890;14.411538;Škurinje spomenik;5A","45.354753;14.416157;Škurinje škola;5A","45.357637;14.414415;Škurinjska cesta I;5A","45.358743;14.413847;Škurinjska cesta I;5A","45.363672;14.409207;Škurinjska cesta II;5A","45.366650;14.402777;Tibljaši ;5A","45.365038;14.419485;B.Francetića;5B","45.365067;14.418947;B.Francetića;5B","45.361713;14.424733;B.Francetića - Pešćevac;5B","45.361773;14.424602;B.Francetića - Pešćevac;5B","45.363445;14.422947;B.Francetića - Tonići;5B","45.363188;14.423147;B.Francetića - Tonići;5B","45.360125;14.426538;Benaši - B. Francetića;5B","45.360278;14.426492;Benaši - B. Francetića;5B","45.368435;14.413600;Kablari;5B","45.367817;14.416592;Kablarska cesta;5B","45.367197;14.416993;Kablarska cesta;5B","45.368926;14.405946;Petrci;5B","45.343437;14.413497;Čepićka (Prav.Fax);7,7A","45.342007;14.414337;Podmurvice;7,7A","45.342093;14.414402;Podmurvice;7,7A","45.344677;14.412297;Rujevica;7,7A","45.345230;14.411665;Rujevica;7,7A","45.325788;14.476657;Sveta Ana;7,7A,9","45.339510;14.419353;Vukovarska;7,7A","45.339560;14.419183;Vukovarska;7,7A","45.325242;14.470760;KBC Sušak;7,7A,8A","45.348292;14.408277;Blažićevo;7A","45.348192;14.408677;Blažićevo;7A","45.353463;14.399318;Hosti;7A","45.350707;14.405568;Pehlin dj. vrtić;7A","45.350702;14.405717;Pehlin dj. vrtić;7A","45.323945;14.480203;R.Petrovića I;7A","45.324063;14.480035;R.Petrovića I;7A","45.323048;14.483962;R.Petrovića II;7A","45.323293;14.483035;R.Petrovića II;7A","45.325835;14.476457;Sveta Ana;7A,9","45.324383;14.482458;Sveti križ;7A","45.352138;14.402633;Ul. Hosti;7A","45.352242;14.402277;Ul. Hosti;7A","45.327725;14.464469;Sveučilišna avenija;8,8A","45.328741;14.465678;Sveučilišna avenija;8,8A","45.328680;14.467743;Radmile Matejčić;8A","45.312394; 14.523941;Baraći;9","45.313775;14.522908;Sv. Kuzam;9","45.316593;14.516060;Draga – Tijani;9","45.319623;14.504268;Draga - Sv. Jakov;9","45.321768;14.497358;Draga Brig – dom;9","45.323173;14.495275;Draga Orlići II;9","45.324765;14.493465;Draga Orlići I;9","45.327185;14.484248;Draga pod Ohrušvom;9","45.318795;14.470274;D.Gervaisa I Vulk.naselje;9","45.319440;14.468934;D.Gervaisa II market;9","45.321413;14.464556;D.Gervaisa III;9","45.32151;14.46404;D.Gervaisa III;9","45.31961;14.46838;D.Gervaisa II market;9","45.31865;14.47034;D.Gervaisa I Vulk.naselje;9","45.323723;14.475663;Zdravka Kučića III;9","45.326933;14.485210;Draga pod Ohrušvom;9","45.324802;14.493043;Draga Orlići I;9","45.323125;14.495323;Draga Orlići II;9","45.321650;14.497435;Draga Brig – dom;9","45.319252;14.504892;Draga - Sv. Jakov;9","45.316538;14.516260;Draga – Tijani;9","45.313413;14.523018;Sv. Kuzam;9","45.331880;14.453537;Banska vrata;13","45.337348;14.468337;Donja Orehovica;13","45.341818;14.465372;Gornja Orehovica;13","45.350212;14.458312;Balda Fućka;13","45.352812;14.457206;Pašac I;13","45.354590;14.455625;Pašac II;13","45.361943;14.443925;Grohovski put;13","45.364293;14.441863;Grohovo;13","45.331967;14.453433;Banska vrata;13","45.337392;14.468182;Donja Orehovica;13","45.341648;14.465253;Gornja Orehovica;13","45.349868;14.458457;Balda Fućka;13","45.354480;14.455752;Pašac II;13","45.325367;14.470072;KBC Sušak ulaz;KBC","45.331594;14.428495;KBC 1 porta;KBC","45.331990;14.426328;KBC 2 hitna;KBC","45.332569;14.430778;KBC 3 Poliklinika;KBC"]
        
        //Put all pins (stations) on map
        for el in stations {
            
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
    func sideMenuDidSelectButtonAtIndex(index: Int, section: Int) {
        //All bus lines
        if section == 0 {
            closeSideMenu()
            viewDidLoad()
        }
        //List of bus lines
        else{
            switch index{
            case 0: //1
                closeSideMenu()
                pins(["45.314145;14.473235;Pećine","45.316130;14.470423;J.P. Kamova WTC","45.319122;14.465713;J.P. Kamova","45.321268;14.462003;Pećine Ž. Kolodvor","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331348;14.426507;KBC Rijeka","45.333952;14.422355;Mlaka","45.335673;14.417787;Novi list","45.338047;14.410053;Toretta","45.338825;14.401400;Krnjevo Liburnijska","45.339738;14.391402;3. Maj","45.339813;14.385672;Liburnijska - V. Bratonje","45.340107;14.380535;Kantrida","45.341748;14.372572;Bazeni Kantrida","45.342112;14.369577;Dječja bolnica","45.344672;14.358355;Bivio"], coordinates2: ["45.344672;14.358355;Bivio","45.341965;14.368903;Dječja bolnica","45.341403;14.373520;Bazeni kantrida","45.339723;14.381755;Kantrida","45.339940;14.387087;Liburnijska - V. Bratonje","45.339517;14.392678;3. Maj","45.338682;14.400213;Krnjevo Liburnijska","45.338475;14.404088;Krnjevo Zvonimirova","45.338047;14.410053;Toretta","45.335952;14.416880;Novi list","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324122;14.454672;Piramida – Pećine","45.321420;14.459790;OŠ Pećine","45.319345;14.463418;Hotel Jadran","45.316817;14.468140;Hotel Park","45.314145;14.473235;Pećine"], linNumb: "1", direction: ["Pećine -> Bivio","Bivio -> Pećine"], CLLocation: [45.337837, 14.417976], span: 0.13)
            case 1: //1A
                closeSideMenu()
                pins(["45.326227;14.448750;A.K. Miošića","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331348;14.426507;KBC Rijeka","45.333952;14.422355;Mlaka","45.335673;14.417787;Novi list","45.338242;14.407653;Toretta","45.338825;14.401400;Krnjevo Liburnijska","45.339738;14.391402;3. Maj","45.339813;14.385672;Liburnijska - V. Bratonje","45.341642;14.381257;Labinska ulica","45.342363;14.379120;OŠ Kantrida","45.344015;14.372867;Šparići","45.344460;14.370147;Ploče","45.345413;14.367600;Mate Balote","45.346168;14.364617;Marčeljeva Draga"], coordinates2: ["45.346168;14.364617;Marčeljeva Draga","45.345388;14.367367;Mate Balote","45.344393;14.370950;Ploče","45.343802;14.373542;Šparići","45.342527;14.377630;OŠ Kantrida","45.341850;14.380448;Labinska ulica","45.339940;14.387087;Liburnijska - V. Bratonje","45.339517;14.392678;3. Maj","45.338682;14.400213;Krnjevo Liburnijska","45.338475;14.404088;Krnjevo Zvonimirova","45.338047;14.410053;Toretta","45.335952;14.416880;Novi List","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.326227;14.448750;A.K. Miošića"], linNumb: "1A", direction: ["A.K. Miošića -> Marčeljeva Draga","Marčeljeva Draga -> A.K. Miošića"], CLLocation: [45.338458, 14.410687], span: 0.095)
            case 2: //1B
                closeSideMenu()
                    pins(["45.317368;14.469047;Tower","45.319208;14.472038;Radnička","45.320777;14.474757;Podvežica centar","45.323723;14.475663;Z. Kučića III","45.325242;14.470760;KBC Sušak","45.323650;14.465208;Mihanovićeva","45.326153;14.462240;Drage Ščitara","45.328627;14.459103;Park heroja","45.330117;14.459523;Trsat","45.332198;14.464653;Josipa Kuflaneka","45.333478;14.465490;Slave Raškaj","45.334347;14.464225;Strmica"], coordinates2: ["45.334347;14.464225;Strmica","45.333283;14.463745;Rose Leard","45.332465;14.462370;Vrlije","45.330117;14.459523;Trsat","45.328430;14.462168;Trsat groblje","45.326358;14.465338;S. Krautzeka I","45.325050;14.467345;S. Krautzeka II","45.322138;14.472820;M. Kontuša","45.321005;14.471858;OŠ Podvežica","45.319307;14.471830;Radnička","45.317368;14.469047;Tower"], linNumb: "1B", direction: ["Tower -> Strmica","Strmica -> Tower"], CLLocation: [45.324489, 14.468708], span: 0.03)
            case 3: //2
                closeSideMenu()
                pins(["45.330117;14.459523;Trsat","45.328430;14.462168;Trsat groblje","45.326358;14.465338;Slavka Krautzeka I","45.325050;14.467345;Slavka Krautzeka II","45.322393;14.464753;Teta Roža","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331348;14.426507;KBC Rijeka","45.333952;14.422355;Mlaka","45.335673;14.417787;Novi List","45.338242;14.407653;Toretta","45.339442;14.400822;Krnjevo Zametska","45.341622;14.395777;Zametska","45.343488;14.391825;Baredice","45.344388;14.388380;Zamet centar","45.345782;14.384412;Ul. I.Č. Belog","45.347135;14.377862;Diračje","45.350595;14.369450;Dražice","45.353600;14.364685;Martinkovac","45.355650;14.368592;Srdoči"], coordinates2: ["45.355650;14.368592;Srdoči","45.353398;14.369488;Blečići","45.353008;14.363833;Martinkovac","45.350195;14.370017;Dražice","45.347063;14.378032;Diračje","45.346032;14.381813;Ul. I.Č. Belog","45.344448;14.386803;Zamet centar","45.343480;14.392540;Baredice","45.341643;14.395545;Zametska","45.338475;14.404088;Krnjevo Zvonimirova","45.338047;14.410053;Toretta","45.335952;14.416880;Novi List","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.322392;14.465108;Teta Roža","45.323650;14.465208;Mihanovićeva","45.324203;14.462012;Pošta","45.325463;14.458645;Paris","45.327082;14.456653;J. Rakovca","45.328470;14.455012;Vidikovac","45.331283;14.456970;Trsat crkva","45.330117;14.459523;Trsat"], linNumb: "2", direction: ["Trsat -> Srdoči","Srdoči -> Trsat"], CLLocation: [45.337234, 14.418405], span: 0.12)
            case 4: //2A
                closeSideMenu()
                pins(["45.326227;14.448750;A.K. Miošića","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.331397;14.430870;Nikole Tesle","45.333252;14.430542;Potok","45.335148;14.426315;Štranga","45.336522;14.424803;Tehnički fakultet","45.337055;14.418773;R. Benčića","45.338242;14.407653;Toretta","45.339442;14.400822;Krnjevo Zametska","45.341622;14.395777;Zametska","45.343488;14.391825;Baredice","45.345287;14.377600;Zamet - Bože Vidasa","45.343965;14.383207;Zamet crkva","45.344270;14.380460;Zamet tržnica","45.345287;14.377600;Bože Vidasa","45.346962;14.371453;Ivana Zavidića",], coordinates2: ["45.346962;14.371453;Ivana Zavidića","45.345350;14.376958;Bože Vidasa","45.344140;14.380993;Zamet tržnica","45.343972;14.384078;Zamet crkva","45.344183;14.387783;Zamet - Bože Vidasa","45.343480;14.392540;Baredice","45.341643;14.395545;Zametska","45.338475;14.404088;Krnjevo Zvonimirova;","45.338047;14.410053;Toretta","45.337173;14.419607;R.Benčića","45.336822;14.424390;Tehnički fakultet","45.334900;14.426407;Štranga","45.333078;14.430742;Potok","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.326227;14.448750;A.K. Miošića"], linNumb: "2A", direction: ["A.K.Miošića -> Ivana Zavidića","Ivana Zavidića -> A.K.Miošića"], CLLocation: [45.338381, 14.412483], span: 0.09)
            case 5: //3
                closeSideMenu()
                pins(["45.326227;14.448750;A.K. Miošića","45.325192;14.451762;Sušački neboder","45.328793;14.446327;Ivana Grohovca","45.329675;14.441278;Žrtava fašizma","45.330283;14.438418;Pomerio park","45.330777;14.433817;F.I. Guardie","45.331397;14.430870;N. Tesle","45.331348;14.426507;KBC Rijeka","45.333952;14.422355;Mlaka","45.335673;14.417787;Novi list","45.338242;14.407653;Toretta","45.339442;14.400822;Krnjevo Zametska","45.341622;14.395777;Zametska","45.343900;14.395572;Becićeva","45.346648;14.390880;N. Cesta – B. Mohorić","45.348857;14.387563;Fantini","45.349178;14.391293;Pilepići","45.352647;14.391640;Drnjevići","45.353595;14.385973;J. Mohorića","45.353717;14.383448;Selinari","45.354027;14.381748;Šumci","45.351265;14.381285;Grbci"], coordinates2: ["45.351265;14.381285;Grbci","45.349802;14.382995;Starci","45.348493;14.385473;Zamet groblje","45.345375;14.392382;N. Cesta – B. Mohorić","45.343845;14.395322;Becićeva","45.341643;14.395545;Zametska","45.338475;14.404088;Krnjevo Zvonimirova","45.338047;14.410053;Toretta","45.335952;14.416880;Novi list","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.330383;14.432737;Manzzonijeva","45.330560;14.435097;F.I. Guardie","45.330078;14.439993;Pomerio Park","45.328985;14.442543;Žrtava fašizma","45.326718;14.448082;Novi most","45.326227;14.448750;A. K. Miošiča"], linNumb: "3", direction: ["A.K.Miošića -> Grbci","Grbci -> A.K.Miošića"], CLLocation: [45.338139, 14.418663], span: 0.078)
            case 6: //3A
                closeSideMenu()
                pins(["45.325539;14.445637;Jelačićev trg","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331348;14.426507;KBC Rijeka","45.333952;14.422355;Mlaka","45.335673;14.417787;Novi List","45.338242;14.407653;Toretta","45.339442;14.400822;Krnjevo Zametska","45.341622;14.395777;Zametska","45.343488;14.391825;Baredice","45.344670;14.388980;Zamet B. Monjac","45.346509;14.388522;Braće Mohorić","45.346648;14.390880;N. Cesta - B. Mohorić","45.348857;14.387563;Fantini","45.349178;14.391293;Pilepići","45.352647;14.391640;Drnjevići","45.354938;14.389190;Mulci","45.358212;14.386703;Pužići","45.361043;14.386077;Trampov breg","45.363665;14.381728;Bezjaki"], coordinates2: ["45.363665;14.381728;Bezjaki","45.361040;14.386015;Trampov breg","45.358175;14.386628;Pužići","45.354930;14.389035;Mulci","45.352617;14.391733;Drnjevići","45.349255;14.390965;Pilepići","45.348873;14.387592;Fantini","45.346610;14.388183;Braće Mohorić","45.344483;14.388818;Zamet B. Monjac","45.343480;14.392540;Baredice","45.341643;14.395545;Zametska","45.338475;14.404088;Krnjevo Zvonimirova","45.338047;14.410053;Toretta","45.335952;14.416880;Novi List","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.325539;14.445637;Jelačićev trg"], linNumb: "3A", direction: ["Jelačićev trg -> Bezjaki","Bezjaki -> Jelačićev trg"], CLLocation: [45.340130, 14.415916], span: 0.072)
            case 7: //4
                closeSideMenu()
                pins(["45.326586;14.446901;Fiumara","45.325700;14.444043;Palazzo Modello","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.330383;14.432737;Manzzonijeva","45.334308;14.433233;1. maja","45.335653;14.433822;Tizianova","45.333815;14.437303;Belveder","45.332725;14.443063;Kozala groblje","45.333105;14.446373;Ante Kovačića","45.336013;14.446012;Kapitanovo","45.338175;14.444967;Kozala - Drenovski put","45.339703;14.443195;Kozala","45.341712;14.438232;Vinas","45.342225;14.440983;Brašćine okretište"], coordinates2: ["45.342225;14.440983;Brašćine","45.338160;14.444857;Kozala – Drenovski put","45.335387;14.446498;Kapitanovo","45.332650;14.445873;A. Kovačića","45.332837;14.442472;Kozala groblje","45.332548;14.439078;Laginjina","45.329275;14.442348;Guvernerova palača","45.326586;14.446901;Fiumara"], linNumb: "4", direction: ["Fiumara -> Brašćine","Brašćine -> Fiumara"], CLLocation: [45.333795, 14.439949], span: 0.025)
            case 8: //4A
                closeSideMenu()
                pins(["45.339816;14.452026;Sv. Katarina","45.341324;14.445321;Katarina I","45.339883;14.450149;Katarina II","45.342225;14.440983;Brašćine","45.342367;14.443147;Internacionalnih brigada","45.343962;14.443272;Galenski laboratorij","45.345537;14.444820;Pulac I","45.346772;14.446282;Pulac II","45.348153;14.444365;Vrh Pulca"], coordinates2: ["45.348153;14.444365;Vrh Pulca","45.346782;14.446262;Pulac II","45.345578;14.444770;Pulac I","45.343865;14.443243;Galenski laboratorij","45.342653;14.443068;Internacionalnih brigada","45.342225;14.440983;Brašćine","45.340019;14.449924;Katarina II","45.341490;14.445085;Katarina I","45.339816;14.452026;Sv. Katarina"], linNumb: "4A", direction: ["Sv. Katarina -> Pulac","Pulac -> Sv. Katarina"], CLLocation: [45.344096, 14.446971], span: 0.013)
            case 9: //5
                closeSideMenu()
                pins(["45.325539;14.445637;Jelačićev trg","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.330383;14.432737;Manzzonijeva","45.334308;14.433233;1. maja","45.337637;14.431708;Osječka - F. Kresnika","45.339922;14.427395;Osječka - Mihačeva Draga","45.343872;14.423640;Osječka Lipa","45.345793;14.422897;Osječka zaobilaznica","45.349625;14.419497;Osječka – Drežnička","45.351606;14.418472;Osječka – Crkva","45.352157;14.419127;I.L. Ribara - S. Vukelića","45.350940;14.421352;I.L. Ribara - M. Ruslambega","45.350207;14.424217; Staro okretište","45.348000;14.427480;I.L. Ribara - I. Žorža","45.346697;14.430942;Bok","45.347667;14.433665;Severinska","45.352422;14.429665;OŠ F. Franković","45.353865;14.427280;Braće Hlača","45.355953;14.426745;Frkaševo","45.356893;14.424668;Drenova"], coordinates2: ["45.356893;14.424668;Drenova","45.355950;14.426667;Frkaševo","45.354240;14.426108;Braće Hlača","45.351905;14.430175;OŠ F. Franković","45.347303;14.433933;Severinska","45.346782;14.432563;Bok","45.348568;14.426753;I.L. Ribara - I. Žorža","45.350500;14.423595;Staro okretište","45.350830;14.421833;I.L. Ribara - M. Rustambega","45.351952;14.419865;I.L. Ribara - S. Vukelića","45.351940;14.418073;Osječka – Crkva","45.350050;14.419235;Osječka – Drežnička","45.344853;14.423107;Osječka zaobilaznica","45.342753;14.424028;Osječka Lipa","45.340468;14.426327;Osječka - C. Ilijassich","45.339505;14.428212;Osječka - Mihačeva Draga","45.337370;14.432247;Osječka - F. Kresnika","45.333713;14.433160;1. maja","45.331378;14.430905;Nikole Tesle","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.325539;14.445637;Jelačićev trg"], linNumb: "5", direction: ["Jelačićev trg -> Drenova","Drenova -> Jelačićev trg"], CLLocation: [45.340251, 14.432997], span: 0.045)
            case 10: //5A
                closeSideMenu()
                pins(["45.349625;14.419497;Osječka – Drežnička","45.351606;14.418472;Osječka – Crkva","45.358743;14.413847;Škurinjska cesta I","45.362890;14.411538;Škurinje spomenik","45.366650;14.402777;Tibljaši"], coordinates2: ["45.366650;14.402777;Tibljaši","45.363672;14.409207;Škurinjska cesta II","45.362873;14.411238;Škurinje spomenik","45.357637;14.414415;Škurinjska cesta I","45.354753;14.416157;Škurinje škola","45.351940;14.418073;Osječka – Crkva","45.350050;14.419235;Osječka – Drežnička"], linNumb: "5A", direction: ["Drežnička -> Tibljaši","Tibljaši -> Drežnička"], CLLocation: [45.356598, 14.410766], span: 0.032)
            case 11: //5B
                closeSideMenu()
                pins(["45.356893;14.424668;Drenova","45.360278;14.426492;Benaši – B. Francetića","45.361713;14.424733;B. Francetića – Pešćevac","45.363445;14.422947;B. Francetića – Tonići","45.365038;14.419485;B. Francetića","45.367817;14.416592;Kablarska cesta","45.368435;14.413600;Kablari","45.368926;14.405946;Petrci"], coordinates2: ["45.368926;14.405946;Petrci","45.368435;14.413600;Kablari","45.367197;14.416993;Kablarska cesta","45.365067;14.418947;B. Francetića","45.363188;14.423147;B. Francetića – Tonići","45.361773;14.424602;B. Francetića – Pešćevac","45.360125;14.426538;Benaši - B. Francetića","45.356893;14.424668;Drenova"], linNumb: "5B", direction: ["Drenova -> Petrci","Petrci -> Drenova"], CLLocation: [45.363413, 14.417032], span: 0.028)
            case 12: //6
                closeSideMenu()
                pins(["45.319477;14.478048;Podvežica","45.320910;14.474823;Podvežica centar","45.321005;14.471858;OŠ Podvežica","45.320647;14.468457;Kvaternikova Tihovac","45.322070;14.464978;Kvaternikova","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.331397;14.430870;Nikole Tesle","45.333252;14.430542;Potok","45.335148;14.426315;Štranga","45.336522;14.424803;Tehnički fakultet","45.338173;14.420053;Studentski dom","45.339120;14.415757;Čandekova","45.340242;14.409452;Turnić","45.341410;14.408083;Dom umirovljenika","45.341807;14.403462;G. Carabino","45.343340;14.398757;Vidovićeva","45.342797;14.397168;Novo naselje"], coordinates2: ["45.342797;14.397168;Novo naselje","45.340852;14.401550;Nova cesta","45.340397;14.407770;Turnić","45.339442;14.414663;Čandekova","45.338063;14.419537;Studentski dom","45.334900;14.426407;Štranga","45.333078;14.430742;Potok","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.321370;14.466212;Kvaternikova","45.320758;14.468037;Kvaternikova Tihovac","45.321005;14.471858;OŠ Podvežica","45.320777;14.474757;Podvežica centar","45.319477;14.478048;Podvežica"], linNumb: "6", direction: ["Podvežica -> Novo Naselje","Novo Naselje -> Podvežica"], CLLocation: [45.338863, 14.439691], span: 0.089)
            case 13: //7
                closeSideMenu()
                pins(["45.322082;14.482583;Gornja Vežica","45.320142;14.482182;F. Belulovića - Z. Kučića","45.320745;14.479170;Zdravka Kučića I","45.322148;14.477713;Zdravka Kučića II","45.323723;14.475663;Zdravka Kučića III","45.325470;14.471185;KBC Sušak","45.322393;14.464753;Teta Roža","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.325700;14.444043;Palazzo Modello","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.331397;14.430870;Nikole Tesle","45.333252;14.430542;Potok","45.335148;14.426315;Štranga","45.336522;14.424803;Tehnički fakultet","45.339560;14.419183;Vukovarska","45.342093;14.414402;Podmurvice","45.343437;14.413497;Čepićka","45.345230;14.411665;Rujevica","45.350758;14.407557;Pehlin I","45.353158;14.404647;Pehlin škola","45.354393;14.403210;Pehlin II","45.359113;14.396978;Turkovo"], coordinates2: ["45.359113;14.396978;Turkovo","45.354393;14.403210;Pehlin II","45.351078;14.406765;Pehlin I","45.344677;14.412297;Rujevica","45.342007;14.414337;Podmurvice","45.339510;14.419353;Vukovarska","45.336822;14.424390;Tehnički fakultet","45.334900;14.426407;Štranga","45.333078;14.430742;Potok","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.322392;14.465108;Teta Roža","45.325242;14.470760;KBC Sušak","45.325788;14.476657;Sveta Ana","45.323428;14.479390;Franje Belulovića","45.322082;14.482583;Gornja Vežica"], linNumb: "7",direction: ["Gornja Vežica -> Pehlin","Pehlin -> Gornja Vežica"], CLLocation: [45.336631, 14.442438], span: 0.097)
            case 14: //7A
                closeSideMenu()
                pins(["45.324383;14.482458;Sveti križ","45.323293;14.483035;R. Petrovića II","45.324063;14.480035;R. Petrovića I","45.325835;14.476457;Sveta Ana","45.325470;14.471185;KBC Sušak","45.322393;14.464753;Teta Roža","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.325700;14.444043;Palazzo Modello","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.331397;14.430870;Nikole Tesle","45.333252;14.430542;Potok","45.335148;14.426315;Štranga","45.336522;14.424803;Tehnički fakultet","45.339560;14.419183;Vukovarska","45.342093;14.414402;Podmurvice","45.343437;14.413497;Čepićka","45.345230;14.411665;Rujevica","45.348192;14.408677;Blažićevo","45.350702;14.405717;Pehlin dj. Vrtić","45.352138;14.402633;Ul. Hosti","45.353463;14.399318;Hosti"], coordinates2: ["45.353463;14.399318;Hosti","45.352242;14.402277;Ul. Hosti","45.350707;14.405568;Pehlin dj. Vrtić","45.348292;14.408277;Blažićevo","45.344677;14.412297;Rujevica","45.342007;14.414337;Podmurvice","45.339510;14.419353;Vukovarska","45.336822;14.424390;Tehnički fakultet","45.334900;14.426407;Štranga","45.333078;14.430742;Potok","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.322392;14.465108;Teta Roža","45.325242;14.470760;KBC Sušak","45.325788;14.476657;Sveta Ana","45.323945;14.480203;R. Petrovića I","45.323048;14.483962;R. Petrovića II","45.324383;14.482458;Sveti križ"], linNumb: "7A", direction: ["Sveti križ -> Hosti","Hosti -> Sveti križ"], CLLocation: [45.336752, 14.444884], span: 0.097)
            case 15: //8
                closeSideMenu()
                pins(["45.330117;14.459523;Trsat;First station on weekends","45.328430;14.462168;Trsat groblje,Does not stop on workday ","45.326358;14.465338;Slavka Krautzeka I;Does not stop on workday","45.325050;14.467345;Slavka Krautzeka II;Does not stop on workday","45.328093;14.468794;Kampus; First station on workday ","45.325470;14.471185;KBC Sušak; Does not stop on weekends","45.323650;14.465208;Mihanovićeva","45.324203;14.462012;Pošta","45.325127;14.458557;Paris","45.326955;14.454542;Vodosprema","45.327262;14.452505;Bobijevo","45.326257;14.451008;ZZZ","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331348;14.426507;KBC Rijeka","45.333700;14.421691;Mlaka – Baračeva","45.334162;14.416280;Baračeva I","45.335312;14.410437;Baračeva II","45.335508;14.404227;Torpedo"], coordinates2: ["45.335508;14.404227;Torpedo","45.335338;14.409030;Baračeva II","45.334030;14.416143;Baračeva I","45.333425;14.422990;Mlaka","45.331417;14.426168;KBC Rijeka","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.327208;14.447822;Titov trg","45.326465;14.450810;ZZZ","45.326233;14.453808;Mažuranićev trg","45.327592;14.453005;Bobijevo","45.326780;14.455052;Vodosprema","45.325463;14.458645;Paris","45.327082;14.456653;J. Rakovca","45.328470;14.455012;Vidikovac","45.331283;14.456970;Trsat crkva","45.330117;14.459523;Trsat;Last station on weekends","45.328430;14.462168;Trsat groblje","45.328741;14.465678;Sveučilišna avenija ","45.327725;14.464469;Kampus;Last station on workdays"], linNumb: "8", direction: ["(Trsat) Kampus -> Torpedo","Torpedo -> Kampus (Trsat)"], CLLocation: [45.332860, 14.440206], span: 0.075)
            case 16: //8A
                closeSideMenu()
                pins(["45.327725;14.464469;Sveučilišna avenija","45.326358;14.465338;Slavka Krautzeka I","45.325050;14.467345;Slavka Krautzeka II","45.322393;14.464753;Teta Roža","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.325539;14.445637;Jelačićev trg"], coordinates2: ["45.325539;14.445637;Jelačićev trg","45.326586;14.446901;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.322392;14.465108;Teta Roža","45.325242;14.470760;KBC Sušak","45.328680;14.467743;Radmila Matejčić","45.327725;14.464469;Sveučilišna avenija"], linNumb: "8A", direction: ["Kampus -> Jelačićev trg","Jelačićev trg -> Kampus"], CLLocation: [45.322511, 14.459175], span: 0.03)
            case 17: //9
                closeSideMenu()
                pins(["45.324608;14.448008;Delta","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.32151;14.46404;D.Gervaisa III","45.31961;14.46838;D.Gervaisa II market","45.31865;14.47034;D.Gervaisa I Vulk.naselje","45.319307;14.471830;Radnička","45.321005;14.471858;OŠ Podvežica","45.320777;14.474757;Podvežica  centar","45.323723;14.475663;Zdravka Kučića III","45.325788;14.476657;Sveta Ana","45.326933;14.485210;Draga pod Ohrušvom","45.324802;14.493043;Draga Orlići I","45.323125;14.495323;Draga Orlići II","45.321650;14.497435;Draga Brig – dom","45.319252;14.504892;Draga - Sv. Jakov","45.316538;14.516260;Draga – Tijani","45.313413;14.523018;Sv. Kuzam","45.312394;14.523941;Baraći"], coordinates2: ["45.312394;14.523941;Baraći","45.313775;14.522908;Sv. Kuzam","45.316593;14.516060;Draga – Tijani","45.319623;14.504268;Draga - Sv. Jakov","45.321768;14.497358;Draga Brig – dom","45.323173;14.495275;Draga Orlići II","45.324765;14.493465;Draga Orlići I","45.327185;14.484248;Draga pod Ohrušvom","45.325835;14.476457;Sveta Ana","45.325470;14.471185;KBC Sušak","45.322138;14.472820;Martina Kontuša","45.321005;14.471858;OŠ Podvežica","45.319208;14.472038;Radnička","45.318795;14.470274;D.Gervaisa I Vulk.naselje","45.319440;14.468934;D.Gervaisa II market","45.321413;14.464556;D.Gervaisa III","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.324608;14.448008;Delta"], linNumb: "9", direction: ["Delta -> Baraći","Baraći -> Delta"], CLLocation: [45.322028, 14.487754], span: 0.085)
            case 18: //13
                closeSideMenu()
                pins(["45.324608;14.448008;Delta","45.331880;14.453537;Banska vrata","45.337348;14.468337;Donja Orehovica","45.341818;14.465372;Gornja Orehovica","45.350212;14.458312;Balda Fućka","45.352812;14.457206;Pašac I","45.354590;14.455625;Pašac II","45.361943;14.443925;Grohovski put","45.364293;14.441863;Grohovo"], coordinates2: ["45.364293;14.441863;Grohovo","45.354480;14.455752;Pašac II","45.352812; 14.457206;Pašac I","45.349868;14.458457;Balda Fućka","45.341648;14.465253;Gornja Orehovica","45.337392;14.468182;Donja Orehovica","45.331967;14.453433;Banska vrata","45.326705;14.447252;Fiumara","45.324608;14.448008;Delta"], linNumb: "13", direction: ["Delta -> Grohovo","Grohovo -> Delta"], CLLocation: [45.347313, 14.448615], span: 0.085)
            case 19: //KBC
                closeSideMenu()
                pins(["45.325367;14.470072;KBC Sušak ulaz","45.322393;14.464753;Teta Roža","45.322667;14.460528;Kumičićeva","45.325192;14.451762;Sušački neboder","45.326586;14.446901;Fiumara","45.327128;14.440335;Trg RH","45.327868;14.438232;Riječki neboder","45.329773;14.433685;Brajda","45.330498;14.431331;Željeznički kolodvor","45.331594;14.428495;KBC 1 porta","45.331990;14.426328;KBC 2 hitna","45.332569;14.430778;KBC 3 Poliklinika"], coordinates2: ["45.332569;14.430778;KBC 3 Poliklinika","45.331378;14.430905;Nikole Tesle","45.330319;14.430867;Željeznički kolodvor","45.329513;14.434123;Brajda","45.327255;14.437783;Žabica","45.326378;14.440090;Riva","45.324925;14.443947;Tržnica","45.326705;14.447252;Fiumara","45.324308;14.454365;Piramida","45.322493;14.460970;Kumičićeva","45.322392;14.465108;Teta Roža","45.325367;14.470072;KBC Sušak ulaz"], linNumb: "KBC", direction: ["KBC Sušak -> KBC Rijeka","KBC Rijeka -> KBC Sušak"], CLLocation: [45.325054, 14.450317], span: 0.055)
            default:
                closeSideMenu()
            
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
