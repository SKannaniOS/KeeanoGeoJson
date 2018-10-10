//
//  ViewController.swift
//  KeeanoGeoJson
//
//  Created by SaTHEEsH KaNNaN on 10/10/18.
//  Copyright © 2018 Innoppl. All rights reserved.
//

import UIKit
import GoogleMaps

// MARK: - ViewController
class ViewController: UIViewController {

    // MARK: - Properties
    var mapView: GMSMapView!
    
    
    // MARK: - View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadMapView()
    }

    // MARK: - Initial Map Functions
    func loadMapView() -> Void {
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        self.view = self.mapView
    }

}

