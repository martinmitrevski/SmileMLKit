//
//  ViewController.swift
//  SmileMLKit
//
//  Created by Martin Mitrevski on 11.05.18.
//  Copyright © 2018 Mitrevski. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    let threshold: CGFloat = 0.75
    
    lazy var faceDetector = Vision.vision().faceDetector(options: faceDetectionOptions())
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detectedInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func selectImageTapped(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) {
            [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) {
            [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    // MARK: - Photo picker
    
    private func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // MARK: - Face Detection
    
    private func faceDetection(fromImage image: UIImage) {
        let visionImage = VisionImage(image: image)
        faceDetector.detect(in: visionImage) { [unowned self] (faces, error) in
            guard error == nil, let detectedFaces = faces else {
                self.showAlert("An error occured", alertMessage: "The face detection failed.")
                return
            }
            
            let faceStates = self.faceStates(forDetectedFaces: detectedFaces)
            self.updateDetectedInfo(forFaceStates: faceStates)
        }
    }
    
    private func faceStates(forDetectedFaces faces: [VisionFace]) -> [FaceState] {
        var states = [FaceState]()
        for face in faces {
            var isSmiling = false
            var leftEyeOpen = false
            var rightEyeOpen = false
            if face.hasSmilingProbability {
                isSmiling = self.isPositive(forProbability: face.smilingProbability)
            }
            
            if face.hasRightEyeOpenProbability {
                rightEyeOpen = self.isPositive(forProbability: face.rightEyeOpenProbability)
            }
            
            if face.hasLeftEyeOpenProbability {
                leftEyeOpen = self.isPositive(forProbability: face.leftEyeOpenProbability)
            }
            
            let faceState = FaceState(smiling: isSmiling,
                                      leftEyeOpen: leftEyeOpen,
                                      rightEyeOpen: rightEyeOpen)
            states.append(faceState)
        }
        
        return states
    }
    
    private func isPositive(forProbability probability: CGFloat) -> Bool {
        return probability > threshold
    }
    
    private func updateDetectedInfo(forFaceStates faceStates: [FaceState]) {
        var text = ""
        for (index, faceState) in faceStates.enumerated() {
            let next = personText(forState: faceState, index: index)
            text = text + next + " "
        }
        detectedInfo.text = text
    }
    
    private func personText(forState state: FaceState, index: Int) -> String {
        let isSmiling = state.smiling ? "is smiling" : "not smiling"
        var eyesOpened = ""
        if state.leftEyeOpen == state.rightEyeOpen {
            eyesOpened =
                state.leftEyeOpen && state.rightEyeOpen ? "both eyes opened" : "both eyes closed"
        } else {
            eyesOpened = "one eye closed and one opened"
        }
        let personText = "Person number \(index + 1) \(isSmiling), with \(eyesOpened)."
        return personText
    }
    
    //MARK: - Alerts
    
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

func faceDetectionOptions() -> VisionFaceDetectorOptions {
    let options = VisionFaceDetectorOptions()
    options.modeType = .accurate
    options.landmarkType = .all
    options.classificationType = .all
    options.minFaceSize = CGFloat(0.1)
    options.isTrackingEnabled = false
    return options
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Handling Image Picker Selection
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = image
        faceDetection(fromImage: image)
    }
}
