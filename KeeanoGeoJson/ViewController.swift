//
//  ViewController.swift
//  KeeanoGeoJson
//
//  Created by SaTHEEsH KaNNaN on 10/10/18.
//  Copyright © 2018 Innoppl. All rights reserved.
//

import UIKit
import GoogleMaps
import MapKit

// MARK: - ViewController
class ViewController: UIViewController {

    // MARK: - Properties    
    var mapView : GMSMapView!
    var jsonRootObject : AnyDictionary?
    var allFeatures : [AnyDictionary]?
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMapView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadGeoJson()
    }
    
    // MARK: - Initial Map Functions
    
    func loadMapView() -> Void {
        let camera = GMSCameraPosition.camera(withLatitude: 39.0742, longitude: 21.8243, zoom: 12.0)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.view = self.mapView
    }
    
    // MARK: - GeoJson
    
    func loadGeoJson() -> Void {
        
        guard let fileURL = Bundle.main.url(forResource: "data", withExtension: "geojson") else { return }
        
        do {
            
            let fileData = try Data(contentsOf: fileURL)
            
            guard let rootObject = try JSONSerialization.jsonObject(with: fileData, options: JSONSerialization.ReadingOptions.allowFragments) as? AnyDictionary else { return }
            
            self.jsonRootObject = rootObject
            
            self.loadBoundingBox()
            
            guard let allFeatures = rootObject["features"] as? [AnyDictionary] else { return }
                        
            for feature in allFeatures {
                
                if let properties = feature["properties"] as? AnyDictionary, let geometry = feature["geometry"] as? [String : Any] {
                    
                    let feature = GMFeature(properties: properties, geometry: geometry)
                    
                    if let layers = feature.featureOverlays() {
                        _ = layers.map { $0.map = self.mapView }
                    }
                }
            }
            
        }
        catch { print(error.localizedDescription) }
    }
    
    // MARK: - Bounding Box
    
    func loadBoundingBox() -> Void {
        
        guard let rootObject = self.jsonRootObject else { return }
        
        guard let boxCoordinates = rootObject["bbox"] as? [Double] else { return }
        
        let lng1 = boxCoordinates[0]
        let lat1 = boxCoordinates[1]
        let lng2 = boxCoordinates[2]
        let lat2 = boxCoordinates[3]
        
        var span = MKCoordinateSpan()
        span.latitudeDelta = fabs(lat2 - lat1)
        span.longitudeDelta = fabs(lng2 - lng1)
        
        var center = CLLocationCoordinate2D()
        center.latitude = fmax(lat1, lat2) - (span.latitudeDelta / 2.0)
        center.longitude = fmax(lng1, lng2) - (span.longitudeDelta / 2.0)
        
        let place = CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude)
        let placeCam = GMSCameraUpdate.setTarget(place)
        
        self.mapView.animate(with: placeCam)
        
    }

}




