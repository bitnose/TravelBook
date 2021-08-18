//
//  ViewController.swift
//  TravelBook
//
//  Created by Sötnos on 17.8.2021.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Location Variables
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    // MARK: - Annotation variables
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    // MARK: - FUNCS
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
        // MARK: Location setup
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let hideGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(hideGestureRecognizer)
        
        
        // Add gesture recognizer to detect when new annotation should be created
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        
        // long gesture
        gestureRecognizer.minimumPressDuration = 3
        // Add the recognizer on the view
        mapView.addGestureRecognizer(gestureRecognizer)
        
        // If there is a selected location
        if selectedTitle != "" {
            
            // Coredata objects
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Make a fetch request to the coredata to find the selected location in coredata
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let stringUUID = selectedTitleID!.uuidString
            
            // Make a predicate to filter the results ie to find a matching object (use id)
            fetchRequest.predicate = NSPredicate(format: "id = %@", stringUUID)
            // Make it false because we need to access the values
            fetchRequest.returnsObjectsAsFaults = false
            
            // MARK: - Make the request
            do {
                // Get the results
                let results = try context.fetch(fetchRequest)
                
                // If there are any results
                if results.count > 0 {
                    
                    // LOOP through the results and cast them as NSManagedObjects
                    for result in results as! [NSManagedObject] {
                        
                        // Change the types ie unwrap and set up annotation data
                        if let title = result.value(forKey: "title") as? String {
                            annotationTitle = title
                            
                            if let subtitle = result.value(forKey: "subtitle") as? String {
                                annotationSubtitle = subtitle
                                
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        
                                        annotationLongitude = longitude
                                        
                                        // Create a new annotation point with the fetched data
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        // Add the annotation on the map
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        // Focus the mapview on the chosen location
                                        locationManager.stopUpdatingLocation()
                                        
                                        // Update the span closer, ie zoom in with an animation
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
                // If errors catch
            } catch let error {
                print("Error while fetching data \(error)")
            }
        }
    }

    // MARK: - Create a new annotation by recognizing gestures
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        // Check if the gesture begins
        if gestureRecognizer.state == .began {
            
            // Get the point
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            // Conver the point into coordinates
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            // Make a new point
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            // Add annotation
            self.mapView.addAnnotation(annotation)
        }
    }
        
    // MARK: - To get the current location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // When nothing selected
        if selectedTitle == "" {
        
            // Latitude and longitude to get user's current location
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            // Make a span to zoom in with an animation
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - Creating a Pin View
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        // If an annotation is a current locaiton of the user return nil instead of an annotation view
        if annotation is MKUserLocation {
            return nil
        }
        // Create an annotation view
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        // if pin view is nil create a new view
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            // Add a button to the view
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        // Otherwise
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    // MARK: - Show the detailview
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // If something is selected
        if selectedTitle != "" {
            
            // Location
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            // This method submits the specified location data to the geocoding server asynchronously and returns. When the request completes, the geocoder executes the provided completion handler on the main thread.
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                // If got some placemark data
                if let placemark = placemarks {
                    
                    // If the count of the elements in placemark is more than 0
                    if placemark.count > 0 {
                        
                        // Create new placemark item
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        // Use self because in a closer
                        item.name = self.annotationTitle
                        // Open the placemark in maps ie launch the maps with specified launch options
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }

    // MARK: - IBACTION: Save Button clicked
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        // Core data constants to tap the core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Core data Entity
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        // Create a new core data object with data
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        // Save to core date
        do {
            try context.save()
        } catch {
            print("Error")
        }
        
        // Notify the observers when the new object is created and saved, open the new view
        NotificationCenter.default.post(name: Notification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Hide keyboard
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    
    
}
