//
//  ViewController.swift
//  CreateML_Example
//
//  Created by Eduardo Lombardi on 23/11/18.
//  Copyright © 2018 Eduardo Lombardi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    //MARK: - Outlets and private vars
    @IBOutlet private weak var uiRecognitionLabel: UILabel?
    @IBOutlet private weak var uiSwitch: UISwitch?
    @IBOutlet private weak var uiCameraView: UIView?
    
    private var requests = [VNRequest]()
    
    //MARK: - Computed properties
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return AVCaptureSession.init() }
        session.addInput(input)
        return session
    }()
    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    //MARK: - Camera capture delegates
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var requestOptions:[VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        
        guard let value = CGImagePropertyOrientation(rawValue: 1) else {
            return
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation:value , options: requestOptions)
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func validateSwitchTap(_ sender: UISwitch) {
        if sender.isOn {
            setupVision()
            self.cameraLayer.isHidden = false
            self.captureSession.startRunning()
        } else {
            self.cameraLayer.isHidden = true
            self.uiRecognitionLabel?.text = ""
            self.captureSession.stopRunning()
        }
    }
    
    
    //MARK: - View Controller delegates
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let app = UIApplication.shared
        switch app.statusBarOrientation {
        case .portrait:
            cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait;
        case .portraitUpsideDown:
            cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown;
        case .landscapeLeft:
            cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft;
        case .landscapeRight:
            cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight;
        default:
            cameraLayer.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight;
        }
        
        self.cameraLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        setupCamera()
        setupVision()
        
    }
    
    //MARK: - CoreML Classifier and configurer
    func handleClassifications(request: VNRequest, error: Error?) {
        guard let observations = request.results
            else { print("no results: \(error!)"); return }
        
        print(observations)
        let classifications = observations[0...4]
            .compactMap({ $0 as? VNClassificationObservation })
            .filter({ $0.confidence > 0.3 })
            .sorted(by: { $0.confidence > $1.confidence })
            .map {
                
                (prediction: VNClassificationObservation) -> String in
                return "\(round(prediction.confidence * 100 * 100)/100)%: \(prediction.identifier)"
                
        }
        DispatchQueue.main.async {
            print(classifications.joined(separator: "###"))
            self.uiRecognitionLabel?.text = classifications.joined(separator: "\n")
        }
    }
    
    func setupVision() {
         guard let visionModel = try? VNCoreMLModel(for: imageClassifier().model)
        else { fatalError("Can't load VisionML model") }
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleClassifications)
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop
        self.requests = [classificationRequest]
    }
    
    //MARK: - Layout Configurations
    func setupLayout() {
        self.uiCameraView?.layer.addSublayer(self.cameraLayer)
        self.cameraLayer.zPosition = -100
        uiRecognitionLabel?.text = ""
        uiSwitch?.setOn(false, animated: false)


    }
    
    func setupCamera() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyCameraQueue"))
        self.captureSession.addOutput(videoOutput)
    }
}

