//
//  ScanViewController.swift
//  VisionTextDetection
//
//  Created by Brandon Taleisnik on 7/17/17.
//  Copyright © 2017 Brandon Taleisnik. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {

    
    var allBlocks: [Block] = []
    var prices: [Double] = []
    var total: Double?
    var receiptImage: UIImage?
    var totalIndex: Int?
    var foundDouble: Bool?
    var allItems: [Item] = []
    var nextPriceIndexToAdd: Int = 0

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
        print(allBlocks)
        
        print(imageLocation)
        
        if allBlocks.count > 0 {
            //draw original blocks
//            for block in allBlocks {
//                let button = calcButtonCoordinates(block: block)
//                button.addTarget(self, action: #selector(ratingButtonTapped), for: .touchUpInside)
//                button.layer.borderColor = UIColor.green.cgColor
//                button.layer.borderWidth = 2
//                view.addSubview(button)
//            }
            
            let newBlock: [Block] = rescaleBlock(viewSize: viewSize, imageSize: receiptImage?.size, allBlocks: allBlocks, imageLocation: imageLocation)
            
            //draw re-scaled blocks
            var counter: Int = 0
            for block in newBlock {
                let button = calcButtonCoordinates(block: block)
                button.tag = counter
                button.addTarget(self, action: #selector(blockTapped), for: .touchUpInside)
                button.layer.borderColor = UIColor.green.cgColor
                button.layer.borderWidth = 2
                view.addSubview(button)
                
                counter += 1
            }
        }
        
        
        
        

    }
    
    func blockTapped(sender: UIButton) {
        
        var currentBlock: Block = allBlocks[sender.tag]
        foundDouble = false

        
        for i in 0..<currentBlock.paragraphs.count {
            print(currentBlock.paragraphs[i])
            
            //for every line in paragraph, add price element if can be converted to double (i.e. a price)
            for k in 0..<currentBlock.paragraphs[i].count {
                if let priceDouble = currentBlock.paragraphs[i][k].doubleValue {
                    prices.append(priceDouble)
                    foundDouble = true
                    //sender.layer.borderColor = UIColor.cyan.cgColor
                    sender.backgroundColor = UIColor(red: 84/255, green: 136/255, blue: 138/255, alpha: 0.5)
                }
            }
        }
        
        //If prices have been selected, assume highest price is total
        if prices.isEmpty == false {
            
            //find current highest number in prices
            let currentTotal: Double = prices.max()!

            //if no total has been set yet, make currentTotal = total, remove it from pirce, and keep track of index
            if total == nil {
                total = currentTotal
                totalIndex = prices.index(of: prices.max()!)
                prices = prices.filter{$0 != currentTotal}
            }
            
            //if currentTotal is greater than total, insert total back into prices and replace with currentTotal
            if currentTotal > total! {
                //add back old total in correct index
                prices.insert(total!, at: totalIndex!)
                
                //store index of new total and filter out
                totalIndex = prices.index(of: currentTotal)
                total = currentTotal
                prices = prices.filter{$0 != currentTotal}
            }

        }
        
        //if prices existed in the block, we're done and our work was already done above
        if foundDouble == false {
            
            //sender.layer.borderColor = UIColor.cyan.cgColor
            sender.backgroundColor = UIColor(red: 84/255, green: 136/255, blue: 138/255, alpha: 0.5)
            
            //for each item, assign it a price, add to items dictionary, and update priceAdded tracker
            for i in 0..<currentBlock.paragraphs.count {
                for k in 0..<currentBlock.paragraphs[i].count {
                    
                    //make sure prices index is in scope, if not, exit
                    if nextPriceIndexToAdd < prices.count {
                        //if item is not free (discard/skip if it is), assign price to item
                        if prices[nextPriceIndexToAdd] != 0.0 {
                            allItems.append(Item(name: currentBlock.paragraphs[i][k], price: prices[nextPriceIndexToAdd]))
                        }
                        nextPriceIndexToAdd += 1
                    }
                }
            }
        }
    
        //if all data seems complete (i.e. items.count = prices.count, sum(prices) = total, etc.)
        if checkItemCompletion(prices: prices, total: total, allItems: allItems) == true {
            
            performSegue(withIdentifier: "navToItems", sender: nil)
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "navToItems" {
            let itemsVC = segue.destination as! ItemsTableViewController
            
            itemsVC.allItems = self.allItems
            
           // navigationController?.pushViewController(itemsVC, animated: true)
        }
    }
    
    func checkItemCompletion(prices: [Double], total: Double?, allItems: [Item]) -> Bool {
        
        //check item prices add up to total
        var itemSum: Double = 0.0
        for i in allItems {
            itemSum += i.price!
            
            //check all items have a name and price
            if i.name == nil || i.price == nil {
                return false
            }
        }
        
        if itemSum > total! {
            return false
        }
        
        let pricesWithoutZero = prices.filter{$0 != 0.0}
        //check there are same # of items as prices
        if pricesWithoutZero.count != allItems.count {
            return false
        }
        
        return true
    }
    
    func calcButtonCoordinates(block: Block)->UIButton {
        let x = block.v1?.x
        let y = block.v1?.y
        let width = (block.v2?.x)! - (block.v1?.x)!
        let height = (block.v3?.y)! - (block.v2?.y)!
        
        return UIButton(frame: CGRect(x: x!, y: y!, width: width, height: height))
    }
    
    func rescaleBlock(viewSize: CGSize, imageSize: CGSize?, allBlocks: [Block], imageLocation: CGPoint) -> [Block] {
        
        let imageHeight = imageSize?.height
        let imageWidth = imageSize?.width
        let viewHeight = viewSize.height
        let viewWidth = viewSize.width
        
        var newBlock: [Block] = allBlocks
        
        //If view size > image size, xScaler and yScaler will be >1 and will expand block
        //If image size > view size, xScaler and yScaler will be <1 and will reduce block
        let xScaler = viewWidth/imageWidth!
        let yScaler = viewHeight/imageHeight!
        
        //Re-scale x coordinates using xScale multiplier and adjust for non 0,0 position

        var i = 0
        for block in allBlocks {
//                newBlock[i].v1?.x = ((block.v1?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlock[i].v2?.x = ((block.v2?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlock[i].v3?.x = ((block.v3?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
//                newBlock[i].v4?.x = ((block.v4?.x!)! + CGFloat(imageLocation.x)) * (xScaler)
            
            newBlock[i].v1?.x = (CGFloat((block.v1?.x)!) * (xScaler)) //+ imageLocation.x
            newBlock[i].v2?.x = (CGFloat((block.v2?.x)!) * (xScaler)) //+ imageLocation.x
            newBlock[i].v3?.x = (CGFloat((block.v3?.x)!) * (xScaler)) //+ imageLocation.x
            newBlock[i].v4?.x = (CGFloat((block.v4?.x)!) * (xScaler)) //+ imageLocation.x



            i += 1
            
        }

            
        
        //Re-scale y coordinates using yScaler multiplier, and adjust for non 0,0 position

        i = 0
        for block in allBlocks {
//                newBlock[i].v1?.y = ((block.v1?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlock[i].v2?.y = ((block.v2?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlock[i].v3?.y = ((block.v3?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
//                newBlock[i].v4?.y = ((block.v4?.y!)! + CGFloat(imageLocation.y)) * (yScaler)
            
            newBlock[i].v1?.y = (CGFloat((block.v1?.y)!) * (yScaler)) //+ imageLocation.y
            newBlock[i].v2?.y = (CGFloat((block.v2?.y)!) * (yScaler)) //+ imageLocation.y
            newBlock[i].v3?.y = (CGFloat((block.v3?.y)!) * (yScaler)) //+ imageLocation.y
            newBlock[i].v4?.y = (CGFloat((block.v4?.y)!) * (yScaler)) //+ imageLocation.y

                
            i += 1
        }
            
    
        
        return newBlock
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
