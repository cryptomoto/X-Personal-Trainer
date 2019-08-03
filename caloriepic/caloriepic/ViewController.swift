//
//  ViewController.swift
//  caloriepic
//
//  Created by Chris Anthony on 7/26/19.
//  Copyright © 2019 committed3d. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraDisplay: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCamera()
        noButton.layer.cornerRadius = 15.0
        yesButton.layer.cornerRadius = 15.0

    }
    func setUpCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = .hd4K3840x2160
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        cameraDisplay.layer.addSublayer(previewLayer)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraOutput"))
        
        session.addInput(input)
        session.addOutput(output)
        session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let sampleBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        scanImage(buffer: sampleBuffer)
    }
    
    func scanImage(buffer: CVPixelBuffer) {
        guard let model = try? VNCoreMLModel(for: FoodML_1().model) else { return }
       
        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let results = request.results as? [VNClassificationObservation] else { return }
            guard let mostConfidentResult = results.first else { return }
            let confidenceText = "\n \(Int(mostConfidentResult.confidence * 100.0))% confidence"
            
            
            DispatchQueue.main.async {
                if mostConfidentResult.confidence >= 0.75 {
                    switch mostConfidentResult.identifier {
                    default:
                        self.resultLabel.text = "\(mostConfidentResult.identifier) \(confidenceText)"
                        self.confidenceLabel.text = ""
                    }
                } else {
                        self.resultLabel.text = "Scanning!"
                    }
                }
            }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print(error)
        }
    }
    @IBAction func yesDidPress(_ sender: Any) {
        self.confidenceLabel.text = "Thanks!"
    }
    @IBAction func noDidPress(_ sender: Any) {
        self.confidenceLabel.text = "We're on it!"
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
}
