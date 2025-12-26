//
//  GymMapView.swift
//  Gym Flex Italia
//
//  Created by Yarkin Yavuz on 11/16/25.
//

import SwiftUI
import MapKit

/// Map view showing gym locations with markers
struct GymMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let gyms: [Gym]
    let onGymSelected: ((Gym) -> Void)?
    let showUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showUserLocation
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = false
        
        // Set initial region
        mapView.setRegion(region, animated: false)
        
        // Add gym annotations
        addAnnotations(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if it changed significantly
        let currentCenter = mapView.region.center
        let newCenter = region.center
        let distance = CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude)
            .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))
        
        // Only update if region changed significantly (more than 100m)
        if distance > 100 {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations if gyms changed
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        addAnnotations(to: mapView)
    }
    
    private func addAnnotations(to mapView: MKMapView) {
        let annotations = gyms.map { gym -> GymAnnotation in
            let annotation = GymAnnotation(gym: gym)
            annotation.coordinate = gym.coordinate
            annotation.title = gym.name
            annotation.subtitle = "€\(String(format: "%.1f", gym.pricePerHour))/hour"
            return annotation
        }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GymMapView
        
        init(_ parent: GymMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            guard let gymAnnotation = annotation as? GymAnnotation else {
                return nil
            }
            
            let identifier = "GymMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // Customize marker appearance
                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = UIColor(AppColors.brand)
                    markerView.glyphImage = UIImage(systemName: "dumbbell.fill")
                    markerView.glyphTintColor = .white
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            // Add detail disclosure button
            let button = UIButton(type: .detailDisclosure)
            button.tintColor = UIColor(AppColors.brand)
            annotationView?.rightCalloutAccessoryView = button
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let gymAnnotation = view.annotation as? GymAnnotation else { return }
            parent.onGymSelected?(gymAnnotation.gym)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let gymAnnotation = view.annotation as? GymAnnotation else { return }
            parent.onGymSelected?(gymAnnotation.gym)
        }
    }
}

// MARK: - Gym Annotation
class GymAnnotation: NSObject, MKAnnotation {
    let gym: Gym
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(gym: Gym) {
        self.gym = gym
        self.coordinate = gym.coordinate
        self.title = gym.name
        self.subtitle = "€\(String(format: "%.1f", gym.pricePerHour))/hour"
    }
}

