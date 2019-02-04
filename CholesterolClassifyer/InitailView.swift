//
//  InitailView.swift
//  CholesterolClassifyer
//
//  Created by Nafeh Shoaib and Mario Reckl on 2017-11-18.
//  Copyright © 2017 nafehshoaib. All rights reserved.
//

import Foundation
import UIKit
import VisualRecognitionV3
import Photos

@available(iOS 11.0, *)
class InitailView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // IBM Watson Setup
    let apiKey = "8d7aced8efa9ce11cca985d203dce5989cc20148"
    let version = "2017-08-10" // use today's date for the most recent version
    var resultString = "Elevated Levels Of Cholesterol NOT Been Detected"
    
    // UIImagePickerController to take picture of the user's eye
    let picker = UIImagePickerController()

    var imageURLOLD: URL? // url where the most recent picture is saved

    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
    }
    
    // MARK: UIImagePicker Setup
    @IBAction func scan(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            var imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // Save images to Application Documents Directory
    func saveToDocs(image: UIImage) throws -> URL  {
        let imagePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // name the image by creating a UUID for the device, making sure that images are deleted once new ones are created
        let imageURL = imagePath.appendingPathComponent("\(UUID()).png")
        // Safely write the image's contents to the chosen file
        let jpegData = UIImageJPEGRepresentation(image, 0.35)
        try jpegData?.write(to: imageURL, options: .atomic)
        imageURLOLD = imageURL
        return imageURL
    }
    
    // Save image to Application Documents once finished taking picture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Get image out of media information dictionary, casted from Any
        let pickedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        print(pickedImage)
        // If saving is successful, dismiss the picker and analyse the image using image path
        if let localUrl = saveToDocs(image: pickedImage) {
            picker.dismiss(animated: true, completion: nil)
            analyse(path: localUrl)
        }
    }

    func analyse(path: URL) {
        // Setup UIIndicator while analysis progresses
        let busyIndecator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
        busyIndecator.backgroundColor = UIColor(white: 1, alpha: 0.25)
        busyIndecator.frame = CGRect(x: 0, y:0, width:  self.view.frame.width, height:  self.view.frame.height)
        busyIndecator.startAnimating()
        self.view.addSubview(busyIndecator)
        
        // VisualRecognition IBM Watson Swift API object
        let visualRecognition = VisualRecognition(apiKey: apiKey, version: version)
        
//        let imageSelf = Bundle.main.url(forResource: "download-1", withExtension: "jpg")!//(forResource: path)//Bundle.main.url(forAuxiliaryExecutable: image)
//        print(imageSelf);
        
        // Error handling closure to be passed into classify API call
        let failure = { (error: Error) in print(error) }
        // App ID given by IBM Watson API
        let classifierID:[String] = ["Untitled_980185356"]
        print("starting")
        
        // Main classification handler
        visualRecognition.classify(imageFile: path, classifierIDs: classifierID , language: "en", failure: failure) { classifiedImages in
            // Activity Indicator should stop once classification ends, using Grand Central Dispatch asynchoronously
            DispatchQueue.main.async {
                busyIndecator.stopAnimating()
                busyIndecator.removeFromSuperview()
            }
            print(classifiedImages) // Crude Debug
            
            // if classified images exist and so did not have an unforseen runtime error, proceed
            if (classifiedImages.images.count > 0){
                print(classifiedImages.images)
                print("classification")
                
                // if classifications exist
                if (classifiedImages.images[0].classifiers.count > 0) {
                    // Get first classification of the first image, since the classification is binary
                    var classification = classifiedImages.images[0].classifiers[0].classes[0].classification
                    
                    // Handle results with respective end scene
                    if (classification == "Negative") {
                        // Perform segue once classification is completed asynchronously using Grand Central Dispatch
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "healthyResults", sender: self)
                        }
                    }
                    else if (classification == "Positive"){
                        // Change result string to then send it to the next view controller
                        self.resultString = "Elevated levels of cholesterol detected, please talk to your doctor about high cholesterol"
                        DispatchQueue.main.async{
                            self.performSegue(withIdentifier: "healthyResults", sender: self)}
                    }
                }
            }
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Safely check if the next viewController is the Results View, if so, send it the updated result String
        if let vc = segue.destination as? ResultsView {
            print(resultString)
            vc.result = resultString
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Delegates
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
}
