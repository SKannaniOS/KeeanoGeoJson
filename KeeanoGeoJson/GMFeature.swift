//
//  GMFeature.swift
//  KeeanoGeoJson
//
//  Created by SaTHEEsH KaNNaN on 10/10/18.
//  Copyright © 2018 Innoppl. All rights reserved.
//

import UIKit
import GoogleMaps

// MARK: - FeatureType
enum FeatureType : String {
    case Point = "Point"
    case Polygon = "Polygon"
    case Unspecified = "Unspecified"
}

// MARK: - PropertyType
enum PropertyType : String, CaseIterable {
    case Spot = "spot"
    case AnchorageSpot = "anchorage_spot"
    case Port = "port"
    case Beach = "beach"
    case MooringSpot = "mooring_spot"
    case Marina = "marina"
    case Unspecified = "Unspecified"
}

// MARK: - GMFeature
class GMFeature: NSObject {
    
    // MARK: - Properties
    let type : String = "GMFeature"
    var properties : AnyDictionary! {
        didSet{
            if let fType = properties["type"] as? String {
                _ = PropertyType.allCases.map{
                    if $0.rawValue == fType {
                        self.propertyType = $0
                    }
                }
            }
        }
    }
    var geometry : AnyDictionary! {
        didSet{
            if let fType = geometry["type"] as? String {
                self.featureType = fType == FeatureType.Point.rawValue ? .Point : .Polygon
            }
        }
    }
    
    private(set) var featureType : FeatureType = .Unspecified
    private(set) var propertyType : PropertyType = .Unspecified
    
    // MARK: - Initializers
    init(properties : AnyDictionary, geometry : AnyDictionary) {
        self.properties = properties
        super.init()
        self.setGeometry(geometry)
    }
    
    private func setGeometry(_ geometry : AnyDictionary) -> Void {
        self.geometry = geometry
    }
    
    private func setProperties(_ properties : AnyDictionary) -> Void {
        self.properties = properties
    }
    
    // MARK: - Class Function
    
    class func isMarker<T : GMSOverlay>(_ overlay : T) -> Bool {
        return overlay is GMSMarker ? true : false
    }
    
    
    // MARK: - Overlay Creator
    
    func featureOverlays<T : GMSOverlay> () -> [T]? {
        
        guard let gType = geometry["type"] as? String, let coordinates = geometry["coordinates"] else { return nil }
        
        if self.featureType == .Point {
            
            guard let pointValues = coordinates as? [Double], pointValues.count == 2 else { return nil }
            
            let point = CLLocationCoordinate2D(latitude: pointValues.last!, longitude: pointValues.first!)
            
            let marker = GMSMarker(position: point)
            marker.title = gType
            marker.icon = GMSMarker.markerImage(with: .orange)
            
            return [marker] as? [T]
        }
        
        if self.featureType == .Polygon {
            
            guard let baseValues = coordinates as? [[[Double]]]  else { return nil }
            
            var paths = [GMSPath]()
            var polygons = [GMSPolygon]()
            
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
                polygon.title = "gType"
                polygon.isTappable = true
                
                polygons.append(polygon)
            }
            
            return polygons as? [T]
        }
        
        return nil
    }
}
