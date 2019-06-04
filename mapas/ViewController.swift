//
//  ViewController.swift
//  mapas
//
//  Created by Lobarinhas on 10/04/2019.
//  Copyright © 2019 Lobarinhas. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController , MKMapViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var lblSearch: UILabel!
    var searchActive:Bool = false
    var geocoder = CLGeocoder()
    var locationManager = CLLocationManager()
    var latestLocation:CLLocation!
    var coordInitMap:CLLocation!
    var pointsForPoliLine = [CLLocationCoordinate2D]()
    var directionsOnOff:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblSearch.text = ""
        
        let initialLocation = CLLocation(latitude: 41.693218, longitude: -8.848564)
        coordInitMap = initialLocation
        latestLocation = initialLocation
        centerMapOnLocation(location: initialLocation)
        
        let tapOnMap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(self.longTapped(_:)))
        mapView.addGestureRecognizer(tapOnMap)
        mapView.addGestureRecognizer(longTap)
        // Do any additional setup after loading the view.    }
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer){
        let touch = sender.location(in: mapView)
        let locationCoord = mapView.convert(touch, toCoordinateFrom: mapView)
            
        let newCoord:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: locationCoord.latitude, longitude: locationCoord.longitude)
        pointsForPoliLine.append(newCoord)
            
        if pointsForPoliLine.count == 4{
            addBoundry()
        }
    }
    
    func addBoundry() {
        let polignon = MKPolygon(coordinates: &pointsForPoliLine, count: pointsForPoliLine.count)
        mapView.addOverlay(polignon)
    }
    
    @objc func longTapped(_ sender: UILongPressGestureRecognizer){
        if sender.state.rawValue == 1 {
            let touchLocation = sender.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            let location = CLLocation(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location){
                (placemarks, error) in
                self.processResponseRev(withPlacemarks: placemarks, error: error)
            }
            if directionsOnOff == true{
                self.calculateRoute(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            }
        }
    }
    
    func centerMapOnLocation(location:CLLocation) {
        let regionRadius:CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,latitudinalMeters: regionRadius,longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        let point = MKPointAnnotation()
        point.coordinate = CLLocationCoordinate2D(latitude: 41.693218, longitude: -8.848564)
        point.title = "Scala"
        point.subtitle = "Viana da Castelo"
        mapView.addAnnotation(point)
        
        mapView.addOverlay(MKCircle(center: point.coordinate, radius: 200))
    }
    
    @IBAction func clickSegmentedControl(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
            break;
        case 1:
            mapView.mapType = .satellite
            break
        default:
            mapView.mapType = .hybrid
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle{
            let circleRender = MKCircleRenderer(overlay: overlay)
            circleRender.fillColor = UIColor.green
            return circleRender
        }
        
        if let overlay = overlay as? MKPolygon{
            let polygonRender = MKPolygonRenderer(overlay: overlay)
            polygonRender.strokeColor = UIColor.yellow
            return polygonRender
        }
        
        //DIRECTIONS
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = UIColor.blue
        render.lineWidth = 5.0
        return render
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            print(view.annotation!.title!!)
            print(view.annotation!.subtitle!!)
            print(view.annotation!.coordinate)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
        }
        
        let button = UIButton(type: .detailDisclosure) as UIButton
        pinView?.rightCalloutAccessoryView = button
        
        return pinView
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let aux:String = searchBar.text!
        if aux.count > 0 {
            geocoder.geocodeAddressString(aux){
                (placemarks, error) in
                self.processResponse(withPlacemarks: placemarks, error: error)
            }
        }
    }
    
    func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?){
        if let error = error {
            print("Unable to fetch the request "+error.localizedDescription)
            lblSearch.text = "Não consegui encontrar o endereço"
        }
        else{
            var location:CLLocation?
            
            if let placemarks = placemarks, placemarks.count>0 {
                location = placemarks.first?.location
            }
            if let location = location{
                let coordinate = location.coordinate
                let latAux = NSNumber(value: (coordinate.latitude) as Double)
                let lat:String = ""+String(latAux.stringValue)
                let lngAux = NSNumber(value: (coordinate.longitude) as Double)
                let lng:String = ""+String(lngAux.stringValue)
                lblSearch.text = "Lat: "+lat+" Lng: "+lng
                coordInitMap = location
                centerMapOnLocation(location: location)
            }
            else{
                lblSearch.text = "Não consegui encontrar o endereço"
            }
        }
    }
    
    func processResponseRev(withPlacemarks placemarks: [CLPlacemark]?, error: Error?){
        if let error=error {
            print("Unable to fetch the request "+error.localizedDescription)
            lblSearch.text = "Não consegui encontrar o endereço"
        }
        else{
            if let placemarks = placemarks, let placemark = placemarks.first{
                lblSearch.text = placemark.country! + " , " + placemark.locality! + " , "+String(placemark.postalCode!)+" , "+placemark.name!
            }
            else {
                lblSearch.text = "Não consegui encontrar o endereço"
            }
        }
    }
    
    @IBAction func ondeEstou(_ sender: UIButton) {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    
    @IBAction func distancia(_ sender: Any) {
        let distancia:CLLocationDistance = latestLocation.distance(from: coordInitMap)
        
        lblSearch.text = String(format: "%.2f", distancia)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocation = locations[locations.count-1]
        var result = " Lat: " + String(format: "%.4f", latestLocation.coordinate.latitude)
        result = result + " Lng: " + String(format: "%.4f", latestLocation.coordinate.longitude)
        lblSearch.text = result
        result = result + " Horizontal Accuracy: " + String(format: "%.4f", latestLocation.horizontalAccuracy)
        result = result + " Altitude: " + String(format: "%.4f", latestLocation.altitude)
        result = result + " Vertical Accuracy: " + String(format: "%.4f", latestLocation.verticalAccuracy)
        centerMapOnLocation(location: latestLocation)
        print(result)
    }
    
    @IBAction func directionsOn(_ sender: UISwitch) {
        if directionsOnOff == false {
            directionsOnOff = true
            print("On")
        }
        else{
            directionsOnOff = false
            print("Off")
        }
    }
    
    func calculateRoute(latitude: CLLocationDegrees, longitude: CLLocationDegrees){
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude), addressDictionary: nil))
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: { (response,error) in
            if error != nil{
                print("Erro getting directions")
            }
            else{
                self.showRoute(response!)
            }
        })
    }
    
    func showRoute(_ response: MKDirections.Response){
        for route in response.routes{
            mapView.addOverlay(route.polyline)
            for step in route.steps{
                print(step.instructions)
            }
        }
    }
}

