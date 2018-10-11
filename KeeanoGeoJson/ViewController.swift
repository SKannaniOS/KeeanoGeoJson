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
    var allFeatures = [GMFeature]()
    
    var defaultMapZoom : Float = 12.0
    var initialLocation = CLLocationCoordinate2D(latitude: 39.0742, longitude: 21.8243)
    var lastZoom : Float = 0.0
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadMapView()
        self.createReloadButton()
        self.loadGeoJson()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadBoundingBox()
    }
    
    // MARK: - Initial Map Functions
    
    func loadMapView() -> Void {
        let camera = GMSCameraPosition.camera(withTarget: self.initialLocation, zoom: self.defaultMapZoom)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.mapView.delegate = self
        self.view = self.mapView
    }
    
    
    // MARK: - Map Reload
    
    func createReloadButton() -> Void {
        
        let screenSize = UIScreen.main.bounds.size
        let buttonSize = CGSize(width: 44.0, height: 44.0)
        let gap : CGFloat = 10.0
        
        let button = UIButton(type: .custom)
        
        button.frame = CGRect(x: screenSize.width - buttonSize.width - gap, y: screenSize.height - buttonSize.height - gap, width: buttonSize.width, height: buttonSize.height)
        button.setImage(UIImage(named: "Reload_Icon"), for: .normal)
        button.addTarget(self, action: #selector(reloadAction(_:)), for: .touchUpInside)
        
        self.mapView.addSubview(button)
    }
    
    @objc func reloadAction(_ button : UIButton) -> Void {
        self.loadBoundingBox()
    }
    
    // MARK: - GeoJson
    
    func loadGeoJson() -> Void {
        
        guard let fileURL = Bundle.main.url(forResource: "data", withExtension: "geojson") else { return }
        
        do {
            
            let fileData = try Data(contentsOf: fileURL)
            
            guard let rootObject = try JSONSerialization.jsonObject(with: fileData, options: JSONSerialization.ReadingOptions.allowFragments) as? AnyDictionary else { return }
            
            self.jsonRootObject = rootObject
            
           
            guard let allRawFeatures = rootObject["features"] as? [AnyDictionary] else { return }
            
            self.allFeatures.removeAll()
            
            for rawFeature in allRawFeatures {
                
                if let properties = rawFeature["properties"] as? AnyDictionary, let geometry = rawFeature["geometry"] as? [String : Any] {
                    
                    let feature = GMFeature(properties: properties, geometry: geometry)
                    
                    self.allFeatures.append(feature)
                }
            }
        }
        catch { print(error.localizedDescription) }
    }
    
    // MARK: - Features
    
    func loadFeatures(forZoom zoomLevel : Float) -> Void {
        
        guard self.allFeatures.count > 0 else { return }
        
        self.mapView.clear()
        
        guard zoomLevel > 9.0 else { return }
        
        var allowedTypes : [PropertyType] = PropertyType.allCases
        
        if zoomLevel >= 9.0, zoomLevel <= 12.0 {
            allowedTypes = [.Port, .Marina]
        }
        
        if zoomLevel > 12.0, zoomLevel <= 17.0 {
            allowedTypes = [.Port, .Marina, .Beach]
        }
        
        let filteredFeatures = self.allFeatures.filter { allowedTypes.contains($0.propertyType) }
        
        _ = filteredFeatures.map {
            if let layers = $0.featureOverlays() {
                _ = layers.map { $0.map = self.mapView }
            }
        }
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
        let placeCam = GMSCameraUpdate.setTarget(place, zoom: self.defaultMapZoom)
        
        self.mapView.animate(with: placeCam)
        
    }

}

// MARK: - GMSMapViewDelegate

extension ViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        if self.lastZoom != mapView.camera.zoom {
            self.loadFeatures(forZoom: mapView.camera.zoom)
        }
        self.lastZoom = mapView.camera.zoom
    }
}

