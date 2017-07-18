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
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //let viewSize = receiptimageView.frame.size
        let viewSize = self.view.frame.size
        let imageLocation = receiptimageView.frame.origin
        print(viewSize)
        
        if let currentReciept = receiptImage {
            receiptimageView.image = currentReciept
        }
        print("\n\n\nNEW CONTROLLER")
        print(allBlockCoordinates)
        
        print(imageLocation)
        
        if allBlockCoordinates.count > 0 {
            //draw original blocks
            for block in allBlockCoordinates {
                let button = calcButtonCoordinates(block: block)
                button.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)
                button.layer.borderColor = UIColor.green.cgColor
                button.layer.borderWidth = 2
                view.addSubview(button)
            }
            
            let newBlockCoordinates: [BlockCoordinates] = rescaleBlockCoordinates(viewSize: viewSize, imageSize: receiptImage?.size, allBlockCoordinates: allBlockCoordinates, imageLocation: imageLocation)
            
            //draw re-scaled blocks
            for block in newBlockCoordinates {
                let button = calcButtonCoordinates(block: block)
                button.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)
                button.layer.borderColor = UIColor.red.cgColor
                button.layer.borderWidth = 2
                view.addSubview(button)
            }
        }
        
        
        
        

    }
    
    func ratingButtonTapped() {
        print("Button pressed")
    }
    
    func calcButtonCoordinates(block: BlockCoordinates)->UIButton {
        let x = block.v1?.x
        let y = block.v1?.y
        let width = (block.v2?.x)! - (block.v1?.x)!
        let height = (block.v3?.y)! - (block.v2?.y)!
        
        return UIButton(frame: CGRect(x: x!, y: y!, width: width, height: height))
    }
    
    func rescaleBlockCoordinates(viewSize: CGSize, imageSize: CGSize?, allBlockCoordinates: [BlockCoordinates], imageLocation: CGPoint) -> [BlockCoordinates] {
        
        let imageHeight = imageSize?.height
        let imageWidth = imageSize?.width
        let viewHeight = viewSize.height
        let viewWidth = viewSize.width
        
        var newBlockCoordinates: [BlockCoordinates] = allBlockCoordinates
        
        //If view size > image size, xScaler and yScaler will be >1 and will expand block
        //If image size > view size, xScaler and yScaler will be <1 and will reduce block
        let xScaler = viewWidth/imageWidth!
        let yScaler = viewHeight/imageHeight!
        
        //Re-scale x coordinates using xScale multiplier and adjust for non 0,0 position
        if (viewWidth/imageWidth!) >= (imageWidth!/viewWidth) {

            var i = 0
            for block in allBlockCoordinates {
//                newBlockCoordinates[i].v1?.x = ((block.v1?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlockCoordinates[i].v2?.x = ((block.v2?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlockCoordinates[i].v3?.x = ((block.v3?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlockCoordinates[i].v4?.x = ((block.v4?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
                
                newBlockCoordinates[i].v1?.x = (CGFloat((block.v1?.x)!) * (xScaler)) //+ imageLocation.x
                newBlockCoordinates[i].v2?.x = (CGFloat((block.v2?.x)!) * (xScaler)) //+ imageLocation.x
                newBlockCoordinates[i].v3?.x = (CGFloat((block.v3?.x)!) * (xScaler)) //+ imageLocation.x
                newBlockCoordinates[i].v4?.x = (CGFloat((block.v4?.x)!) * (xScaler)) //+ imageLocation.x


 
                i += 1
                
            }

            
        }
        
        //Re-scale y coordinates using yScaler multiplier, and adjust for non 0,0 position
        if (viewHeight/imageHeight!) >= (imageHeight!/viewHeight) {
            
            var i = 0
            for block in allBlockCoordinates {
//                newBlockCoordinates[i].v1?.y = ((block.v1?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlockCoordinates[i].v2?.y = ((block.v2?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlockCoordinates[i].v3?.y = ((block.v3?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlockCoordinates[i].v4?.y = ((block.v4?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
                
                newBlockCoordinates[i].v1?.y = (CGFloat((block.v1?.y)!) * (yScaler)) //+ imageLocation.y
                newBlockCoordinates[i].v2?.y = (CGFloat((block.v2?.y)!) * (yScaler)) //+ imageLocation.y
                newBlockCoordinates[i].v3?.y = (CGFloat((block.v3?.y)!) * (yScaler)) //+ imageLocation.y
                newBlockCoordinates[i].v4?.y = (CGFloat((block.v4?.y)!) * (yScaler)) //+ imageLocation.y

                
                i += 1
            }
            
        }
        
        return newBlockCoordinates
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
