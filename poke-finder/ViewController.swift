//
//  ViewController.swift
//  poke-finder
//
//  Created by Aaryn Biro on 2017-05-24.
//  Copyright © 2017 Aaryn Biro. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var filterBtn: UIButton!
    
    //array of pokemon on map
    static var pokemonOnMap = [String]()
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        pickerView.delegate = self
        pickerView.dataSource = self
        mapView.delegate = self
        //will follow user on map
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        //initialize geofire
        geoFireRef = Database.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
        
        
        
    }
    
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    //if they say yes , update the map
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateregion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateregion, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userlocation: MKUserLocation) {
        if let loc = userlocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView?
        let annoIdentifier = "Pokemon"
        
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier){
        
        annotationView = deqAnno
        annotationView?.annotation = annotation
        
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            
            
            
            
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            let btn = UIButton()
            btn.frame = CGRect(x:0, y:0, width: 30, height: 30)
            
            btn.setImage(UIImage(named:"map"), for: .normal)
            
            annotationView.rightCalloutAccessoryView = btn
            
            //does not work
            //pokemonOnMap.append(pokemon[anno.pokemonNumber])
        }
        
        return annotationView
    }
    
    
    //passing location for pokemon, using key from database, from GeoFire docs
    func createSighting(forLocation location: CLLocation, withPokemon pokeID: Int){
        geoFire.setLocation(location, forKey: "\(pokeID)")
        //ViewController.pokemonOnMap.append(pokemon[pokeID])

        
    }

    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            if let key = key, let location = location {
                let anno = PokeAnnotation  (coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
                //does not workself.pokemonOnMap.append(anno.pokemonName)
            }
        })
        
        
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    
    
    //tap pokemon and popup appears, working with Apple Maps
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let anno = view.annotation as? PokeAnnotation {
            
            var place: MKPlacemark!
            if #available(iOS 10.3, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            
           // let place = MKPlacemark(coordinate: anno.coordinate)
            let destination =  MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            let options = [MKLaunchOptionsMapCenterKey: NSValue (mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
             MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }
    
    @IBAction func spotRandomPokemon(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        let rand = arc4random_uniform(151) + 1
        createSighting(forLocation: loc, withPokemon: Int(rand) )
        
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return pokemon.count
       // return ViewController.pokemonOnMap.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pokemon[row].capitalized
        //return ViewController.pokemonOnMap[row].capitalized
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        //statePickerBtn.setTitle(provinces[row], for: UIControlState.normal)
         let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        createSighting(forLocation: loc, withPokemon: Int(row + 1) )
        
        pickerView.isHidden = true
        filterBtn.alpha = 1.0
        
    
        
    }
    

    @IBAction func filterBtnPressed(_ sender: Any) {
        filterBtn.alpha = 0.5
        pickerView.isHidden = false
        
    }
}

