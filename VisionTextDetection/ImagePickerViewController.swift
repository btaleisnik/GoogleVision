// Copyright 2016 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import SwiftyJSON
import DSGradientProgressView


struct Item {
    var name: String?
    var price: Double?
    
    init() {
        self.name = ""
        self.price = 0.0
    }
    
    init(name: String?, price: Double?) {
        self.name = name
        self.price = price
    }
}



//If detectedBreak key exists in symbols->property:
//add " " for SPACE
//add \n for EOL_SURE_SPACE
//add new paragraph for LINE_BREAK

struct Symbol {
    var text: String?
    var addSpace: Bool
    var newLine: Bool
    var newParagraph: Bool
    
    init() {
        addSpace = false
        newLine = false
        newParagraph = false
    }
}

struct Word {
    var word: [Symbol]
    
    init() {
        word = []
    }
}

struct Paragraph {
    var paragraph: [Word]
    
    init() {
        paragraph = []
    }
}

struct Coordinate {
    var x: CGFloat?
    var y: CGFloat?
    
    init(x: CGFloat?, y: CGFloat?) {
        self.x = x
        self.y = y
    }
}

struct Block {
    var v1: Coordinate?
    var v2: Coordinate?
    var v3: Coordinate?
    var v4: Coordinate?
    var paragraphs: [[String]]
    
    init() {
        self.v1 = Coordinate(x: nil, y: nil)
        self.v2 = Coordinate(x: nil, y: nil)
        self.v3 = Coordinate(x: nil, y: nil)
        self.v4 = Coordinate(x: nil, y: nil)
        self.paragraphs = [[]]
    }
    
    init(v1: Coordinate?, v2: Coordinate?, v3: Coordinate?, v4: Coordinate?, paragraphs: [[String]]) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        self.v4 = v4
        self.paragraphs = paragraphs
    }
}


// MARK: Easy string indexing functions
extension String {
    subscript(index: Int) -> Character {
        let startIndex = self.index(self.startIndex, offsetBy: index)
        return self[startIndex]
    }
    
    subscript(range: CountableRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: range.count)
        return self[startIndex..<endIndex]
    }
    
    subscript(range: CountableClosedRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: range.count)
        return self[startIndex...endIndex]
    }
    
    subscript(range: NSRange) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.location)
        let endIndex = self.index(startIndex, offsetBy: range.length)
        return self[startIndex..<endIndex]
    }
    
    var isInt: Bool {
        return Int(self) != nil
    }
}


// MARK: ImagePickerViewController Class
class ImagePickerViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let imagePicker = UIImagePickerController()
    let session = URLSession.shared
    
    var currentItem = Item()
    var allItems: [Item] = []
    
    var allBlocks: [Block] = []
    var scanningComplete: Bool? = false

    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var priceTextView: UITextView!
    @IBOutlet weak var itemTextView: UITextView!

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "navToScan" {
            let scanVC = segue.destination as! ScanViewController

            scanVC.allBlocks = self.allBlocks
            scanVC.receiptImage = self.imageView.image
            scanVC.scanningComplete = self.scanningComplete
            
        }
    }

    
    
    var googleAPIKey = "AIzaSyD78xYTGtVFxFaHcHgthQNGTuF_vB6lHsw"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    @IBAction func loadImageButtonTapped(_ sender: UIButton) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        priceTextView.isHidden = true
        itemTextView.isHidden = true
        spinner.hidesWhenStopped = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


/// Image processing

