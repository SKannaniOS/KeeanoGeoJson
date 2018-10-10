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
    var mapView: GMSMapView!
    
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadMapView()
        self.loadGeoJson()
    }

    // MARK: - Initial Map Functions
    func loadMapView() -> Void {
        let camera = GMSCameraPosition.camera(withLatitude: 39.0742, longitude: 21.8243, zoom: 12.0)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.view = self.mapView
    }
    
    func loadBoundingBox(_ boxCoordinates : [Double]) -> Void {
        
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
    
    func loadGeoJson() -> Void {
        
        guard let fileURL = Bundle.main.url(forResource: "data", withExtension: "geojson") else { return }
        
        do {
            
            let fileData = try Data(contentsOf: fileURL)
            
            guard let rootObject = try JSONSerialization.jsonObject(with: fileData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String : Any] else { return }
            
            
            if let bbox = rootObject["bbox"] as? [Double] {
                self.loadBoundingBox(bbox)
            }
            
            guard let allFeatures = rootObject["features"] as? [[String : Any]] else { return }
            
            for feature in allFeatures {
                
                if let properties = feature["properties"] as? [String : Any], let geometry = feature["geometry"] as? [String : Any] {
                    
                    
                    let gf = GMFeature(properties: properties, geometry: geometry)
                    
                    print(gf.featureType)
                    
                    if let gType = geometry["type"] as? String, let coordinates = geometry["coordinates"] {
                        
                        if gType == "Point", let pointValues = coordinates as? [Double], pointValues.count == 2{
                            
                            let point = CLLocationCoordinate2D(latitude: pointValues.last!, longitude: pointValues.first!)
                            
                            let marker = GMSMarker(position: point)
                            marker.title = gType
                            marker.icon = GMSMarker.markerImage(with: .orange)
                            marker.map = self.mapView
                            
                        }
                        
                        if gType == "Polygon", let baseValues = coordinates as? [[[Double]]] {
                            
                            var paths = [GMSPath]()
                            
                            for polyValues in baseValues {
                                
                                let path = GMSMutablePath()
                                
                                for ds in polyValues {
                                    let point = CLLocationCoordinate2D(latitude: ds.last!, longitude: ds.first!)
                                    path.add(point)
                                }
                                
                                paths.append(path)
                            }
                            
                            for path in paths {
                                
                                let polygon = GMSPolygon()
                                
                                polygon.path = path
                                polygon.fillColor = .green
                                polygon.strokeColor = .red
                                polygon.strokeWidth = 1.0
                                polygon.title = gType
                                
                                polygon.map = self.mapView
                            }
                            
                        }
                    }
                    
                }
            }
            
        }
        catch { print(error.localizedDescription) }
    }
}

enum FeatureType : String {
    case Point = "Point"
    case Polygon = "Polygon"
    case Unspecified = "Unspecified"
}



class GMFeature: NSObject {
    
    let type : String = "GMFeature"
    var properties : AnyDictionary!
    var geometry : AnyDictionary! {
        didSet{
            if let fType = geometry["type"] as? String {
                self.featureType = fType == FeatureType.Point.rawValue ? .Point : .Polygon
            }
        }
    }
    
    private(set) var featureType : FeatureType = .Unspecified
    
    init(properties : AnyDictionary, geometry : AnyDictionary) {
        self.properties = properties
        super.init()
        self.setGeometry(geometry)
    }
    
    private func setGeometry(_ geometry : AnyDictionary) -> Void {
        self.geometry = geometry
    }
    
}

