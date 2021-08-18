//
//  ListViewController.swift
//  TravelBook
//
//  Created by Sötnos on 17.8.2021.
//

import UIKit
import CoreData

// MARK: - ListViewController
// Display the list/tableview of saved locations

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Variables
    // Objects (array) to be displayed
    var titleArray = [String]()
    var idArray = [UUID]()
    
    var chosenTitle = ""
    var chosenTitleID : UUID?
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        // Add a button into the navigationbar (add button)
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        // Conform the protocol
        tableView.delegate = self
        tableView.dataSource = self
        
        // Call function to get the data to populate the tableview
        getData()
    }
    
    // MARK: - viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        // Add an observer to listen when new places were created and if so get the data
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    // MARK: - Get data from the core data
    /// Objective-C function
    
    @objc func getData() {
        
        // Core data constants
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Fetch request to fetch all the objects from the entity
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        // Make the request
        do {
            let results = try context.fetch(request)
            
            // If got any results
            if results.count > 0 {
                
                // Remove all the data from the array before updating it
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
                // Loop through the results
                for result in results as! [NSManagedObject] {
                    
                    // Unwrap the data and append it to the array
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    
                    // Unwrap the data and append it to the array
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    // Reload the tableview to update it
                    tableView.reloadData()
                }
            }
        // Catch the errors if any
        }catch let error{
            print("Error while fetching data. \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - BUTTON ACTION
    // When button pressed user is able to add new places on the map
    @objc func addButtonClicked() {
        // Nothing selected
        chosenTitle = ""
        // Map view ->
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    // MARK: - TableView Protocol

    // Number of rows is same as the amount of the objects in array
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }

    // Cells in tableview
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // A simpe cell with a textlabel
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    
    // MARK: - Delete Data From Core Data and the List
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            // Coredata
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            // Make a fetch request to the coredata to find the selected location in coredata
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = idArray[indexPath.row].uuidString
            
            // Make a predicate to filter the results ie to find a matching object (use id)
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            // Make it false because we need to access the values
            fetchRequest.returnsObjectsAsFaults = false
            
            // Remove the item
            do {
                // Fetcht the right item
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    // Unwrap
                    for result in results as! [NSManagedObject] {
                        
                        if let id = result.value(forKey: "id") as? UUID {
                            
                            // Check that the ids are matching and remove the item from the arrays and reload the tableview
                            if id == idArray[indexPath.row] {
                                context.delete(result)
                                titleArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                
                                do {
                                    try context.save()
                                } catch let error {
                                    print("error while saving data \(error)")
                                }
                                // Break the loop because it should not continue after the deleting the item from the lists
                                break
                            }
                        }
                    }
                }
            } catch let error {
                print("Error, \(error.localizedDescription)")
            }
        }
    }

    // MARK: - To send data betweeen the views
    // If the row is selected show the selected place on the map
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        chosenTitle = titleArray[indexPath.row]
        chosenTitleID = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }

    // If something is selected send some information to the view
    // Passing data with segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleID
        } 
    }
}
