//
//  ScanViewController.swift
//  VisionTextDetection
//
//  Created by Brandon Taleisnik on 7/17/17.
//  Copyright © 2017 Brandon Taleisnik. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {
    
    var allBlockCoordinates: [BlockCoordinates] = []
    var receiptImage: UIImage?

    @IBOutlet weak var receiptimageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        receiptimageView.image = receiptImage
        print("\n\n\nNEW CONTROLLER")
        print(allBlockCoordinates)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