extension ImagePickerViewController {
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            self.spinner.stopAnimating()
            //self.imageView.isHidden = true
            self.priceTextView.isHidden = false
            self.itemTextView.isHidden = false
            self.itemTextView.text = ""
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                self.priceTextView.text = "Error code \(errorObj["code"]): \(errorObj["message"])"
            } else {
                
                //ATTEMPTING TO ISOLATE BLOCK COORDINATES
                var blockResponses: JSON = json["responses"][0]["fullTextAnnotation"]["pages"][0]["blocks"]
                //print(blockResponses)
                
                //print("\n\nNumber of blocks: \(blockResponses.count)\n")
                
                //print(blockResponses[0])

                var coord1: Coordinate?
                var coord2: Coordinate?
                var coord3: Coordinate?
                var coord4: Coordinate?
                var allParagraphs: [[String]] = []
                
                //for each block in receipt
                for i in 0..<blockResponses.count {
                    
                    var currentBlock = Block()

                    var currentVertices = blockResponses[i]["boundingBox"]["vertices"]
                    //print(currentVertices)
                    
                    //Get Block Coordinates
                    var counter = 0
                    for x in currentVertices {

                        let cgfloatX = CGFloat((x.1["x"].rawValue as? NSNumber)!)
                        let cgfloatY = CGFloat((x.1["y"].rawValue as? NSNumber)!)
                        
                        //print(cgfloatX)
                        
                        
                        switch counter
                        {
                        case 0:
                            coord1 = Coordinate(x: cgfloatX, y: cgfloatY)
                            break
                        case 1:
                            coord2 = Coordinate(x: cgfloatX, y: cgfloatY)
                            break
                        case 2:
                            coord3 = Coordinate(x: cgfloatX, y: cgfloatY)
                            break
                        case 3:
                            coord4 = Coordinate(x: cgfloatX, y: cgfloatY)
                            break
                        default:
                            print("Error; Invalid coordinates")
                        }
                        
                        counter += 1
                    }
                    
                    
                    //For each block in receipt
                   // for x in 0..<blockResponses.count {
                        var paragraphJSON = blockResponses[i]["paragraphs"]
                    
                        allParagraphs = []
                    
                        //For each paragraph in current block
                        for j in 0..<paragraphJSON.count {
                            var wordsJSON = paragraphJSON[j]["words"]
                            
                            var currentParagraph = Paragraph()
                            
                            //For each word in paragraph
                            for k in 0..<wordsJSON.count {
                                var symbolsJSON = wordsJSON[k]["symbols"]
                                
                                var currentWord = Word()
                                
                                //For each symbol in word
                                for m in 0..<symbolsJSON.count {
                                    
                                    var currentSymbol = Symbol()
                                    
                                    //check if detectedBreak property is present for symbol
                                    if symbolsJSON[m]["property"]["detectedBreak"] != JSON.null {
                                        let detectedBreak = symbolsJSON[m]["property"]["detectedBreak"]["type"]
                                        
                                        //add flag for appropriate special character
                                        if detectedBreak == "SPACE" {
                                            currentSymbol.addSpace = true
                                        } else if detectedBreak == "EOL_SURE_SPACE" {
                                            currentSymbol.newLine = true
                                        } else if detectedBreak == "LINE_BREAK" {
                                            currentSymbol.newParagraph = true
                                        } else {
                                            print(detectedBreak)
                                        }
                                    }
                                    
                                    
                                    currentSymbol.text = symbolsJSON[m]["text"].description
                                    
                                    //if letter is , replace with .
                                    //this handles instances when decimal in price is interpreted as , so attempt to convert to double will fail; if all , are . we circumvent this
                                    if currentSymbol.text == "," {
                                        currentSymbol.text = "."
                                    }
                                    currentWord.word.append(currentSymbol)
                                }
                                
                                currentParagraph.paragraph.append(currentWord)
                            }
                            
                            //Add currentParagraph to allParagraphs in block
                            allParagraphs.append(self.paragraphToBlock(paragraph: currentParagraph))
                            
                        }
                        
                   // }
                    
                    
                    
                    //Add currentBlock to allBlocks
                    currentBlock = Block(v1: coord1, v2: coord2, v3: coord3, v4: coord4, paragraphs: allParagraphs)
                    self.allBlocks.append(currentBlock)
                }
                
                //TEXT DATA HAS NOW BEEN ASSOCIATED WITH EACH BLOCK SO WE CAN IDENTIFY WHEN USER SELECTS ITEMS
                
                //////////////////////////////////////////////////////////////////////////////////////////////
                //////////////////// THIS SECTION READS DOUBLE VALUES TO IDENTIFY PRICES /////////////////////
                /////////////////// WANT TO CHANGE TO INSTEAD LOOP THROUGH BLOCK USER SELECTS ///////////////
                //////////////////////////////////////////////////////////////////////////////////////////////

                // Parse the response
                let responses: JSON = json["responses"][0]["textAnnotations"][0]["description"]
                
                var rawReceiptData = responses.rawString()
                
                //replace all , with . so $ amounts are in Double format
                rawReceiptData = rawReceiptData?.replacingOccurrences(of: ",", with: ".")
                
                let receiptTextArray = (rawReceiptData?.components(separatedBy: .newlines))!
                
                var prices: [Double] = []
                print(receiptTextArray)
                
                for i in receiptTextArray {
                    if let priceDouble = i.doubleValue {
                        //if free item, we don't care
                        if priceDouble > 0 {
                            //print(priceDouble)
                            prices.append(priceDouble)
                        }
                    }
                }
                
                //find total (assume it's the max() double on receipt, then remove all occurences
                let total = prices.max()
                prices = prices.filter{$0 != total}
                
                //sum up all items and verify itemSum == Total
                var itemSum = prices.reduce(0,+)
                
                //attempt to remove subtotal; look for a number greater than 90% of total price - likely the  pre-tax subtotal
                var subtotal: Double?
                var tax: Double?
                if itemSum != total {
                    for price in prices {
                        if (price > (total!*0.9)) {
                            subtotal = price
                            tax = total! - subtotal!
                            prices = prices.filter{$0 != price}
                            itemSum = prices.reduce(0, +)
                        }
                    }
                }
                
                var pricesText: String = "Prices Found: "
                
                for price in prices {
                    // if it's not the last item add a comma
                    if prices[prices.count - 1] != price {
                        pricesText += "\(price), "
                    } else {
                        pricesText += "\(price)"
                    }
                }
                
                
                self.priceTextView.text = pricesText
                self.itemTextView.text = "Subtotal: \(String(format: "%.2f", (subtotal ?? 0.0))) \nTax: \(String(format: "%.2f", (tax ?? 0.0))) \nTotal: \(String(format: "%.2f", total!))"
                
                //////////////////////////////////////////////////////////////////////////////////////////////
                //////////////////// THIS SECTION READS DOUBLE VALUES TO IDENTIFY PRICES /////////////////////
                /////////////////// WANT TO CHANGE TO INSTEAD LOOP THROUGH BLOCK USER SELECTS ///////////////
                //////////////////////////////////////////////////////////////////////////////////////////////

                //PRINTS ALL LINES IN EACH BLOCK
                for block in self.allBlocks {
                    for i in 0..<block.paragraphs.count {
                        print(block.paragraphs[i])
                    }
                }
            }
            self.scanningComplete = true
            self.performSegue(withIdentifier: "navToScan", sender: nil)
        })
        
    }
    
    func paragraphToBlock(paragraph: Paragraph) -> [String] {
        
        var paragraphRawText: String = ""
        
        //append each concatenated word to a string
        for i in 0..<paragraph.paragraph.count {
            
            //concatenate all letters in each word
            let currentWord = concatLetters(word: paragraph.paragraph[i])
            paragraphRawText.append(currentWord)
            
        }
        
        //divide rawText string at \n characters into separate [String] elements
        let paragraphArray: [String] = concatWords(rawText: paragraphRawText)
        
        print(paragraphArray)
        return paragraphArray
    }
    
    func concatLetters(word: Word)-> String {
        var fullWord: String = ""
        
        for i in word.word {
            fullWord.append(i.text!)
            if i.addSpace == true {
                fullWord.append(" ")
            } else if i.newLine == true {
                fullWord.append("\n")
            }
        }
        print(fullWord)
        return fullWord
    }
    
    func concatWords(rawText: String) -> [String] {
        var paragraphArray: [String] = []
        
        paragraphArray = rawText.components(separatedBy: "\n").map{"\($0)"}
        
        return paragraphArray
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage // You could optionally display the image here by setting imageView.image = pickedImage
            spinner.startAnimating()
            itemTextView.isHidden = true
            priceTextView.isHidden = true
            
            // Base64 encode the image and create the request
            let binaryImageData = base64EncodeImage(pickedImage)
            createRequest(with: binaryImageData)
        }
        
        dismiss(animated: true, completion: nil)
        self.performSegue(withIdentifier: "navToScan", sender: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
}


/// Networking

extension ImagePickerViewController {
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata?.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String) {
        // Create our request URL
        
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "DOCUMENT_TEXT_DETECTION",
                    ]
                ]
            ]
        ]
        let jsonObject = JSON(jsonDictionary: jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
}


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
