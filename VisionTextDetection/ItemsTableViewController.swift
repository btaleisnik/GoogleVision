//
//  ItemsTableViewController.swift
//  VisionTextDetection
//
//  Created by Brandon Taleisnik on 7/19/17.
//  Copyright © 2017 Brandon Taleisnik. All rights reserved.
//

import UIKit

class ItemsTableViewController: UITableViewController {
    
    var allItems: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return allItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath)

        cell.textLabel?.text = allItems[indexPath.row].name!
        cell.detailTextLabel?.text = String(allItems[indexPath.row].price!)
        
        return cell
    }
}
